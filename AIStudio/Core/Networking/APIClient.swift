/// Sends endpoints to one server and decodes their responses.
protocol APIClient: Sendable {
    /// Throws `APIError`, or `CancellationError` when the calling task is cancelled.
    func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response
}
