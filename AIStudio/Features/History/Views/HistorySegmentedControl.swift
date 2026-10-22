import UIKit

/// Переключатель «Chat / Video»: капсула с подсветкой, которая съезжает к выбранному сегменту.
final class HistorySegmentedControl: UIControl {
    // MARK: - Types

    private enum Layout {
        static let height: CGFloat = 40
        static let inset: CGFloat = 4
        static let trackColor = Palette.card.withAlphaComponent(0.4)
        static let highlightColor = Palette.accent.withAlphaComponent(0.08)
    }

    // MARK: - Properties

    private(set) var selectedIndex = 0

    private let highlightView = UIView()
    private var segmentButtons: [UIButton] = []
    private var highlightLeading: NSLayoutConstraint?

    // MARK: - Init

    init(titles: [String]) {
        super.init(frame: .zero)
        setupViews(titles: titles)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        highlightView.layer.cornerRadius = highlightView.bounds.height / 2
        updateHighlightPosition()
    }

    // MARK: - API

    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard segmentButtons.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
        updateAccessibility()
        guard animated, window != nil else {
            setNeedsLayout()
            return
        }
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            self.updateHighlightPosition()
            self.layoutIfNeeded()
        }
    }

    // MARK: - Private

    private func setupViews(titles: [String]) {
        backgroundColor = Layout.trackColor
        layer.cornerCurve = .continuous
        highlightView.backgroundColor = Layout.highlightColor
        highlightView.layer.cornerCurve = .continuous
        highlightView.isUserInteractionEnabled = false
        addSubview(highlightView)

        segmentButtons = titles.enumerated().map { index, title in makeSegment(title: title, index: index) }
        let stack = UIStackView(arrangedSubviews: segmentButtons)
        stack.distribution = .fillEqually
        addSubview(stack)

        [stack, highlightView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let highlightLeading = highlightView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.inset)
        self.highlightLeading = highlightLeading
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.inset),
            highlightView.topAnchor.constraint(equalTo: stack.topAnchor),
            highlightView.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
            highlightView.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1 / CGFloat(max(titles.count, 1))),
            highlightLeading,
        ])
        updateAccessibility()
    }

    private func makeSegment(title: String, index: Int) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold16
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in
            guard let self, index != selectedIndex else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            setSelectedIndex(index, animated: true)
            sendActions(for: .valueChanged)
        }, for: .touchUpInside)
        return button
    }

    private func updateHighlightPosition() {
        let segmentWidth = (bounds.width - Layout.inset * 2) / CGFloat(max(segmentButtons.count, 1))
        highlightLeading?.constant = Layout.inset + segmentWidth * CGFloat(selectedIndex)
    }

    private func updateAccessibility() {
        for (index, button) in segmentButtons.enumerated() {
            button.accessibilityTraits = index == selectedIndex ? [.button, .selected] : .button
        }
    }
}
