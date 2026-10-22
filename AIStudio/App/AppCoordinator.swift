import UIKit

/// Владеет окном и решает, какой сценарий на экране.
@MainActor
final class AppCoordinator {
    // MARK: - Properties

    private let window: UIWindow
    private let container: AppContainer
    /// Распознаватели жестов держат делегата слабой ссылкой.
    private var swipeBackDelegate: SwipeBackGestureDelegate?

    // MARK: - Init

    init(window: UIWindow, container: AppContainer) {
        self.window = window
        self.container = container
        window.backgroundColor = Palette.background
    }

    // MARK: - API

    func start() {
        window.rootViewController = makeInitialViewController()
        window.makeKeyAndVisible()
    }

    // MARK: - Private

    private func makeInitialViewController() -> UIViewController {
        #if DEBUG
        if let screen = DebugStartScreen.current {
            return makeDebugScreen(screen)
        }
        #endif
        return makeSplash()
    }

    private func makeSplash() -> UIViewController {
        let splash = container.makeSplashViewController()
        splash.onFinish = { [weak self] in self?.showFirstScreen() }
        return splash
    }

    private func makeOnboarding() -> UIViewController {
        let onboarding = container.makeOnboardingViewController()
        onboarding.onFinish = { [weak self] in self?.showPaywallAfterOnboarding() }
        return onboarding
    }

    private func makePaywall(onDone: @escaping @MainActor () -> Void) -> UIViewController {
        let paywall = container.makePaywallViewController()
        paywall.onClose = onDone
        paywall.onAccessGranted = onDone
        return paywall
    }

    private func showFirstScreen() {
        if container.onboardingProgress.isOnboardingCompleted {
            showMain()
        } else {
            setRoot(makeOnboarding())
        }
    }

    private func showPaywallAfterOnboarding() {
        guard !container.premiumStatus.isPremium else {
            showMain()
            return
        }
        setRoot(makePaywall { [weak self] in self?.showMain() })
    }

    private func makeMain() -> UINavigationController {
        let main = container.makeMainViewController()
        let navigationController = UINavigationController(rootViewController: main)
        navigationController.isNavigationBarHidden = true
        let swipeBackDelegate = SwipeBackGestureDelegate(navigationController: navigationController)
        navigationController.interactivePopGestureRecognizer?.delegate = swipeBackDelegate
        self.swipeBackDelegate = swipeBackDelegate

        let presentPaywall: @MainActor () -> Void = { [weak self, weak navigationController] in
            guard let navigationController else { return }
            self?.presentPaywall(from: navigationController)
        }
        main.onOpenPaywall = presentPaywall
        container.premiumGate.onPaywallRequired = presentPaywall
        main.onOpenChat = { [weak self, weak navigationController] in
            guard let navigationController else { return }
            self?.showChat(nil, in: navigationController)
        }
        main.onOpenHistory = { [weak self, weak navigationController] in
            guard let navigationController else { return }
            self?.showHistory(in: navigationController)
        }
        main.onOpenSettings = { [weak self, weak navigationController] in
            guard let navigationController else { return }
            self?.showSettings(in: navigationController)
        }
        main.onOpenVideoGenerator = { [weak self, weak main, weak navigationController] in
            guard let navigationController else { return }
            self?.showVideoTemplates(in: navigationController) { main?.videoCardView }
        }
        return navigationController
    }

    /// `source` — вид, из которого каталог раскрывается zoom-переходом; без него экран пушится как обычно.
    private func showVideoTemplates(
        in navigationController: UINavigationController,
        animated: Bool = true,
        zoomingFrom source: (@MainActor () -> UIView?)? = nil
    ) {
        let catalog = container.makeVideoTemplatesViewController()
        catalog.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        catalog.onOpenTemplate = { [weak self, weak catalog, weak navigationController] templates, index in
            guard let catalog, let navigationController, templates.indices.contains(index) else { return }
            self?.showVideoTemplate(templates[index], among: templates, from: catalog, in: navigationController)
        }
        if let source {
            zoom(catalog, from: source)
        }
        push(catalog, onto: navigationController, animated: animated)
    }

    private func showVideoTemplate(
        _ template: VideoTemplate,
        among templates: [VideoTemplate],
        from catalog: VideoTemplatesViewController,
        in navigationController: UINavigationController
    ) {
        let templateScreen = container.makeVideoTemplateViewController(template: template, templates: templates)
        templateScreen.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        templateScreen.onOpenGeneration = { [weak self, weak navigationController] id in
            guard let navigationController else { return }
            self?.showGenerating(id, in: navigationController)
        }
        // Возврат сворачивает экран в карточку шаблона, который сейчас на экране:
        // в карусели могли пролистать к другому.
        zoom(templateScreen) { [weak catalog, weak templateScreen] in
            guard let templateScreen else { return nil }
            return catalog?.cardView(for: templateScreen.currentTemplateID)
        }
        push(templateScreen, onto: navigationController, animated: true)
    }

    /// Экран генерации уступает место результату, если видео готово, пока он открыт.
    /// `cardSource` даёт карточку истории, из которой раскрывается экран.
    private func showGenerating(
        _ id: VideoGeneration.ID,
        in navigationController: UINavigationController,
        replacing current: UIViewController? = nil,
        cardSource: (@MainActor (VideoGeneration.ID) -> UIView?)? = nil
    ) {
        let generating = container.makeGeneratingViewController(generationID: id)
        generating.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        generating.onOpenResult = { [weak self, weak navigationController, weak generating] generation in
            guard let navigationController, let generating else { return }
            self?.showResult(generation, in: navigationController, replacing: generating, cardSource: cardSource)
        }
        if let cardSource {
            zoom(generating) { cardSource(id) }
        }
        push(generating, in: navigationController, replacing: current)
    }

    /// «Replace» на результате запускает новую генерацию, и её экран встаёт на место результата.
    private func showResult(
        _ generation: VideoGeneration,
        in navigationController: UINavigationController,
        replacing current: UIViewController? = nil,
        cardSource: (@MainActor (VideoGeneration.ID) -> UIView?)? = nil
    ) {
        let result = container.makeVideoResultViewController(generation: generation)
        result.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        result.onOpenGeneration = { [weak self, weak navigationController, weak result] id in
            guard let navigationController, let result else { return }
            self?.showGenerating(id, in: navigationController, replacing: result, cardSource: cardSource)
        }
        if let cardSource {
            zoom(result) { cardSource(generation.id) }
        }
        push(result, in: navigationController, replacing: current)
    }

    /// Пушит `viewController`, занимая место `current`, если тот в стеке.
    /// Замена — следующий шаг того же сценария, поэтому экран проявляется на месте, а не въезжает.
    private func push(_ viewController: UIViewController, in navigationController: UINavigationController, replacing current: UIViewController?) {
        guard let current, let index = navigationController.viewControllers.firstIndex(of: current) else {
            push(viewController, onto: navigationController, animated: true)
            return
        }
        let fade = CATransition()
        fade.type = .fade
        fade.duration = Motion.standard
        navigationController.view.layer.add(fade, forKey: kCATransition)
        navigationController.setViewControllers(Array(navigationController.viewControllers[..<index]) + [viewController], animated: false)
    }

    /// Второй тап, пока экран въезжает, запушил бы тот же экран дважды.
    private func push(_ viewController: UIViewController, onto navigationController: UINavigationController, animated: Bool) {
        guard navigationController.transitionCoordinator == nil else { return }
        navigationController.pushViewController(viewController, animated: animated)
    }

    /// Раскрывает `viewController` zoom-переходом из вида, который вернёт `source`, и сворачивает обратно при возврате.
    /// На системах до iOS 18 остаётся обычный push.
    private func zoom(_ viewController: UIViewController, from source: @escaping @MainActor () -> UIView?) {
        guard #available(iOS 18.0, *) else { return }
        viewController.preferredTransition = .zoom { _ in source() }
    }

    private func showSettings(in navigationController: UINavigationController, animated: Bool = true) {
        let settings = container.makeSettingsViewController()
        settings.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        settings.onOpenPaywall = { [weak self, weak navigationController] in
            guard let navigationController else { return }
            self?.presentPaywall(from: navigationController)
        }
        push(settings, onto: navigationController, animated: animated)
    }

    private func showHistory(in navigationController: UINavigationController, animated: Bool = true) {
        let history = container.makeHistoryViewController()
        history.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        history.onOpenChat = { [weak self, weak navigationController] chat in
            guard let navigationController else { return }
            self?.showChat(chat, in: navigationController)
        }
        let cardSource: @MainActor (VideoGeneration.ID) -> UIView? = { [weak history] id in
            history?.videoCardView(for: id)
        }
        history.onOpenVideo = { [weak self, weak navigationController] generation in
            guard let navigationController else { return }
            self?.showResult(generation, in: navigationController, cardSource: cardSource)
        }
        history.onOpenGeneration = { [weak self, weak navigationController] id in
            guard let navigationController else { return }
            self?.showGenerating(id, in: navigationController, cardSource: cardSource)
        }
        push(history, onto: navigationController, animated: animated)
    }

    private func showChat(_ chat: Chat?, in navigationController: UINavigationController, animated: Bool = true) {
        let chatScreen = container.makeChatViewController(chat: chat)
        chatScreen.onBack = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        chatScreen.onDeleted = { [weak navigationController] in
            navigationController?.popToRootViewController(animated: true)
        }
        push(chatScreen, onto: navigationController, animated: animated)
    }

    private func showMain() {
        setRoot(makeMain())
    }

    private func presentPaywall(from presenter: UIViewController) {
        // Несколько премиум-действий подряд показывают пейвол один раз.
        guard presenter.presentedViewController == nil else { return }
        let paywall = makePaywall { [weak presenter] in presenter?.dismiss(animated: true) }
        paywall.modalPresentationStyle = .fullScreen
        presenter.present(paywall, animated: true)
    }

    private func setRoot(_ viewController: UIViewController) {
        UIView.transition(
            with: window,
            duration: Motion.standard,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            self.window.rootViewController = viewController
        }
    }

    #if DEBUG
    private func makeDebugScreen(_ screen: DebugStartScreen) -> UIViewController {
        switch screen {
        case .onboarding:
            makeOnboarding()
        case .paywall:
            makePaywall { [weak self] in self?.showMain() }
        case .main:
            makeMain()
        case .chat:
            showingNewChat(in: makeMain())
        case .history:
            showingHistory(in: makeMain())
        case .settings:
            showingSettings(in: makeMain())
        case .videoTemplates:
            showingVideoTemplates(in: makeMain())
        }
    }

    private func showingNewChat(in navigationController: UINavigationController) -> UIViewController {
        showChat(nil, in: navigationController, animated: false)
        return navigationController
    }

    private func showingHistory(in navigationController: UINavigationController) -> UIViewController {
        showHistory(in: navigationController, animated: false)
        return navigationController
    }

    private func showingSettings(in navigationController: UINavigationController) -> UIViewController {
        showSettings(in: navigationController, animated: false)
        return navigationController
    }

    private func showingVideoTemplates(in navigationController: UINavigationController) -> UIViewController {
        showVideoTemplates(in: navigationController, animated: false)
        return navigationController
    }
    #endif
}
