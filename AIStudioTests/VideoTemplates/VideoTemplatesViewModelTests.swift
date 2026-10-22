import XCTest
@testable import AIStudio

@MainActor
final class VideoTemplatesViewModelTests: XCTestCase {
    private struct Repository: VideoTemplateRepository {
        let result: Result<[VideoTemplate], APIError>

        func templates() async throws -> [VideoTemplate] {
            try result.get()
        }
    }

    private let catalog: [VideoTemplate] = [
        .fixture(id: 1, category: "Trending"),
        .fixture(id: 2, category: "Film"),
        .fixture(id: 3, category: "Trending"),
        .fixture(id: 1, category: "Trending"),
    ]

    func test_load_selectsFirstCategoryAndShowsItsTemplates() async {
        let viewModel = VideoTemplatesViewModel(repository: Repository(result: .success(catalog)))

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.categories, ["Trending", "Film"])
        XCTAssertEqual(viewModel.state.selectedCategory, "Trending")
        XCTAssertEqual(viewModel.state.visibleTemplates.map(\.id), [1, 3])
    }

    func test_load_whenFails_showsError() async {
        let viewModel = VideoTemplatesViewModel(repository: Repository(result: .failure(.offline)))

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.templates, .failed(UserFacingError(message: APIError.offline.localizedDescription)))
    }

    func test_reload_keepsSelectedCategory() async {
        // Дано
        let viewModel = VideoTemplatesViewModel(repository: Repository(result: .success(catalog)))
        await viewModel.load().value
        viewModel.selectCategory("Film")

        // Когда
        await viewModel.load().value

        // Тогда
        XCTAssertEqual(viewModel.state.selectedCategory, "Film")
    }

    func test_selectTemplate_opensItAmongCategoryTemplates() async {
        // Дано
        let viewModel = VideoTemplatesViewModel(repository: Repository(result: .success(catalog)))
        let events = PublisherRecorder(viewModel.events)
        await viewModel.load().value

        // Когда
        viewModel.selectTemplate(id: 3)

        // Тогда
        XCTAssertEqual(events.values, [.openTemplate(templates: [catalog[0], catalog[2]], index: 1)])
    }
}
