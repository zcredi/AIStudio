import Foundation
import OSLog

final class URLSessionAPIClient: APIClient {
    // MARK: - Properties

    private let server: APIServer
    private let transport: any HTTPTransport
    private let interceptors: [any RequestInterceptor]
    private let logger = Logger(category: "APIClient")

    // MARK: - Init

    init(
        server: APIServer,
        transport: any HTTPTransport = URLSession.shared,
        interceptors: [any RequestInterceptor] = []
    ) {
        self.server = server
        self.transport = transport
        self.interceptors = interceptors
    }

    // MARK: - APIClient

    @concurrent
    func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response {
        let request = try await makeRequest(for: endpoint)
        let (data, response) = try await perform(request)
        try validate(response, data: data)
        return try decode(Response.self, from: data)
    }

    // MARK: - Private

    private func makeRequest<Response>(for endpoint: Endpoint<Response>) async throws -> URLRequest {
        var request = URLRequest(url: try makeURL(for: endpoint), timeoutInterval: endpoint.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            let encoded = try encode(body)
            request.httpBody = encoded.data
            request.setValue(encoded.contentType, forHTTPHeaderField: "Content-Type")
        }

        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }
        return request
    }

    private func encode(_ body: RequestBody) throws -> (data: Data, contentType: String) {
        do {
            return try body.encoded()
        } catch {
            logger.error("Failed to encode request body: \(error)")
            throw APIError.invalidRequest
        }
    }

    private func makeURL<Response>(for endpoint: Endpoint<Response>) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = server.host
        components.path = server.basePath + endpoint.path
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
            // URLComponents leaves `+` as is, and servers read it as a space.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = components.url else { throw APIError.invalidRequest }
        return url
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            logger.error("Request failed: \(error.code.rawValue, privacy: .public)")
            throw APIError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        return (data, httpResponse)
    }

    private func validate(_ response: HTTPURLResponse, data: Data) throws {
        guard !(200..<300).contains(response.statusCode) else { return }
        logger.error("Request failed with status \(response.statusCode, privacy: .public)")
        throw APIError(statusCode: response.statusCode, message: ServerErrorBody.message(in: data))
    }

    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        do {
            return try JSONDecoder.api().decode(type, from: data)
        } catch {
            logger.error("Failed to decode \(String(describing: type), privacy: .public): \(error)")
            throw APIError.decoding
        }
    }
}
