import Combine
import UIKit

final class SplashViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let mascotSize = CGSize(width: 143, height: 142)
        static let mascotToProgressSpacing = Spacing.xxl
        static let progressSize = CGSize(width: 212, height: 4)
        static let trackColor = Palette.card
        /// Прогресс, пока идёт ожидание; остальное заполняется после загрузки.
        static let waitingProgress: CGFloat = 0.9
        static let waitingDuration: TimeInterval = 3
    }

    // MARK: - Properties

    var onFinish: (@MainActor () -> Void)?

    private let viewModel: SplashViewModel
    private let progressTrack = UIView()
    private let progressFill = GradientView()
    private var progressWidth: NSLayoutConstraint?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: SplashViewModel) {
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
        bind()
        viewModel.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setProgress(Layout.waitingProgress, duration: Layout.waitingDuration) {}
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background

        let mascotView = UIImageView(image: UIImage(resource: .mascot))
        mascotView.contentMode = .scaleAspectFit

        progressTrack.backgroundColor = Layout.trackColor
        progressTrack.layer.cornerRadius = Layout.progressSize.height / 2
        progressTrack.clipsToBounds = true
        progressTrack.addSubview(progressFill)
        progressTrack.isAccessibilityElement = true
        progressTrack.accessibilityLabel = String(localized: "Loading")
        progressTrack.accessibilityTraits = .updatesFrequently

        [mascotView, progressTrack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        progressFill.translatesAutoresizingMaskIntoConstraints = false

        let progressWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)
        self.progressWidth = progressWidth

        NSLayoutConstraint.activate([
            mascotView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mascotView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mascotView.widthAnchor.constraint(equalToConstant: Layout.mascotSize.width),
            mascotView.heightAnchor.constraint(equalToConstant: Layout.mascotSize.height),

            progressTrack.topAnchor.constraint(equalTo: mascotView.bottomAnchor, constant: Layout.mascotToProgressSpacing),
            progressTrack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressTrack.widthAnchor.constraint(equalToConstant: Layout.progressSize.width),
            progressTrack.heightAnchor.constraint(equalToConstant: Layout.progressSize.height),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressWidth,
        ])
    }

    private func bind() {
        viewModel.events
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)
    }

    private func handle(_ event: SplashViewModel.Event) {
        switch event {
        case .finished:
            setProgress(1, duration: Motion.fast) { [weak self] in
                self?.onFinish?()
            }
        }
    }

    private func setProgress(_ progress: CGFloat, duration: TimeInterval, completion: @escaping @MainActor () -> Void) {
        view.layoutIfNeeded()
        progressWidth?.constant = Layout.progressSize.width * progress
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut],
            animations: { self.view.layoutIfNeeded() },
            completion: { _ in completion() }
        )
    }
}
