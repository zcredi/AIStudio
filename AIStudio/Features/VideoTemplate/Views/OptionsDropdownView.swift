import UIKit

/// Стеклянный список вариантов, который всплывает над строкой своего параметра.
final class OptionsDropdownView: UIView {
    // MARK: - Types

    struct Option {
        let title: String
        let subtitle: String
        let symbolName: String?
        let isSelected: Bool
    }

    private enum Layout {
        static let width: CGFloat = 220
        static let cornerRadius: CGFloat = 20
    }

    // MARK: - Properties

    var onSelect: ((Int) -> Void)?
    /// Пользователи VoiceOver закрывают список жестом escape вместо тапа снаружи.
    var onDismiss: (() -> Void)?

    // MARK: - Init

    init(options: [Option]) {
        super.init(frame: .zero)
        setupViews(options: options)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func accessibilityPerformEscape() -> Bool {
        onDismiss?()
        return true
    }

    // MARK: - Private

    private func setupViews(options: [Option]) {
        let glassView = GlassView(material: .menu, shape: .roundedRect(cornerRadius: Layout.cornerRadius))
        addSubview(glassView)
        glassView.pinEdges(to: self)

        let rows = options.enumerated().map { index, option in
            let row = DropdownOptionRow(option: option, showsSeparator: index < options.count - 1)
            row.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            return row
        }
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        glassView.contentView.addSubview(stack)
        stack.pinEdges(to: glassView.contentView)
        glassView.contentView.clipsToBounds = true
        glassView.contentView.layer.cornerRadius = Layout.cornerRadius
        glassView.contentView.layer.cornerCurve = .continuous

        widthAnchor.constraint(equalToConstant: Layout.width).isActive = true
        accessibilityViewIsModal = true
    }
}
