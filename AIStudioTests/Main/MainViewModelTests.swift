import XCTest
@testable import AIStudio

@MainActor
final class MainViewModelTests: XCTestCase {
    func test_init_withoutSubscription_showsProButton() {
        let viewModel = MainViewModel(premiumStatus: FakePremiumStatus())

        XCTAssertTrue(viewModel.state.isProButtonVisible)
    }

    func test_premiumActivated_hidesProButtonWithoutRelaunch() {
        // Дано
        let premiumStatus = FakePremiumStatus()
        let viewModel = MainViewModel(premiumStatus: premiumStatus)

        // Когда
        premiumStatus.isPremium = true

        // Тогда
        XCTAssertFalse(viewModel.state.isProButtonVisible)
    }
}
