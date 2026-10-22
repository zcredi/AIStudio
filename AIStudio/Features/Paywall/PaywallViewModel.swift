import Combine
import Foundation

@MainActor
final class PaywallViewModel {
    // MARK: - Types

    struct State: Equatable {
        var plans: Loadable<[PaywallPlan]> = .loading
        var selectedPlanID: PaywallPlan.ID?
        /// Идёт покупка или восстановление; на это время экран блокирует ввод.
        var isProcessing = false
    }

    enum Event: Equatable {
        case accessGranted
        case purchasePending
        case showError(UserFacingError)
    }

    // MARK: - Properties

    @Published private(set) var state = State()
    let events: AnyPublisher<Event, Never>

    private let subscriptionService: any SubscriptionPurchasing
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var products: [PaywallProduct] = []
    private var loadTask: Task<Void, Never>?

    // MARK: - Init

    init(subscriptionService: any SubscriptionPurchasing) {
        self.subscriptionService = subscriptionService
        events = eventSubject.eraseToAnyPublisher()
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - API

    /// Возвращаемая задача позволяет вызывающему коду, например тестам, дождаться результата.
    @discardableResult
    func load() -> Task<Void, Never> {
        loadTask?.cancel()
        update { $0.plans = .loading }

        let task = Task { [weak self, subscriptionService] in
            do {
                let paywall = try await subscriptionService.loadPaywall()
                guard !Task.isCancelled else { return }
                self?.show(paywall)
            } catch {
                self?.showLoadingFailure(error)
            }
        }
        loadTask = task
        return task
    }

    func selectPlan(id: PaywallPlan.ID) {
        guard !state.isProcessing else { return }
        update { $0.selectedPlanID = id }
    }

    @discardableResult
    func purchase() -> Task<Void, Never>? {
        guard !state.isProcessing, let product = products.first(where: { $0.id == state.selectedPlanID }) else {
            return nil
        }
        update { $0.isProcessing = true }

        return Task { [weak self, subscriptionService] in
            do {
                let outcome = try await subscriptionService.purchase(product)
                self?.finishPurchase(with: outcome)
            } catch {
                self?.failOperation(with: error)
            }
        }
    }

    @discardableResult
    func restore() -> Task<Void, Never>? {
        guard !state.isProcessing else { return nil }
        update { $0.isProcessing = true }

        return Task { [weak self, subscriptionService] in
            do {
                try await subscriptionService.restorePurchases()
                self?.grantAccess()
            } catch {
                self?.failOperation(with: error)
            }
        }
    }

    // MARK: - Private

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func show(_ paywall: Paywall) {
        products = paywall.products
        let plans = PaywallPlan.plans(for: paywall.products)
        update {
            $0.plans = .loaded(plans)
            $0.selectedPlanID = plans.first(where: { $0.savings != nil })?.id ?? plans.first?.id
        }
    }

    private func showLoadingFailure(_ error: any Error) {
        guard let userFacingError = UserFacingError(error) else { return }
        update { $0.plans = .failed(userFacingError) }
    }

    private func finishPurchase(with outcome: PurchaseOutcome) {
        switch outcome {
        case .purchased:
            grantAccess()
        case .pending:
            update { $0.isProcessing = false }
            eventSubject.send(.purchasePending)
        case .cancelled:
            update { $0.isProcessing = false }
        }
    }

    private func grantAccess() {
        update { $0.isProcessing = false }
        eventSubject.send(.accessGranted)
    }

    private func failOperation(with error: any Error) {
        update { $0.isProcessing = false }
        guard let userFacingError = UserFacingError(error) else { return }
        eventSubject.send(.showError(userFacingError))
    }
}
