import Combine
import UIKit

final class ChatViewController: UIViewController {
    // MARK: - Types

    private enum Section {
        case conversation
    }

    private enum Layout {
        static let messageSpacing = Spacing.xxl
        static let verticalInset = Spacing.xxl
        static let estimatedRowHeight: CGFloat = 80
        static let dateFormat = Date.VerbatimFormatStyle(
            format: "\(day: .twoDigits).\(month: .twoDigits).\(year: .defaultDigits)",
            timeZone: .current,
            calendar: .current
        )
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    /// Чат удалён; координатор возвращается на главный экран.
    var onDeleted: (@MainActor () -> Void)?

    private let viewModel: ChatViewModel
    private let markdownRenderer = MarkdownRenderer()
    private let shouldFocusInput: Bool
    private let headerView = ChatHeaderView()
    private let inputBar = ChatInputBar()
    private let inputBackground = UIView()
    private let emptyStateView = ChatEmptyStateView(suggestions: ChatViewModel.suggestions)
    private let historyStatusView = ChatHistoryStatusView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var dataSource = makeDataSource()
    private lazy var toastPresenter = ToastPresenter(containerView: view)
    private var itemsByID: [ChatItem.ID: ChatItem] = [:]
    private var renderedMenuState: (isPinned: Bool, hasConversation: Bool)?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    /// Новый чат открывается с поднятой клавиатурой, как в макете.
    init(viewModel: ChatViewModel, shouldFocusInput: Bool) {
        self.viewModel = viewModel
        self.shouldFocusInput = shouldFocusInput
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldFocusInput, viewModel.state.items.isEmpty {
            inputBar.focus()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Сообщения прокручиваются под стеклянной шапкой.
        let topInset = headerView.frame.maxY
        guard collectionView.contentInset.top != topInset else { return }
        collectionView.contentInset.top = topInset
        collectionView.verticalScrollIndicatorInsets.top = topInset
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true
        inputBackground.backgroundColor = Palette.card
        historyStatusView.isHidden = true

        [collectionView, emptyStateView, historyStatusView, headerView, inputBackground, inputBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            emptyStateView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            historyStatusView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            historyStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyStatusView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            // Панель едет вместе с клавиатурой; её цвет продолжается под home indicator.
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            inputBackground.topAnchor.constraint(equalTo: inputBar.bottomAnchor),
            inputBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActions() {
        headerView.onBack = { [weak self] in self?.onBack?() }
        inputBar.onTextChange = { [weak self] in self?.viewModel.updateDraft($0) }
        inputBar.onSend = { [weak self] in self?.viewModel.sendTapped() }
        emptyStateView.onSelectSuggestion = { [weak self] suggestion in
            self?.viewModel.applySuggestion(suggestion)
            self?.inputBar.focus()
        }
        historyStatusView.onRetry = { [weak self] in self?.viewModel.load() }

        // Лента сама прячет клавиатуру при прокрутке, но короткий чат и заглушка не прокручиваются,
        // поэтому тап и свайп вниз в любом месте экрана тоже её закрывают.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDown.direction = .down
        for recognizer in [tap, swipeDown] {
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            view.addGestureRecognizer(recognizer)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func bind() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in self?.scrollToBottom(animated: true) }
            .store(in: &cancellables)
    }

    private func render(_ state: ChatViewModel.State) {
        renderHeader(state)
        inputBar.render(
            text: state.draft,
            placeholder: state.items.isEmpty ? String(localized: "Ask anything...") : String(localized: "How can I help you?"),
            canSend: state.canSend
        )
        apply(state.items)
        historyStatusView.render(state.history)
        setVisible(historyStatusView, state.history.value == nil)
        setVisible(emptyStateView, state.history.value != nil && state.items.isEmpty)
    }

    private func renderHeader(_ state: ChatViewModel.State) {
        let menuState = (isPinned: state.isPinned, hasConversation: state.hasConversation)
        guard renderedMenuState.map({ $0 != menuState }) ?? true else { return }
        renderedMenuState = menuState
        headerView.render(
            date: state.date.formatted(Layout.dateFormat),
            isPinned: state.isPinned,
            menu: state.hasConversation ? makeMenu(isPinned: state.isPinned) : nil
        )
    }

    /// Плавно показывает или прячет заглушку, чтобы загрузка, пустой чат и переписка сменялись без рывка.
    private func setVisible(_ stateView: UIView, _ isVisible: Bool) {
        let isShown = !stateView.isHidden && stateView.alpha > 0
        guard isShown != isVisible else { return }
        if isVisible, stateView.isHidden {
            stateView.alpha = 0
            stateView.isHidden = false
        }
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            stateView.alpha = isVisible ? 1 : 0
        } completion: { _ in
            // Пока вид исчезал, его могли попросить показать снова.
            if stateView.alpha == 0 {
                stateView.isHidden = true
            }
        }
    }

    private func makeMenu(isPinned: Bool) -> UIMenu {
        UIMenu(children: [
            UIAction(title: String(localized: "Share"), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.viewModel.shareTapped()
            },
            UIAction(
                title: isPinned ? String(localized: "Unpin chat") : String(localized: "Pin chat"),
                image: UIImage(systemName: isPinned ? "pin.slash" : "pin")
            ) { [weak self] _ in
                self?.viewModel.togglePinTapped()
            },
            UIAction(title: String(localized: "Delete chat"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.viewModel.deleteTapped()
            },
        ])
    }

    private func handle(_ event: ChatViewModel.Event) {
        switch event {
        case .showToast(.copied):
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            toastPresenter.show(.success, message: String(localized: "Copied"))
        case .showToast(.copyFailed):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            toastPresenter.show(.failure, message: String(localized: "Copy failed"))
        case .share(let text):
            present(UIActivityViewController(activityItems: [text], applicationActivities: nil), animated: true)
        case .confirmDeletion:
            confirmDeletion()
        case .deleted:
            onDeleted?()
        }
    }

    private func confirmDeletion() {
        let alert = UIAlertController(
            title: String(localized: "Delete chat?"),
            message: String(localized: "This chat will be removed from your history."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.deletionConfirmed()
        })
        present(alert, animated: true)
    }

    private func scrollToBottom(animated: Bool) {
        let lastItem = collectionView.numberOfItems(inSection: 0) - 1
        guard lastItem >= 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: lastItem, section: 0), at: .bottom, animated: animated)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ChatViewController: UIGestureRecognizerDelegate {
    /// Поле ввода и кнопки обрабатывают касания сами: тап по подсказке вставляет текст и оставляет клавиатуру.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var touchedView = touch.view
        while let current = touchedView, current !== view {
            if current === inputBar || current is UIControl {
                return false
            }
            touchedView = current.superview
        }
        return true
    }

    /// Свайп вниз срабатывает вместе с прокруткой ленты, а не вместо неё.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - Collection

extension ChatViewController {
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(Layout.estimatedRowHeight))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Layout.messageSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: Layout.verticalInset, leading: 0, bottom: Layout.verticalInset, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, ChatItem.ID> {
        let userRegistration = UICollectionView.CellRegistration<UserMessageCell, ChatMessage> { cell, _, message in
            cell.configure(with: message)
        }
        let assistantRegistration = UICollectionView.CellRegistration<AssistantMessageCell, ChatItem> { [weak self] cell, _, item in
            guard let self, case .message(let message, let canRegenerate) = item else { return }
            cell.configure(with: markdownRenderer.render(message.text, cacheKey: message.id), canRegenerate: canRegenerate)
            cell.onCopy = { [weak self] in self?.viewModel.copyMessage(id: message.id) }
            cell.onRegenerate = { [weak self] in self?.viewModel.regenerateTapped() }
        }
        let typingRegistration = UICollectionView.CellRegistration<TypingIndicatorCell, ChatItem> { _, _, _ in }
        let failureRegistration = UICollectionView.CellRegistration<ChatFailureCell, UserFacingError> { [weak self] cell, _, error in
            cell.configure(with: error)
            cell.onRetry = { [weak self] in self?.viewModel.retryTapped() }
        }

        return UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, id in
            guard let item = self?.itemsByID[id] else { return nil }
            switch item {
            case .message(let message, _) where message.role == .user:
                return collectionView.dequeueConfiguredReusableCell(using: userRegistration, for: indexPath, item: message)
            case .message:
                return collectionView.dequeueConfiguredReusableCell(using: assistantRegistration, for: indexPath, item: item)
            case .typing:
                return collectionView.dequeueConfiguredReusableCell(using: typingRegistration, for: indexPath, item: item)
            case .failure(let error):
                return collectionView.dequeueConfiguredReusableCell(using: failureRegistration, for: indexPath, item: error)
            }
        }
    }

    /// Изменившиеся строки переконфигурируются на месте; новые строки прокручивают переписку вниз.
    private func apply(_ items: [ChatItem]) {
        let previousItems = itemsByID
        itemsByID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })

        var snapshot = NSDiffableDataSourceSnapshot<Section, ChatItem.ID>()
        snapshot.appendSections([.conversation])
        snapshot.appendItems(items.map(\.id))
        let changedIDs = items
            .filter { item in previousItems[item.id].map { $0 != item } ?? false }
            .map(\.id)
        snapshot.reconfigureItems(changedIDs)

        let hasNewRows = items.contains { previousItems[$0.id] == nil }
        let isFirstLoad = previousItems.isEmpty
        dataSource.apply(snapshot, animatingDifferences: !isFirstLoad && view.window != nil) { [weak self] in
            guard hasNewRows else { return }
            self?.scrollToBottom(animated: !isFirstLoad)
        }
    }
}
