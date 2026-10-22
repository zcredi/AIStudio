import UIKit

/// Приветствие «Your AI assistant for anything» с подсказками, видно до первого сообщения.
final class ChatEmptyStateView: UIView {
    // MARK: - Types

    private enum Layout {
        static let textSpacing = Spacing.s
        static let textToSuggestionsSpacing = Spacing.xxl
        static let sideInset = Spacing.l
        static let subtitleAlpha: CGFloat = 0.5
    }

    // MARK: - Properties

    var onSelectSuggestion: ((String) -> Void)? {
        get { suggestionsView.onSelect }
        set { suggestionsView.onSelect = newValue }
    }

    private let suggestionsView: ChatSuggestionsView

    // MARK: - Init

    init(suggestions: [String]) {
        suggestionsView = ChatSuggestionsView(suggestions: suggestions)
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews() {
        let titleLabel = UILabel()
        titleLabel.attributedText = Self.makeTitle()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.accessibilityTraits = .header

        let subtitleLabel = UILabel()
        subtitleLabel.text = String(localized: "Pick a suggestion below or ask your own question")
        subtitleLabel.font = Typography.regular14
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.subtitleAlpha)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, suggestionsView])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.textSpacing
        stack.setCustomSpacing(Layout.textToSuggestionsSpacing, after: subtitleLabel)
        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.sideInset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.sideInset),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor),
            suggestionsView.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    /// Лейбл обтягивает текст, поэтому pattern-градиент, разложенный по всей строке, попадает только на «AI assistant».
    private static func makeTitle() -> NSAttributedString {
        let font = Typography.semibold20
        let prefix = String(localized: "Your ")
        let highlight = String(localized: "AI assistant")
        let suffix = String(localized: " for anything")
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: Palette.textPrimary]

        let prefixWidth = (prefix as NSString).size(withAttributes: attributes).width
        let highlightWidth = (highlight as NSString).size(withAttributes: attributes).width
        let title = NSMutableAttributedString(string: prefix, attributes: attributes)
        title.append(NSAttributedString(string: highlight, attributes: [
            .font: font,
            .foregroundColor: gradientColor(start: prefixWidth, width: highlightWidth),
        ]))
        title.append(NSAttributedString(string: suffix, attributes: attributes))
        return title
    }

    private static func gradientColor(start: CGFloat, width: CGFloat) -> UIColor {
        let size = CGSize(width: ceil(start + width), height: 1)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = [Palette.gradientStart.cgColor, Palette.gradientEnd.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: start, y: 0),
                end: CGPoint(x: start + width, y: 0),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        return UIColor(patternImage: image)
    }
}
