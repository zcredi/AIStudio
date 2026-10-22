import Combine
import UIKit

final class HistoryViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let segmentedInsets = NSDirectionalEdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.l)
        static let contentTopInset = Spacing.xxl
        static let headerToRowsSpacing = Spacing.l
        static let rowSpacing = Spacing.m
        static let sectionSpacing: CGFloat = 32
        static let sideInset = Spacing.l
        static let videoInsets = NSDirectionalEdgeInsets(top: Spacing.xxl, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let videoSpacing = Spacing.s
    }

    private enum VideoSection {
        case main
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    var onOpenChat: (@MainActor (Chat) -> Void)?
    var onOpenVideo: (@MainActor (VideoGeneration) -> Void)?
    var onOpenGeneration: (@MainActor (VideoGeneration.ID) -> Void)?

    private let viewModel: HistoryViewModel
    private let autoplay: AutoplayController
    private let thumbnails: ThumbnailLoader
    private let headerView = NavigationHeaderView(title: String(localized: "History"))
    private let segmentedControl = HistorySegmentedControl(titles: [String(localized: "Chat"), String(localized: "Video")])
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var dataSource = makeDataSource()
    private lazy var videosView = UICollectionView(frame: .zero, collectionViewLayout: makeVideosLayout())
    private lazy var videosDataSource = makeVideosDataSource()
    private let skeletonView = HistorySkeletonView()
    private let errorView = ErrorStateView()
    private let chatsEmptyView = EmptyStateView(
        icon: UIImage(resource: .magicPencilAIcon),
        title: String(localized: "No chats yet"),
        subtitle: String(localized: "Start a conversation to see your history here")
    )
    private let videosEmptyView = EmptyStateView(
        icon: UIImage(resource: .imageToImageIcon),
        title: String(localized: "No videos yet"),
        subtitle: String(localized: "Create your first video to see it here")
    )
    private var sectionsByID: [ChatHistorySection.ID: ChatHistorySection] = [:]
    private var videosByID: [VideoGeneration.ID: HistoryViewModel.VideoItem] = [:]
    /// В порядке снапшота; по ним masonry-раскладка считает высоты карточек.
    private var videoAspectRatios: [CGFloat] = []
    private var hasAppeared = false
    private var isOnScreen = false
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: HistoryViewModel, autoplay: AutoplayController, thumbnails: ThumbnailLoader) {
        self.viewModel = viewModel
        self.autoplay = autoplay
        self.thumbnails = thumbnails
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
        autoplay.attach(to: videosView)
        viewModel.load()
    }

    /// После возврата из чата его могли закрепить, переименовать или удалить.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasAppeared {
            viewModel.load()
        }
        hasAppeared = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOnScreen = true
        updateAutoplay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isOnScreen = false
        updateAutoplay()
    }

    // MARK: - API

    /// Карточка, из которой экран видео раскрывается zoom-переходом и в которую возвращается; при необходимости
    /// докручивается в видимую область.
    func videoCardView(for id: VideoGeneration.ID) -> UIView? {
        guard let indexPath = videosDataSource.indexPath(for: id) else { return nil }
        if videosView.cellForItem(at: indexPath) == nil {
            videosView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            videosView.layoutIfNeeded()
        }
        return videosView.cellForItem(at: indexPath)
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: Layout.contentTopInset, left: 0, bottom: Spacing.l, right: 0)
        collectionView.delegate = self
        videosView.backgroundColor = .clear
        videosView.showsVerticalScrollIndicator = false
        videosView.delegate = self

        [headerView, segmentedControl, collectionView, videosView, skeletonView, errorView, chatsEmptyView, videosEmptyView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func setupLayout() {
        let insets = Layout.segmentedInsets
        var constraints = [
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            segmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: insets.top),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.leading),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.trailing),
        ]
        // Каждое состояние контента занимает область под переключателем.
        for contentView in [collectionView, videosView, skeletonView, errorView, chatsEmptyView, videosEmptyView] {
            constraints += [
                contentView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: insets.bottom),
                contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func setupActions() {
        headerView.onBack = { [weak self] in self?.onBack?() }
        errorView.onRetry = { [weak self] in self?.viewModel.load() }
        segmentedControl.addAction(UIAction { [weak self] _ in
            guard let self, let tab = HistoryViewModel.Tab(rawValue: segmentedControl.selectedIndex) else { return }
            viewModel.selectTab(tab)
        }, for: .valueChanged)
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

    private func render(_ state: HistoryViewModel.State) {
        segmentedControl.setSelectedIndex(state.selectedTab.rawValue, animated: true)
        if case .failed(let error) = state.chats {
            errorView.message = error.message
        }
        if let sections = state.chats.value {
            apply(sections)
        }
        applyVideos(state.videos)
        show(visibleView(for: state))
        updateAutoplay()
    }

    private func visibleView(for state: HistoryViewModel.State) -> UIView {
        switch (state.selectedTab, state.chats) {
        case (.videos, _):
            state.videos.isEmpty ? videosEmptyView : videosView
        case (.chats, .loading):
            skeletonView
        case (.chats, .failed):
            errorView
        case (.chats, .loaded(let sections)):
            sections.isEmpty ? chatsEmptyView : collectionView
        }
    }

    /// Кроссфейд между списком, skeleton, ошибкой и пустым состоянием.
    private func show(_ visibleView: UIView) {
        let views = [collectionView, videosView, skeletonView, errorView, chatsEmptyView, videosEmptyView]
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            views.forEach { $0.alpha = $0 === visibleView ? 1 : 0 }
        }
        views.forEach {
            $0.isUserInteractionEnabled = $0 === visibleView
            $0.accessibilityElementsHidden = $0 !== visibleView
        }
    }

    private func handle(_ event: HistoryViewModel.Event) {
        switch event {
        case .openChat(let chat):
            onOpenChat?(chat)
        case .openVideo(let generation):
            onOpenVideo?(generation)
        case .openGeneration(let id):
            onOpenGeneration?(id)
        }
    }

    /// Видео играют, только пока их вкладка на экране.
    private func updateAutoplay() {
        if isOnScreen, viewModel.state.selectedTab == .videos {
            autoplay.resume()
        } else {
            autoplay.suspend()
        }
    }

    private func presentRename(for row: ChatHistorySection.Row) {
        let alert = UIAlertController(
            title: String(localized: "Rename chat"),
            message: String(localized: "Enter a new name for this chat"),
            preferredStyle: .alert
        )
        let save = UIAlertAction(title: String(localized: "Save"), style: .default) { [weak self, weak alert] _ in
            self?.viewModel.renameChat(id: row.id, to: alert?.textFields?.first?.text ?? "")
        }
        alert.addTextField { textField in
            textField.text = row.title
            textField.placeholder = String(localized: "Chat name")
            textField.clearButtonMode = .whileEditing
            textField.autocapitalizationType = .sentences
            textField.addAction(UIAction { [weak save, weak textField] _ in
                save?.isEnabled = HistoryViewModel.isValidTitle(textField?.text ?? "")
            }, for: .editingChanged)
        }
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(save)
        alert.preferredAction = save
        present(alert, animated: true)
    }

    private func presentDeletion(for row: ChatHistorySection.Row) {
        let alert = UIAlertController(
            title: String(localized: "Delete chat?"),
            message: String(localized: "This chat will be removed from your history."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.deleteChat(id: row.id)
        })
        present(alert, animated: true)
    }

    private func row(at indexPath: IndexPath) -> ChatHistorySection.Row? {
        guard
            let sectionID = dataSource.sectionIdentifier(for: indexPath.section),
            let rowID = dataSource.itemIdentifier(for: indexPath)
        else {
            return nil
        }
        return sectionsByID[sectionID]?.rows.first { $0.id == rowID }
    }
}

// MARK: - Collection

extension HistoryViewController {
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            configuration.backgroundColor = .clear
            configuration.headerMode = .supplementary
            configuration.headerTopPadding = 0
            configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
                self?.swipeActions(at: indexPath)
            }
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            section.interGroupSpacing = Layout.rowSpacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: Layout.headerToRowsSpacing,
                leading: Layout.sideInset,
                bottom: Layout.sectionSpacing,
                trailing: Layout.sideInset
            )
            return section
        }
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<ChatHistorySection.ID, ChatHistorySection.Row.ID> {
        let cellRegistration = UICollectionView.CellRegistration<HistoryChatCell, ChatHistorySection.Row> { cell, _, row in
            cell.configure(with: row)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<HistorySectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            guard let sectionID = self?.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            header.title = self?.sectionsByID[sectionID]?.title
        }

        let dataSource = UICollectionViewDiffableDataSource<ChatHistorySection.ID, ChatHistorySection.Row.ID>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, _ in
            guard let row = self?.row(at: indexPath) else { return nil }
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: row)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    private func apply(_ sections: [ChatHistorySection]) {
        let previousSections = sectionsByID
        sectionsByID = Dictionary(sections.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })

        var snapshot = NSDiffableDataSourceSnapshot<ChatHistorySection.ID, ChatHistorySection.Row.ID>()
        for section in sections {
            snapshot.appendSections([section.id])
            snapshot.appendItems(section.rows.map(\.id), toSection: section.id)
        }
        let previousRows = previousSections.values.flatMap(\.rows)
        let changedRowIDs = sections.flatMap(\.rows).filter { row in
            previousRows.first { $0.id == row.id }.map { $0 != row } ?? false
        }.map(\.id)
        snapshot.reconfigureItems(changedRowIDs)
        dataSource.apply(snapshot, animatingDifferences: !previousSections.isEmpty && view.window != nil)
    }

    private func swipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let row = row(at: indexPath) else { return nil }
        let delete = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.presentDeletion(for: row)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = Palette.actionRed
        delete.accessibilityLabel = String(localized: "Delete")

        let rename = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.presentRename(for: row)
            completion(true)
        }
        rename.image = UIImage(systemName: "pencil")
        rename.backgroundColor = Palette.actionOrange
        rename.accessibilityLabel = String(localized: "Rename")

        let configuration = UISwipeActionsConfiguration(actions: [delete, rename])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

// MARK: - Videos

extension HistoryViewController {
    private func makeVideosLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] _, environment in
            MasonryLayout.makeSection(
                aspectRatios: self?.videoAspectRatios ?? [],
                environment: environment,
                spacing: Layout.videoSpacing,
                insets: Layout.videoInsets
            )
        }
    }

    private func makeVideosDataSource() -> UICollectionViewDiffableDataSource<VideoSection, VideoGeneration.ID> {
        let registration = UICollectionView.CellRegistration<HistoryVideoCell, VideoGeneration.ID> { [weak self] cell, _, id in
            guard let self, let item = videosByID[id] else { return }
            cell.configure(with: item, thumbnails: thumbnails)
            cell.onRetry = { [weak self] in self?.viewModel.retryVideo(id: id) }
        }
        return UICollectionViewDiffableDataSource(collectionView: videosView) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
        }
    }

    private func applyVideos(_ videos: [HistoryViewModel.VideoItem]) {
        let previousVideos = videosByID
        videosByID = Dictionary(videos.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        videoAspectRatios = videos.map { CGFloat($0.aspectRatio) }

        var snapshot = NSDiffableDataSourceSnapshot<VideoSection, VideoGeneration.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(videos.map(\.id))
        let changedIDs = videos.filter { video in previousVideos[video.id].map { $0 != video } ?? false }.map(\.id)
        snapshot.reconfigureItems(changedIDs)
        videosDataSource.apply(snapshot, animatingDifferences: !previousVideos.isEmpty && view.window != nil) { [weak self] in
            self?.autoplay.refresh()
        }
    }
}

// MARK: - UICollectionViewDelegate

extension HistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if collectionView === videosView {
            guard let id = videosDataSource.itemIdentifier(for: indexPath) else { return }
            viewModel.selectVideo(id: id)
        } else {
            guard let rowID = dataSource.itemIdentifier(for: indexPath) else { return }
            viewModel.selectChat(id: rowID)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard collectionView === videosView else { return }
        autoplay.refresh()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard collectionView === videosView else { return }
        autoplay.refresh()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === videosView else { return }
        autoplay.refresh()
    }
}
