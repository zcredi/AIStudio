import Combine
import UIKit

final class PaywallViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let contentInsets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let featuresToPlansSpacing: CGFloat = 32
        static let closeButtonSize: CGFloat = 44
        /// Центрирует область нажатия 44 pt на иконке 24 pt, которая в макете стоит в 16 pt от угла.
        static let closeButtonOffset: CGFloat = 6
        static let closeButtonAlpha: CGFloat = 0.7
        /// Дизайнер попросил едва заметную кнопку закрытия, которая появляется через 2 секунды.
        static let closeButtonRevealDelay: TimeInterval = 2
    }

    // MARK: - Properties

    var onClose: (@MainActor () -> Void)?
    /// Вызывается, когда премиум-доступ активен: после покупки или восстановления.
    var onAccessGranted: (@MainActor () -> Void)?
    var onPrivacyPolicy: (@MainActor () -> Void)?
    var onTermsOfUse: (@MainActor () -> Void)?

    private let viewModel: PaywallViewModel
    private let backgroundView = GlowBackgroundView()
    private let scrollView = UIScrollView()
    private let featuresView = PaywallFeaturesView()
    private let plansView = PaywallPlansView()
    private let bottomBar = PaywallBottomBar()
    private let closeButton = UIButton(type: .system)
    private var cancellables: Set<AnyCancellable> = []
    private var isCloseButtonScheduled = false

    // MARK: - Init

    init(viewModel: PaywallViewModel) {
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
        viewModel.load()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // На коротких экранах (iPhone SE) маскот убирается, чтобы планы помещались над кнопкой покупки.
        let isOverflowing = scrollView.contentSize.height > scrollView.bounds.height + 1
        if isOverflowing, !featuresView.isMascotHidden {
            featuresView.isMascotHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        revealCloseButton()
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let image = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        )
        closeButton.setImage(image, for: .normal)
        closeButton.tintColor = Palette.textPrimary
        closeButton.alpha = 0
        closeButton.accessibilityLabel = String(localized: "Close")

        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        view.addSubview(bottomBar)
        view.addSubview(closeButton)
    }

    private func setupLayout() {
        let content = UIStackView(arrangedSubviews: [featuresView, plansView])
        content.axis = .vertical
        content.spacing = Layout.featuresToPlansSpacing
        scrollView.addSubview(content)

        backgroundView.pinEdges(to: view)
        [scrollView, bottomBar, closeButton, content].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let insets = Layout.contentInsets
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Контент прижат книзу, как в макете, и прокручивается, если не помещается (iPhone SE).
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: insets.leading),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -insets.trailing),
            content.topAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor, constant: insets.top),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -insets.bottom),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.closeButtonOffset),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.closeButtonOffset),
            closeButton.widthAnchor.constraint(equalToConstant: Layout.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Layout.closeButtonSize),
        ])

        // Позволяет контенту задавать высоту прокрутки, когда он выше экрана.
        let fittingHeight = scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        fittingHeight.priority = .defaultLow
        fittingHeight.isActive = true
    }

    private func setupActions() {
        closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)
        plansView.onSelectPlan = { [weak self] id in
            UISelectionFeedbackGenerator().selectionChanged()
            self?.viewModel.selectPlan(id: id)
        }
        plansView.onRetry = { [weak self] in self?.viewModel.load() }
        bottomBar.onUnlock = { [weak self] in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self?.viewModel.purchase()
        }
        bottomBar.onRestore = { [weak self] in self?.viewModel.restore() }
        bottomBar.onPrivacyPolicy = { [weak self] in self?.onPrivacyPolicy?() }
        bottomBar.onTermsOfUse = { [weak self] in self?.onTermsOfUse?() }
    }

    private func bind() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)
    }

    private func render(_ state: PaywallViewModel.State) {
        plansView.render(state.plans, selectedPlanID: state.selectedPlanID, isInteractionEnabled: !state.isProcessing)
        bottomBar.render(isUnlockEnabled: state.selectedPlanID != nil && state.plans.value != nil, isProcessing: state.isProcessing)
        closeButton.isEnabled = !state.isProcessing
    }

    private func handle(_ event: PaywallViewModel.Event) {
        switch event {
        case .accessGranted:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onAccessGranted?()
        case .purchasePending:
            showAlert(
                title: String(localized: "Purchase pending"),
                message: String(localized: "Access opens as soon as the purchase is approved.")
            )
        case .showError(let error):
            showAlert(title: String(localized: "Something went wrong"), message: error.message)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default))
        present(alert, animated: true)
    }

    private func revealCloseButton() {
        guard !isCloseButtonScheduled else { return }
        isCloseButtonScheduled = true
        UIView.animate(withDuration: Motion.standard, delay: Layout.closeButtonRevealDelay) {
            self.closeButton.alpha = Layout.closeButtonAlpha
        }
    }
}
