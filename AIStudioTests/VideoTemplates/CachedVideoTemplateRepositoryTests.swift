import XCTest
@testable import AIStudio

final class CachedVideoTemplateRepositoryTests: XCTestCase {
    private actor CountingRepository: VideoTemplateRepository {
        private(set) var callCount = 0
        private var results: [Result<[VideoTemplate], APIError>]

        init(results: [Result<[VideoTemplate], APIError>]) {
            self.results = results
        }

        func templates() async throws -> [VideoTemplate] {
            callCount += 1
            return try results.removeFirst().get()
        }
    }

    func test_templates_afterSuccess_servesCatalogFromMemory() async throws {
        // Дано
        let base = CountingRepository(results: [.success([.fixture(id: 1)])])
        let repository = CachedVideoTemplateRepository(repository: base)

        // Когда
        _ = try await repository.templates()
        let templates = try await repository.templates()

        // Тогда
        XCTAssertEqual(templates.map(\.id), [1])
        let callCount = await base.callCount
        XCTAssertEqual(callCount, 1)
    }

    func test_templates_afterFailure_loadsAgain() async throws {
        let base = CountingRepository(results: [.failure(.offline), .success([.fixture(id: 2)])])
        let repository = CachedVideoTemplateRepository(repository: base)

        // Первая загрузка падает намеренно.
        _ = try? await repository.templates()
        let templates = try await repository.templates()

        XCTAssertEqual(templates.map(\.id), [2])
    }
}
