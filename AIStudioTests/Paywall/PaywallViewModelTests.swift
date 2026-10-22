import XCTest
@testable import AIStudio

@MainActor
final class PaywallViewModelTests: XCTestCase {
    private struct SUT {
        let viewModel: PaywallViewModel
        let service: FakeSubscriptionService
        let events: PublisherRecorder<PaywallViewModel.Event>
    }

    // MARK: - Loading

    func test_load_withProducts_showsWeeklyAndFullPrices() async {
        let sut = makeSUT()

        await sut.viewModel.load().value

        let plans = sut.viewModel.state.plans.value
        XCTAssertEqual(plans?.map(\.title), ["Year $1.35", "Month $1.84"])
        XCTAssertEqual(plans?.map(\.fullPrice), ["$69.99", "$7.99"])
    }

    func test_load_withProducts_marksOnlyCheapestPerWeekWithSavings() async {
        let sut = makeSUT()

        await sut.viewModel.load().value

        XCTAssertEqual(sut.viewModel.state.plans.value?.map(\.savings), ["SAVE 80%", nil])
    }

    func test_load_withProducts_selectsBestValuePlan() async {
        let sut = makeSUT(products: [.monthly, .yearly])

        await sut.viewModel.load().value

        XCTAssertEqual(sut.viewModel.state.selectedPlanID, PaywallProduct.yearly.id)
    }

    func test_load_whenServiceFails_showsErrorMessage() async throws {
        let sut = makeSUT()
        sut.service.paywallResult = .failure(SubscriptionError.paywallUnavailable)

        await sut.viewModel.load().value

        let expected = try XCTUnwrap(UserFacingError(SubscriptionError.paywallUnavailable))
        XCTAssertEqual(sut.viewModel.state.plans, .failed(expected))
    }

    func test_load_whenCancelled_keepsLoading() async {
        let sut = makeSUT()
        sut.service.paywallResult = .failure(CancellationError())

        await sut.viewModel.load().value

        XCTAssertEqual(sut.viewModel.state.plans, .loading)
    }

    // MARK: - Purchase

    func test_purchase_buysSelectedPlan() async {
        // Дано
        let sut = makeSUT()
        await sut.viewModel.load().value
        sut.viewModel.selectPlan(id: PaywallProduct.monthly.id)

        // Когда
        await sut.viewModel.purchase()?.value

        // Тогда
        XCTAssertEqual(sut.service.purchasedProducts, [.monthly])
    }

    func test_purchase_whenPurchased_grantsAccess() async {
        let sut = makeSUT()
        await sut.viewModel.load().value

        await sut.viewModel.purchase()?.value

        XCTAssertEqual(sut.events.values, [.accessGranted])
        XCTAssertFalse(sut.viewModel.state.isProcessing)
    }

    func test_purchase_whenCancelled_staysSilent() async {
        // Дано
        let sut = makeSUT()
        await sut.viewModel.load().value
        sut.service.purchaseResult = .success(.cancelled)

        // Когда
        await sut.viewModel.purchase()?.value

        // Тогда
        XCTAssertEqual(sut.events.values, [])
        XCTAssertFalse(sut.viewModel.state.isProcessing)
    }

    func test_purchase_whenPending_reportsPending() async {
        let sut = makeSUT()
        await sut.viewModel.load().value
        sut.service.purchaseResult = .success(.pending)

        await sut.viewModel.purchase()?.value

        XCTAssertEqual(sut.events.values, [.purchasePending])
    }

    func test_purchase_whenFails_showsError() async throws {
        // Дано
        let sut = makeSUT()
        await sut.viewModel.load().value
        sut.service.purchaseResult = .failure(SubscriptionError.purchaseFailed)

        // Когда
        await sut.viewModel.purchase()?.value

        // Тогда
        let expected = try XCTUnwrap(UserFacingError(SubscriptionError.purchaseFailed))
        XCTAssertEqual(sut.events.values, [.showError(expected)])
        XCTAssertFalse(sut.viewModel.state.isProcessing)
    }

    func test_purchase_beforePlansLoaded_doesNothing() {
        let sut = makeSUT()

        let task = sut.viewModel.purchase()

        XCTAssertNil(task)
        XCTAssertEqual(sut.service.purchasedProducts, [])
    }

    // MARK: - Restore

    func test_restore_whenSucceeds_grantsAccess() async {
        let sut = makeSUT()

        await sut.viewModel.restore()?.value

        XCTAssertEqual(sut.events.values, [.accessGranted])
    }

    func test_restore_withNothingToRestore_showsError() async throws {
        let sut = makeSUT()
        sut.service.restoreError = SubscriptionError.nothingToRestore

        await sut.viewModel.restore()?.value

        let expected = try XCTUnwrap(UserFacingError(SubscriptionError.nothingToRestore))
        XCTAssertEqual(sut.events.values, [.showError(expected)])
    }

    // MARK: - Private

    private func makeSUT(products: [PaywallProduct] = [.yearly, .monthly]) -> SUT {
        let service = FakeSubscriptionService()
        service.paywallResult = .success(Paywall(products: products))
        let viewModel = PaywallViewModel(subscriptionService: service)
        return SUT(viewModel: viewModel, service: service, events: PublisherRecorder(viewModel.events))
    }
}
