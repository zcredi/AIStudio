import UIKit

/// Кнопки истории и настроек по краям, кнопка PRO посередине.
final class MainHeaderView: UIView {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.l)
        static let buttonSize: CGFloat = 40
    }

    // MARK: - Properties

    var onHistory: (() -> Void)?
    var onSettings: (() -> Void)?
    var onPro: (() -> Void)?

    private let historyButton = MainHeaderView.makeIconButton(image: UIImage(resource: .historyIcon), label: String(localized: "History"))
    private let settingsButton = MainHeaderView.makeIconButton(image: UIImage(resource: .settingsIcon), label: String(localized: "Settings"))
    private let proButton = ProButton()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    func setProButtonVisible(_ isVisible: Bool, animated: Bool) {
        let changes = { self.proButton.alpha = isVisible ? 1 : 0 }
        proButton.isUserInteractionEnabled = isVisible
        proButton.accessibilityElementsHidden = !isVisible
        guard animated else {
            changes()
            return
        }
        UIView.animate(withDuration: Motion.standard, animations: changes)
    }

    // MARK: - Private

    private static func makeIconButton(image: UIImage, label: String) -> UIButton {
        var configuration = UIButton.Configuration.adaptiveGlass()
        configuration.image = image
        configuration.contentInsets = .zero
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = label
        return button
    }

    private func setupViews() {
        historyButton.addAction(UIAction { [weak self] _ in self?.onHistory?() }, for: .touchUpInside)
        settingsButton.addAction(UIAction { [weak self] _ in self?.onSettings?() }, for: .touchUpInside)
        proButton.addAction(UIAction { [weak self] _ in self?.onPro?() }, for: .touchUpInside)

        [historyButton, proButton, settingsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let insets = Layout.insets
        NSLayoutConstraint.activate([
            historyButton.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            historyButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            historyButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            historyButton.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            historyButton.heightAnchor.constraint(equalToConstant: Layout.buttonSize),

            settingsButton.centerYAnchor.constraint(equalTo: historyButton.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
            settingsButton.widthAnchor.constraint(equalToConstant: Layout.buttonSize),
            settingsButton.heightAnchor.constraint(equalToConstant: Layout.buttonSize),

            proButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            proButton.centerYAnchor.constraint(equalTo: historyButton.centerYAnchor),
        ])
    }
}
