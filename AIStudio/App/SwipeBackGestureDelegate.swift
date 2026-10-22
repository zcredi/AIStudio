import UIKit

/// Сохраняет свайп назад от края, когда экраны рисуют свою шапку вместо navigation bar.
final class SwipeBackGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    /// Если начать жест на корневом экране, navigation controller зависнет.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
