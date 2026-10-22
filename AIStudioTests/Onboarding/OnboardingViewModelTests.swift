import XCTest
@testable import AIStudio

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func test_continueTapped_onFirstPage_showsNextPage() {
        let (viewModel, _, events) = makeSUT()

        viewModel.continueTapped()

        XCTAssertEqual(viewModel.state.currentPageIndex, 1)
        XCTAssertEqual(events.values, [])
    }

    func test_continueTapped_onLastPage_finishesAndRemembersCompletion() {
        // Дано
        let (viewModel, store, events) = makeSUT()
        viewModel.showPage(at: viewModel.state.pages.count - 1)

        // Когда
        viewModel.continueTapped()

        // Тогда
        XCTAssertEqual(events.values, [.finished])
        XCTAssertTrue(store.isOnboardingCompleted)
    }

    func test_showPage_afterSwipe_updatesCurrentPage() {
        let (viewModel, _, _) = makeSUT()

        viewModel.showPage(at: 1)

        XCTAssertEqual(viewModel.state.currentPageIndex, 1)
    }

    func test_showPage_withIndexOutOfRange_keepsCurrentPage() {
        let (viewModel, _, _) = makeSUT()

        viewModel.showPage(at: 5)

        XCTAssertEqual(viewModel.state.currentPageIndex, 0)
    }

    // MARK: - Private

    private func makeSUT() -> (OnboardingViewModel, FakeOnboardingProgressStore, PublisherRecorder<OnboardingViewModel.Event>) {
        let store = FakeOnboardingProgressStore()
        let viewModel = OnboardingViewModel(progressStore: store)
        return (viewModel, store, PublisherRecorder(viewModel.events))
    }
}
