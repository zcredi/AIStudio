import UIKit

/// Чипы подсказок, которые переносятся в строки по центру.
final class ChatSuggestionsView: UIView {
    // MARK: - Types

    private enum Layout {
        static let spacing = Spacing.s
        static let chipInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let chipColor = Palette.card.withAlphaComponent(0.8)
        static let chipBorderColor = Palette.accent.withAlphaComponent(0.12)
        static let chipTextColor = Palette.textPrimary.withAlphaComponent(0.9)
    }

    // MARK: - Properties

    var onSelect: ((String) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: arrangeChips(in: bounds.width, isApplying: false))
    }

    private var chips: [UIButton] = []
    private var lastLayoutWidth: CGFloat = 0

    // MARK: - Init

    init(suggestions: [String]) {
        super.init(frame: .zero)
        chips = suggestions.map(makeChip)
        chips.forEach(addSubview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        arrangeChips(in: bounds.width, isApplying: true)
        if lastLayoutWidth != bounds.width {
            lastLayoutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Private

    private func makeChip(title: String) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = Layout.chipTextColor
        configuration.contentInsets = Layout.chipInsets
        configuration.background.backgroundColor = Layout.chipColor
        configuration.background.strokeColor = Layout.chipBorderColor
        configuration.background.strokeWidth = 1
        configuration.cornerStyle = .capsule
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.regular14
            return attributes
        }
        let chip = UIButton(configuration: configuration)
        chip.addAction(UIAction { [weak self] _ in self?.onSelect?(title) }, for: .touchUpInside)
        return chip
    }

    /// Раскладывает чипы по строкам с выравниванием по центру и возвращает общую высоту.
    @discardableResult
    private func arrangeChips(in width: CGFloat, isApplying: Bool) -> CGFloat {
        guard width > 0 else { return 0 }
        var rows: [[(chip: UIButton, size: CGSize)]] = [[]]
        var rowWidth: CGFloat = 0
        for chip in chips {
            let size = chip.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            let neededWidth = rows[rows.count - 1].isEmpty ? size.width : rowWidth + Layout.spacing + size.width
            if neededWidth > width, !rows[rows.count - 1].isEmpty {
                rows.append([(chip, size)])
                rowWidth = size.width
            } else {
                rows[rows.count - 1].append((chip, size))
                rowWidth = neededWidth
            }
        }

        var y: CGFloat = 0
        for row in rows {
            let rowHeight = row.map(\.size.height).max() ?? 0
            let totalWidth = row.map(\.size.width).reduce(0, +) + Layout.spacing * CGFloat(max(row.count - 1, 0))
            var x = (width - totalWidth) / 2
            for item in row {
                if isApplying {
                    item.chip.frame = CGRect(x: x, y: y, width: min(item.size.width, width), height: rowHeight)
                }
                x += item.size.width + Layout.spacing
            }
            y += rowHeight + Layout.spacing
        }
        return max(y - Layout.spacing, 0)
    }
}
