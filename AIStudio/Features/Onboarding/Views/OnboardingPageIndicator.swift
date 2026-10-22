import UIKit

/// Точки страниц из макета: текущая страница — более широкая градиентная капсула.
final class OnboardingPageIndicator: UIView {
    // MARK: - Types

    private enum Layout {
        static let dotSize: CGFloat = 8
        static let currentDotWidth: CGFloat = 22
        static let spacing: CGFloat = 6
        static let inactiveColor = Palette.accent.withAlphaComponent(0.25)
    }

    private final class Dot: UIView {
        let gradientView = GradientView()
        lazy var width = widthAnchor.constraint(equalToConstant: Layout.dotSize)
    }

    // MARK: - Properties

    private let dots: [Dot]

    // MARK: - Init

    init(pageCount: Int) {
        dots = (0..<pageCount).map { _ in Dot() }
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    func setCurrentPage(_ index: Int, animated: Bool) {
        accessibilityValue = String(localized: "Page \(index + 1) of \(dots.count)")
        let changes = {
            for (dotIndex, dot) in self.dots.enumerated() {
                let isCurrent = dotIndex == index
                dot.width.constant = isCurrent ? Layout.currentDotWidth : Layout.dotSize
                dot.gradientView.alpha = isCurrent ? 1 : 0
            }
        }
        // Без окна анимировать нечего, а принудительная раскладка до того, как индикатор
        // размещён, разложила бы его в нулевой размер.
        guard animated, window != nil else {
            changes()
            return
        }
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            changes()
            self.layoutIfNeeded()
        }
    }

    // MARK: - Private

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Page indicator")

        let stack = UIStackView(arrangedSubviews: dots)
        stack.spacing = Layout.spacing
        addSubview(stack)
        stack.pinEdges(to: self)

        for dot in dots {
            dot.backgroundColor = Layout.inactiveColor
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.clipsToBounds = true
            dot.addSubview(dot.gradientView)
            dot.gradientView.pinEdges(to: dot)
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.heightAnchor.constraint(equalToConstant: Layout.dotSize),
                dot.width,
            ])
        }
    }
}
