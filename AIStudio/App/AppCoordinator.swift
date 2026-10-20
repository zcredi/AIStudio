import UIKit

/// Owns the window and decides which flow is on screen.
@MainActor
final class AppCoordinator {
    // MARK: - Properties

    private let window: UIWindow

    // MARK: - Init

    init(window: UIWindow) {
        self.window = window
        window.backgroundColor = Palette.background
    }

    // MARK: - API

    func start() {
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
    }
}
