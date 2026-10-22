import Combine
import UIKit

final class OnboardingViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let indicatorToButtonSpacing: CGFloat = 20
        static let buttonSideInset = Spacing.l
        /// Не даёт кнопке прилипнуть к краю на устройствах без home indicator.
        static let minimumBottomSpacing = Spacing.l
    }

    // MARK: - Properties

    var onFinish: (@MainActor () -> Void)?

    private let viewModel: OnboardingViewModel
    private let backgroundView = GlowBackgroundView()
    private let scrollView = UIScrollView()
    private let pageViews: [OnboardingPageView]
    private let pageIndicator: OnboardingPageIndicator
    private let continueButton = PrimaryButton(title: String(localized: "Continue"))
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        let pages = viewModel.state.pages
        pageViews = pages.map(OnboardingPageView.init(page:))
        pageIndicator = OnboardingPageIndicator(pageCount: pages.count)
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
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        pageIndicator.setCurrentPage(viewModel.state.currentPageIndex, animated: false)

        continueButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.viewModel.continueTapped()
        }, for: .touchUpInside)

        [backgroundView, scrollView, pageIndicator, continueButton].forEach { view.addSubview($0) }
    }

    private func setupLayout() {
        let pagesStack = UIStackView(arrangedSubviews: pageViews)
        scrollView.addSubview(pagesStack)
        backgroundView.pinEdges(to: view)
        [scrollView, pagesStack, pageIndicator, continueButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let bottomAtSafeArea = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomAtSafeArea.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageIndicator.topAnchor),

            pagesStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pagesStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),

            pageIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageIndicator.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -Layout.indicatorToButtonSpacing),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.buttonSideInset),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.buttonSideInset),
            continueButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -Layout.minimumBottomSpacing),
            bottomAtSafeArea,
        ])
        pageViews.forEach { $0.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true }
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

    private func render(_ state: OnboardingViewModel.State) {
        pageIndicator.setCurrentPage(state.currentPageIndex, animated: true)
        scrollToPage(at: state.currentPageIndex)
    }

    private func handle(_ event: OnboardingViewModel.Event) {
        switch event {
        case .finished:
            onFinish?()
        }
    }

    /// Прокручивает, только если смена пришла от кнопки; после свайпа смещение уже на месте.
    private func scrollToPage(at index: Int) {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0, currentPageIndex != index else { return }
        scrollView.setContentOffset(CGPoint(x: pageWidth * CGFloat(index), y: 0), animated: true)
    }

    private var currentPageIndex: Int {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return 0 }
        return Int((scrollView.contentOffset.x / pageWidth).rounded())
    }
}

// MARK: - UIScrollViewDelegate

extension OnboardingViewController: UIScrollViewDelegate {
    /// Двигает индикатор, как только свайп проходит середину страницы.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isTracking || scrollView.isDecelerating else { return }
        viewModel.showPage(at: currentPageIndex)
    }
}
