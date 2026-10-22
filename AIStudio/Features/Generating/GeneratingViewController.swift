import Combine
import UIKit

final class GeneratingViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let loaderToTextSpacing: CGFloat = 40
        static let textSpacing = Spacing.s
        static let textWidth: CGFloat = 344
        static let sideInset = Spacing.l
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    var onOpenResult: (@MainActor (VideoGeneration) -> Void)?

    private let viewModel: GeneratingViewModel
    private let headerView = NavigationHeaderView(title: "")
    private let progressView = UIView()
    private let errorView = ErrorStateView()
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: GeneratingViewModel) {
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
        bind()
        viewModel.start()
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        headerView.onBack = { [weak self] in self?.onBack?() }
        errorView.onRetry = { [weak self] in self?.viewModel.retryTapped() }
        errorView.alpha = 0
    }

    private func setupLayout() {
        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Generating…")
        titleLabel.font = Typography.semibold20
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header

        let subtitleLabel = UILabel()
        subtitleLabel.text = String(localized: "We’re creating the best result for you")
        subtitleLabel.font = Typography.regular16
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = Palette.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let texts = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        texts.axis = .vertical
        texts.spacing = Layout.textSpacing

        let stack = UIStackView(arrangedSubviews: [GeneratingLoaderView(), texts])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.loaderToTextSpacing
        progressView.addSubview(stack)

        [headerView, progressView, errorView, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            if $0 !== stack { view.addSubview($0) }
        }
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            texts.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.textWidth),
            texts.widthAnchor.constraint(lessThanOrEqualTo: progressView.widthAnchor, constant: -2 * Layout.sideInset),
        ])
        for stateView in [progressView, errorView] {
            NSLayoutConstraint.activate([
                stateView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
                stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
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

    private func render(_ state: GeneratingViewModel.State) {
        let visibleView: UIView
        switch state {
        case .generating:
            visibleView = progressView
        case .failed(let error):
            errorView.message = error.message
            visibleView = errorView
        }
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            self.progressView.alpha = visibleView === self.progressView ? 1 : 0
            self.errorView.alpha = visibleView === self.errorView ? 1 : 0
        }
        [progressView, errorView].forEach {
            $0.isUserInteractionEnabled = $0 === visibleView
            $0.accessibilityElementsHidden = $0 !== visibleView
        }
        if visibleView === errorView {
            UIAccessibility.post(notification: .screenChanged, argument: errorView)
        }
    }

    private func handle(_ event: GeneratingViewModel.Event) {
        switch event {
        case .openResult(let generation):
            onOpenResult?(generation)
        }
    }
}
