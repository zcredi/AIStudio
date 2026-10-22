import Combine
import PhotosUI
import UIKit

final class VideoResultViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let sideInset = Spacing.l
        static let videoToButtonsSpacing = Spacing.l
        static let buttonSpacing = Spacing.l
        static let buttonHeight: CGFloat = 50
        static let bottomInset = Spacing.l
        static let shareBackground = Palette.card.withAlphaComponent(0.6)
        static let statusBackdropAlpha: CGFloat = 0.6
        static let statusDuration: Duration = .seconds(2)
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    var onOpenGeneration: (@MainActor (VideoGeneration.ID) -> Void)?

    private let viewModel: VideoResultViewModel
    private let headerView = NavigationHeaderView(title: String(localized: "Result"))
    private let playerView: ResultPlayerView
    private let shareButton = UIButton(type: .system)
    private let downloadButton = PrimaryButton(title: String(localized: "Download"))
    private lazy var toastPresenter = ToastPresenter(containerView: view)
    private var statusDismissTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: VideoResultViewModel) {
        self.viewModel = viewModel
        playerView = ResultPlayerView(videoURL: viewModel.state.videoURL)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        statusDismissTask?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayout()
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.pause()
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        headerView.onBack = { [weak self] in self?.onBack?() }
        playerView.onTogglePlayback = { [weak self] in self?.viewModel.togglePlayback() }
        playerView.onReplace = { [weak self] in self?.viewModel.replaceTapped() }

        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Share")
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.background.backgroundColor = Layout.shareBackground
        configuration.background.cornerRadius = Radius.l
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold16
            return attributes
        }
        shareButton.configuration = configuration
        shareButton.addAction(UIAction { [weak self] _ in self?.viewModel.shareTapped() }, for: .touchUpInside)
        downloadButton.addAction(UIAction { [weak self] _ in self?.viewModel.downloadTapped() }, for: .touchUpInside)
    }

    private func setupLayout() {
        let buttons = UIStackView(arrangedSubviews: [shareButton, downloadButton])
        buttons.spacing = Layout.buttonSpacing
        buttons.distribution = .fillEqually

        let videoArea = UILayoutGuide()
        view.addLayoutGuide(videoArea)
        [headerView, playerView, buttons].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let aspectRatio = CGFloat(viewModel.state.format.aspectRatio)
        let preferredWidth = playerView.widthAnchor.constraint(equalTo: videoArea.widthAnchor)
        // Карточка максимально широкая, пока её высота помещается; высокие форматы уступают.
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            videoArea.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            videoArea.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            videoArea.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            videoArea.bottomAnchor.constraint(equalTo: buttons.topAnchor, constant: -Layout.videoToButtonsSpacing),

            playerView.centerXAnchor.constraint(equalTo: videoArea.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: videoArea.centerYAnchor),
            playerView.widthAnchor.constraint(lessThanOrEqualTo: videoArea.widthAnchor),
            playerView.heightAnchor.constraint(lessThanOrEqualTo: videoArea.heightAnchor),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: aspectRatio),
            preferredWidth,

            buttons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            buttons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            buttons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.bottomInset),
            buttons.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.buttonHeight),
        ])
    }

    private func bind() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)

        // Система ставит видео на паузу в фоне; экран тоже показывает его на паузе.
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.viewModel.pause() }
            .store(in: &cancellables)
    }

    private func render(_ state: VideoResultViewModel.State) {
        playerView.render(isPlaying: state.isPlaying, isReplacing: state.isReplacing)
        downloadButton.isLoading = state.isSaving
        downloadButton.isEnabled = !state.isSaving
    }

    private func handle(_ event: VideoResultViewModel.Event) {
        switch event {
        case .share(let url):
            present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
        case .showSaveResult(.saved):
            showSaveStatus(.saved)
        case .showSaveResult(.failed):
            showSaveStatus(.failed)
        case .showSaveResult(.accessDenied), .showPhotoAccessDenied:
            present(UIAlertController.makePhotoAccessAlert(), animated: true)
        case .showPhotoPicker:
            present(PHPickerViewController.makeSingleImagePicker(delegate: self), animated: true)
        case .showToast(.uploadFailed):
            toastPresenter.show(.failure, message: String(localized: "Upload failed"))
        case .showError(let error):
            let alert = UIAlertController(title: String(localized: "Something went wrong"), message: error.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default))
            present(alert, animated: true)
        case .openGeneration(let id):
            onOpenGeneration?(id)
        }
    }

    /// Затемняет экран и ненадолго показывает результат сохранения; тап закрывает его раньше.
    private func showSaveStatus(_ status: SaveStatusView.Status) {
        statusDismissTask?.cancel()
        let backdrop = UIControl()
        backdrop.backgroundColor = Palette.dim.withAlphaComponent(Layout.statusBackdropAlpha)
        let statusView = SaveStatusView(status: status)
        statusView.isUserInteractionEnabled = false
        backdrop.addSubview(statusView)
        view.addSubview(backdrop)
        backdrop.pinEdges(to: view)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.centerXAnchor.constraint(equalTo: backdrop.centerXAnchor),
            statusView.centerYAnchor.constraint(equalTo: backdrop.centerYAnchor),
        ])

        backdrop.alpha = 0
        UIView.animate(withDuration: Motion.standard) { backdrop.alpha = 1 }
        UIAccessibility.post(notification: .announcement, argument: statusView.accessibilityLabel)
        if status == .saved {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        backdrop.addAction(UIAction { [weak self, weak backdrop] _ in
            self?.statusDismissTask?.cancel()
            if let backdrop {
                Self.hideStatus(backdrop)
            }
        }, for: .touchUpInside)
        statusDismissTask = Task { [weak backdrop] in
            // Отмена значит, что статус уже закрывается.
            try? await Task.sleep(for: Layout.statusDuration)
            guard !Task.isCancelled, let backdrop else { return }
            Self.hideStatus(backdrop)
        }
    }

    private static func hideStatus(_ backdrop: UIView) {
        UIView.animate(withDuration: Motion.standard) {
            backdrop.alpha = 0
        } completion: { _ in
            backdrop.removeFromSuperview()
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension VideoResultViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        // Cancel не возвращает результатов, и текущее видео остаётся.
        guard let provider = results.first?.itemProvider else { return }
        viewModel.replacePhoto { try await PhotoLoader.load(from: provider) }
    }
}
