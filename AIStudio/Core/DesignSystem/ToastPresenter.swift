import UIKit

/// Показывает по одному тосту сверху: он выезжает, держится две секунды,
/// и его можно смахнуть вверх раньше.
@MainActor
final class ToastPresenter {
    // MARK: - Types

    private enum Layout {
        /// Под строкой заголовка шапки, как в макетах.
        static let topSpacing: CGFloat = 55
        static let visibleDuration: Duration = .seconds(2)
        static let hiddenOffset: CGFloat = -24
    }

    // MARK: - Properties

    private weak var containerView: UIView?
    private var currentToast: ToastView?
    private var hideTask: Task<Void, Never>?

    // MARK: - Init

    init(containerView: UIView) {
        self.containerView = containerView
    }

    // MARK: - API

    func show(_ style: ToastView.Style, message: String) {
        guard let containerView else { return }
        hide(animated: false)

        let toast = ToastView(style: style, message: message)
        toast.onSwipeUp = { [weak self] in self?.hide(animated: true) }
        containerView.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            toast.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: Layout.topSpacing),
        ])
        currentToast = toast
        UIAccessibility.post(notification: .announcement, argument: message)
        animateIn(toast)
        scheduleHide()
    }

    // MARK: - Private

    private func animateIn(_ toast: ToastView) {
        toast.alpha = 0
        guard !UIAccessibility.isReduceMotionEnabled else {
            UIView.animate(withDuration: Motion.standard) { toast.alpha = 1 }
            return
        }
        toast.transform = CGAffineTransform(translationX: 0, y: Layout.hiddenOffset)
        UIView.animate(withDuration: Motion.standard, delay: 0, usingSpringWithDamping: Motion.springDampingRatio, initialSpringVelocity: 0) {
            toast.alpha = 1
            toast.transform = .identity
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            // Отмена значит, что таймер перехватил более новый тост.
            try? await Task.sleep(for: Layout.visibleDuration)
            guard !Task.isCancelled else { return }
            self?.hide(animated: true)
        }
    }

    private func hide(animated: Bool) {
        hideTask?.cancel()
        guard let toast = currentToast else { return }
        currentToast = nil
        guard animated else {
            toast.removeFromSuperview()
            return
        }
        UIView.animate(withDuration: Motion.standard) {
            toast.alpha = 0
            if !UIAccessibility.isReduceMotionEnabled {
                toast.transform = CGAffineTransform(translationX: 0, y: Layout.hiddenOffset)
            }
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }
}
