import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: - Properties

    var window: UIWindow?

    private var coordinator: AppCoordinator?

    // MARK: - UIWindowSceneDelegate

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene, !isRunningUnitTests else { return }

        let container = AppContainer()
        container.start()

        let window = UIWindow(windowScene: windowScene)
        let coordinator = AppCoordinator(window: window, container: container)
        coordinator.start()

        self.window = window
        self.coordinator = coordinator
    }

    // MARK: - Private

    /// Юнит-тесты запускаются внутри приложения; старт SDK там регистрировал бы фейковых пользователей Apphud.
    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
