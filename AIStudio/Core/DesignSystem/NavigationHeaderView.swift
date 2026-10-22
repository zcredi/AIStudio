import UIKit

/// Кнопка назад и заголовок по центру для экранов со своей шапкой.
final class NavigationHeaderView: UIView {
    // MARK: - Types

    private enum Layout {
        static let height: CGFloat = 52
        static let hitAreaSize: CGFloat = 44
        /// Иконка 24 pt стоит в 16 pt от края, а область нажатия остаётся 44 pt.
        static let backButtonLeading = Spacing.l - (hitAreaSize - 24) / 2
    }

    // MARK: - Properties

    var onBack: (() -> Void)?

    /// Экраны с листанием показывают здесь текущий элемент.
    var title: String? {
        get { titleLabel.text }
        set {
            guard newValue != titleLabel.text else { return }
            guard window != nil else {
                titleLabel.text = newValue
                return
            }
            UIView.transition(with: titleLabel, duration: Motion.fast, options: .transitionCrossDissolve) {
                self.titleLabel.text = newValue
            }
        }
    }

    private let titleLabel = UILabel()

    // MARK: - Init

    init(title: String) {
        super.init(frame: .zero)
        setupViews(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews(title: String) {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(resource: .backIcon), for: .normal)
        backButton.tintColor = Palette.textPrimary
        backButton.accessibilityLabel = String(localized: "Back")
        backButton.addAction(UIAction { [weak self] _ in self?.onBack?() }, for: .touchUpInside)

        titleLabel.text = title
        titleLabel.font = Typography.semibold18
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.accessibilityTraits = .header

        [backButton, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.backButtonLeading),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Layout.hitAreaSize),
            backButton.heightAnchor.constraint(equalToConstant: Layout.hitAreaSize),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: Spacing.s),
        ])
    }
}
