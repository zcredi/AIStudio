import UIKit

/// Строка-капсула в настройках: градиентная иконка, заголовок, необязательная деталь и шеврон или переключатель.
final class SettingsRowView: UIControl {
    // MARK: - Types

    enum Accessory {
        case chevron
        case toggle
    }

    private enum Layout {
        static let height: CGFloat = 44
        static let insets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l)
        static let iconWidth: CGFloat = 28
        static let iconToTitleSpacing = Spacing.m
        static let cardColor = Palette.card.withAlphaComponent(0.4)
        static let detailColor = Palette.textPrimary.withAlphaComponent(0.4)
        static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        static let chevronConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
    }

    // MARK: - Properties

    /// Вызывается при переключении; действие нажатия на строку для переключателей не используется.
    var onToggle: ((Bool) -> Void)?

    var detail: String? {
        get { detailLabel.text }
        set {
            detailLabel.text = newValue
            accessibilityValue = newValue
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard accessory == .chevron, isHighlighted != oldValue else { return }
            backgroundView.alpha = isHighlighted ? 0.6 : 1
        }
    }

    private let accessory: Accessory
    private let backgroundView = UIView()
    private let detailLabel = UILabel()
    private let toggle = UISwitch()

    // MARK: - Init

    init(title: String, symbolName: String, fallbackSymbolName: String? = nil, accessory: Accessory = .chevron) {
        self.accessory = accessory
        super.init(frame: .zero)
        setupViews(title: title, symbolName: symbolName, fallbackSymbolName: fallbackSymbolName)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = bounds.height / 2
    }

    // MARK: - API

    func setToggleOn(_ isOn: Bool, animated: Bool) {
        guard toggle.isOn != isOn else { return }
        toggle.setOn(isOn, animated: animated)
    }

    // MARK: - Private

    private func setupViews(title: String, symbolName: String, fallbackSymbolName: String?) {
        backgroundView.backgroundColor = Layout.cardColor
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)
        backgroundView.pinEdges(to: self)

        let iconView = UIImageView(image: .gradientSymbol(named: symbolName, fallbackName: fallbackSymbolName, configuration: Layout.symbolConfiguration))
        iconView.contentMode = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typography.regular16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary

        detailLabel.font = UIFont.preferredFont(forTextStyle: .body)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = Layout.detailColor

        let row = UIStackView(arrangedSubviews: [iconView, titleLabel, detailLabel, makeAccessoryView()])
        row.alignment = .center
        row.spacing = Spacing.l
        row.setCustomSpacing(Layout.iconToTitleSpacing, after: iconView)
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = Layout.insets
        row.isUserInteractionEnabled = accessory == .toggle
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addSubview(row)
        row.pinEdges(to: self)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.height),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconWidth),
        ])
        setupAccessibility(title: title)
    }

    private func makeAccessoryView() -> UIView {
        switch accessory {
        case .chevron:
            let chevron = UIImageView(image: .gradientSymbol(named: "chevron.right", configuration: Layout.chevronConfiguration))
            chevron.setContentHuggingPriority(.required, for: .horizontal)
            return chevron
        case .toggle:
            toggle.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                onToggle?(toggle.isOn)
            }, for: .valueChanged)
            return toggle
        }
    }

    private func setupAccessibility(title: String) {
        switch accessory {
        case .chevron:
            isAccessibilityElement = true
            accessibilityLabel = title
            accessibilityTraits = .button
        case .toggle:
            // Доступный элемент — сам переключатель; заголовок строки он читает как свой лейбл.
            isAccessibilityElement = false
            toggle.accessibilityLabel = title
        }
    }
}
