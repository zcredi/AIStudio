import ApphudSDK
import Combine
import OSLog
import StoreKit

/// Единственное место, которое общается с Apphud. Снаружи видны только доменные типы.
@MainActor
final class ApphudSubscriptionService {
    // MARK: - Types

    private enum PurchasableProduct {
        /// Из пейвола Apphud, чтобы покупки попадали в его аналитику.
        case paywall(ApphudProduct)
        /// Из Product hub; предлагаются, когда в Apphud нет пейвола с заданным идентификатором.
        case store(Product)
    }

    private struct LoadedProduct {
        let purchasable: PurchasableProduct
        let product: PaywallProduct
    }

    // MARK: - Properties

    /// ID пользователя Apphud; API использует его как `user_id`. Может меняться во время работы, поэтому читаем его по
    /// месту.
    var userID: String {
        Apphud.userID()
    }

    private let apiKey: String
    private let paywallIdentifier: String
    private let fallbackProductIDs: [String]
    private let premiumSubject = CurrentValueSubject<Bool, Never>(false)
    /// Становится `true`, когда Apphud зарегистрировал пользователя или восстановил его из кэша.
    private let isStatusKnownSubject = CurrentValueSubject<Bool, Never>(false)
    private let logger = Logger(category: "ApphudSubscriptionService")
    /// Продукты последнего загруженного пейвола, нужны для старта покупки.
    private var purchasablesByID: [PaywallProduct.ID: PurchasableProduct] = [:]
    /// Пейволы из Product hub. Apphud отдаёт их только через делегат;
    /// плейсменты содержат пейволы, только если их настроили в Mission control.
    private var deliveredPaywalls: [ApphudPaywall] = []
    private var delegateAdapter: ApphudDelegateAdapter?

    // MARK: - Init

    /// `fallbackProductIDs` предлагаются в этом порядке, если в Apphud нет пейвола с именем `paywallIdentifier`.
    init(apiKey: String, paywallIdentifier: String, fallbackProductIDs: [String]) {
        self.apiKey = apiKey
        self.paywallIdentifier = paywallIdentifier
        self.fallbackProductIDs = fallbackProductIDs
    }

    // MARK: - API

    func start() {
        guard !apiKey.isEmpty else {
            logger.fault("Apphud is not started: API key is missing")
            isStatusKnownSubject.send(true)
            return
        }
        let adapter = ApphudDelegateAdapter(
            onUpdate: { [weak self] in self?.refreshPremiumStatus() },
            onPaywallsLoad: { [weak self] paywalls in self?.deliveredPaywalls = paywalls }
        )
        Apphud.setDelegate(adapter)
        delegateAdapter = adapter
        // Намеренно nonisolated: Apphud не гарантирует, на каком потоке придёт колбэк.
        Apphud.start(apiKey: apiKey) { @Sendable _ in
            Task { @MainActor [weak self] in
                self?.refreshPremiumStatus()
                self?.isStatusKnownSubject.send(true)
            }
        }
        refreshPremiumStatus()
    }

    // MARK: - Private

    private func refreshPremiumStatus() {
        premiumSubject.send(Apphud.hasPremiumAccess())
    }

    private func findPaywall() async -> ApphudPaywall? {
        // Ждёт, пока Apphud загрузит предложения; делегат получает пейволы раньше, чем это вернётся.
        let placementPaywalls = await Apphud.placements().compactMap(\.paywall)
        let paywall = (placementPaywalls + deliveredPaywalls).first { $0.identifier == paywallIdentifier }
        if paywall == nil {
            logger.info("Paywall \(self.paywallIdentifier, privacy: .public) is not set up in Apphud, offering Product hub products")
        }
        return paywall
    }

    /// Продукты, которые App Store не смог найти, пропускаются, чтобы предложить остальные.
    private func storeProducts(of paywall: ApphudPaywall) async -> [LoadedProduct] {
        var products: [LoadedProduct] = []
        for apphudProduct in paywall.products {
            do {
                guard
                    let storeProduct = try await apphudProduct.product(),
                    let product = PaywallProduct(storeProduct)
                else {
                    logger.error("Product \(apphudProduct.productId, privacy: .public) is not an App Store subscription")
                    continue
                }
                products.append(LoadedProduct(purchasable: .paywall(apphudProduct), product: product))
            } catch {
                logger.error("Failed to load product \(apphudProduct.productId, privacy: .public): \(error)")
            }
        }
        return products
    }

    /// App Store возвращает продукты в произвольном порядке; пейвол сохраняет заданный.
    private func fallbackProducts() async -> [LoadedProduct] {
        let storeProducts: [Product]
        do {
            storeProducts = try await Product.products(for: fallbackProductIDs)
        } catch {
            logger.error("Failed to load Product hub products: \(error)")
            return []
        }
        return fallbackProductIDs.compactMap { id in
            guard
                let storeProduct = storeProducts.first(where: { $0.id == id }),
                let product = PaywallProduct(storeProduct)
            else {
                logger.error("Product \(id, privacy: .public) is not available in the App Store")
                return nil
            }
            return LoadedProduct(purchasable: .store(storeProduct), product: product)
        }
    }

    private func outcome(isSuccess: Bool, isPending: Bool, isCancelled: Bool, error: (any Error)?) throws -> PurchaseOutcome {
        if isCancelled {
            return .cancelled
        }
        if isPending {
            return .pending
        }
        guard isSuccess else {
            logger.error("Purchase failed: \(String(describing: error))")
            throw SubscriptionError.purchaseFailed
        }
        return .purchased
    }
}

// MARK: - PremiumStatusProviding

extension ApphudSubscriptionService: PremiumStatusProviding {
    var isPremium: Bool {
        premiumSubject.value
    }

    var isPremiumPublisher: AnyPublisher<Bool, Never> {
        premiumSubject.removeDuplicates().eraseToAnyPublisher()
    }

    func waitUntilStatusIsKnown() async {
        for await isKnown in isStatusKnownSubject.values where isKnown {
            return
        }
    }
}

// MARK: - SubscriptionPurchasing

extension ApphudSubscriptionService: SubscriptionPurchasing {
    func loadPaywall() async throws -> Paywall {
        let paywall = await findPaywall()
        let products = if let paywall {
            await storeProducts(of: paywall)
        } else {
            await fallbackProducts()
        }
        guard !products.isEmpty else { throw SubscriptionError.paywallUnavailable }

        purchasablesByID = Dictionary(
            products.map { ($0.product.id, $0.purchasable) },
            uniquingKeysWith: { first, _ in first }
        )
        // Пейвол загружается в момент появления экрана, поэтому это и есть показ.
        if let paywall {
            Apphud.paywallShown(paywall)
        }
        return Paywall(products: products.map(\.product))
    }

    func purchase(_ product: PaywallProduct) async throws -> PurchaseOutcome {
        guard let purchasable = purchasablesByID[product.id] else { throw SubscriptionError.productUnavailable }

        switch purchasable {
        case .paywall(let apphudProduct):
            let result = await Apphud.purchase(apphudProduct)
            refreshPremiumStatus()
            return try outcome(isSuccess: result.success, isPending: result.isPending, isCancelled: result.userCanceled, error: result.error)
        case .store(let storeProduct):
            let result = await Apphud.purchase(storeProduct)
            refreshPremiumStatus()
            let isCancelled = if case .userCancelled? = result.error as? StoreKitError { true } else { false }
            // `success` означает лишь, что StoreKit вернул транзакцию; отказ сервера Apphud приходит
            // через `error`, и такая покупка не должна ничего открывать.
            let isSuccess = result.transaction != nil && result.error == nil
            return try outcome(isSuccess: isSuccess, isPending: result.isPending, isCancelled: isCancelled, error: result.error)
        }
    }

    func restorePurchases() async throws {
        let failure: String? = await withCheckedContinuation { continuation in
            // Намеренно nonisolated: Apphud не гарантирует, на каком потоке придёт колбэк.
            Apphud.restorePurchases { @Sendable result in
                continuation.resume(returning: result.error.map { String(describing: $0) })
            }
        }
        refreshPremiumStatus()

        guard !isPremium else { return }
        if let failure {
            logger.error("Restore failed: \(failure)")
            throw SubscriptionError.restoreFailed
        }
        throw SubscriptionError.nothingToRestore
    }
}

// MARK: - ApphudDelegateAdapter

/// Получает колбэки Apphud, у которых нет гарантий по актору, и передаёт их на главный актор.
private final class ApphudDelegateAdapter: ApphudDelegate, Sendable {
    private let onUpdate: @MainActor @Sendable () -> Void
    private let onPaywallsLoad: @MainActor @Sendable ([ApphudPaywall]) -> Void

    init(
        onUpdate: @escaping @MainActor @Sendable () -> Void,
        onPaywallsLoad: @escaping @MainActor @Sendable ([ApphudPaywall]) -> Void
    ) {
        self.onUpdate = onUpdate
        self.onPaywallsLoad = onPaywallsLoad
    }

    /// Apphud вызывает это из блока главной очереди в `preparePaywalls`. Пейволы не `Sendable`,
    /// поэтому передаются синхронно на главном акторе, а не через задачу;
    /// `nonisolated(unsafe)` лишь сообщает компилятору то, что место вызова уже гарантирует.
    func paywallsDidFullyLoad(paywalls: [ApphudPaywall]) {
        nonisolated(unsafe) let paywalls = paywalls
        MainActor.assumeIsolated {
            onPaywallsLoad(paywalls)
        }
    }

    func apphudSubscriptionsUpdated(_ subscriptions: [ApphudSubscription]) {
        Task { @MainActor [onUpdate] in onUpdate() }
    }

    func apphudNonRenewingPurchasesUpdated(_ purchases: [ApphudNonRenewingPurchase]) {
        Task { @MainActor [onUpdate] in onUpdate() }
    }
}

// MARK: - Mapping

private extension PaywallProduct {
    init?(_ product: Product) {
        guard
            let storePeriod = product.subscription?.subscriptionPeriod,
            let period = SubscriptionPeriod(storePeriod)
        else {
            return nil
        }
        self.init(
            id: product.id,
            period: period,
            price: product.price,
            priceFormat: product.priceFormatStyle
        )
    }
}

private extension SubscriptionPeriod {
    init?(_ period: Product.SubscriptionPeriod) {
        let unit: Unit
        switch period.unit {
        case .day:
            unit = .day
        case .week:
            unit = .week
        case .month:
            unit = .month
        case .year:
            unit = .year
        @unknown default:
            return nil
        }
        self.init(unit: unit, value: period.value)
    }
}
