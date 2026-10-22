import XCTest
@testable import AIStudio

@MainActor
final class SplashViewModelTests: XCTestCase {
    func test_start_whenStatusIsKnown_finishes() async {
        // Дано
        let premiumStatus = FakePremiumStatus()
        let viewModel = SplashViewModel(
            premiumStatus: premiumStatus,
            timing: SplashViewModel.Timing(minimumDuration: .zero, timeout: .seconds(3600))
        )
        let events = PublisherRecorder(viewModel.events)

        // Когда
        await viewModel.start().value

        // Тогда
        XCTAssertEqual(events.values, [.finished])
    }

    func test_start_whenStatusNeverArrives_finishesAfterTimeout() async {
        // Дано
        let premiumStatus = FakePremiumStatus()
        premiumStatus.isStatusKnown = false
        let viewModel = SplashViewModel(
            premiumStatus: premiumStatus,
            timing: SplashViewModel.Timing(minimumDuration: .zero, timeout: .milliseconds(10))
        )
        let events = PublisherRecorder(viewModel.events)

        // Когда
        await viewModel.start().value

        // Тогда
        XCTAssertEqual(events.values, [.finished])
    }
}
