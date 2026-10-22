import Combine
import UIKit

final class MainViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let sideInset = Spacing.l
        static let heroSpacing = Spacing.xxl
        static let sectionSpacing: CGFloat = 40
        static let minimumVerticalSpacing = Spacing.xxl
        static let heroIconSize: CGFloat = 60
        static let titleKern: CGFloat = 0.4
    }

    // MARK: - Properties

    var onOpenHistory: (@MainActor () -> Void)?
    var onOpenSettings: (@MainActor () -> Void)?
    var onOpenPaywall: (@MainActor () -> Void)?
    var onOpenChat: (@MainActor () -> Void)?
    var onOpenVideoGenerator: (@MainActor () -> Void)?

    private let viewModel: MainViewModel
    private let backgroundView = GlowBackgroundView()
    private let headerView = MainHeaderView()
    private let promptField = PromptFieldButton()
    private let videoCard = VideoFeatureCard()
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayout()
        setupActions()
        bind()
    }

    // MARK: - API

    /// Из этой карточки zoom-переходом раскрывается генератор видео.
    var videoCardView: UIView {
        videoCard
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        [backgroundView, headerView].forEach { view.addSubview($0) }
    }

    private func setupLayout() {
        let content = UIStackView(arrangedSubviews: [makeHero(), videoCard])
        content.axis = .vertical
        content.spacing = Layout.sectionSpacing
        view.addSubview(content)

        backgroundView.pinEdges(to: view)
        [headerView, content].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // Контент центрирован в пространстве под шапкой, как в макете.
        let contentArea = UILayoutGuide()
        view.addLayoutGuide(contentArea)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentArea.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentArea.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            content.centerYAnchor.constraint(equalTo: contentArea.centerYAnchor),
            content.topAnchor.constraint(greaterThanOrEqualTo: contentArea.topAnchor, constant: Layout.minimumVerticalSpacing),
        ])
    }

    private func makeHero() -> UIView {
        let iconView = UIImageView(image: UIImage(resource: .generateBLargeIcon))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.heroIconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.heroIconSize),
        ])

        let titleLabel = UILabel()
        titleLabel.attributedText = NSAttributedString(
            string: String(localized: "Your AI tools,\nready to go"),
            attributes: [.font: Typography.bold28, .kern: Layout.titleKern, .foregroundColor: Palette.textPrimary]
        )
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        let hero = UIStackView(arrangedSubviews: [iconView, titleLabel, promptField])
        hero.axis = .vertical
        hero.alignment = .center
        hero.spacing = Layout.heroSpacing
        promptField.widthAnchor.constraint(equalTo: hero.widthAnchor).isActive = true
        return hero
    }

    private func setupActions() {
        headerView.onHistory = { [weak self] in self?.onOpenHistory?() }
        headerView.onSettings = { [weak self] in self?.onOpenSettings?() }
        headerView.onPro = { [weak self] in self?.onOpenPaywall?() }
        promptField.addAction(UIAction { [weak self] _ in self?.onOpenChat?() }, for: .touchUpInside)
        videoCard.addAction(UIAction { [weak self] _ in self?.onOpenVideoGenerator?() }, for: .touchUpInside)
    }

    private func bind() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)
    }

    private func render(_ state: MainViewModel.State) {
        headerView.setProButtonVisible(state.isProButtonVisible, animated: view.window != nil)
    }
}
