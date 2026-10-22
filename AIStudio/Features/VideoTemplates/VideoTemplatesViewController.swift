import Combine
import UIKit

final class VideoTemplatesViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let chipsTopInset = Spacing.xxl
        static let chipHeight: CGFloat = 33
        static let chipSpacing = Spacing.m
        static let sideInset = Spacing.l
        static let gridInsets = NSDirectionalEdgeInsets(top: Spacing.xxl, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let gridSpacing = Spacing.l
        static let cardHeight: CGFloat = 232
    }

    private enum Section {
        case main
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    /// `templates` — шаблоны выбранной категории; `index` — тот, по которому тапнули.
    var onOpenTemplate: (@MainActor (_ templates: [VideoTemplate], _ index: Int) -> Void)?

    private let viewModel: VideoTemplatesViewModel
    private let autoplay: AutoplayController
    private let headerView = VideoTemplatesHeaderView()
    private let contentView = UIView()
    private lazy var chipsView = UICollectionView(frame: .zero, collectionViewLayout: makeChipsLayout())
    private lazy var gridView = UICollectionView(frame: .zero, collectionViewLayout: makeGridLayout())
    private lazy var chipsDataSource = makeChipsDataSource()
    private lazy var gridDataSource = makeGridDataSource()
    private let skeletonView = VideoTemplatesSkeletonView()
    private let errorView = ErrorStateView()
    private let emptyView = EmptyStateView(
        icon: UIImage(resource: .imageToImageIcon),
        title: String(localized: "No templates yet"),
        subtitle: String(localized: "New effects are on the way. Check back soon")
    )
    private var chipsHeightConstraint: NSLayoutConstraint?
    private var templatesByID: [VideoTemplate.ID: VideoTemplate] = [:]
    private var shownCategory: String?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: VideoTemplatesViewModel, autoplay: AutoplayController) {
        self.viewModel = viewModel
        self.autoplay = autoplay
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
        autoplay.attach(to: gridView)
        viewModel.load()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Чипы растут с Dynamic Type, поэтому растёт и строка.
        chipsHeightConstraint?.constant = UIFontMetrics.default.scaledValue(for: Layout.chipHeight, compatibleWith: traitCollection)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoplay.resume()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoplay.suspend()
    }

    // MARK: - API

    /// Карточка, из которой экран шаблона раскрывается zoom-переходом и в которую возвращается. Докручивает её
    /// в видимую область, если пользователь пролистал к шаблону, чья карточка за пределами экрана.
    func cardView(for id: VideoTemplate.ID) -> UIView? {
        guard let indexPath = gridDataSource.indexPath(for: id) else { return nil }
        if gridView.cellForItem(at: indexPath) == nil {
            gridView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            gridView.layoutIfNeeded()
        }
        return gridView.cellForItem(at: indexPath)
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        headerView.onBack = { [weak self] in self?.onBack?() }
        errorView.onRetry = { [weak self] in self?.viewModel.load() }

        [chipsView, gridView].forEach {
            $0.backgroundColor = .clear
            $0.delegate = self
        }
        chipsView.showsHorizontalScrollIndicator = false
        chipsView.alwaysBounceVertical = false
        chipsView.accessibilityTraits = .tabBar
        gridView.showsVerticalScrollIndicator = false
        // Обращение к data source здесь создаёт их до первого снапшота.
        _ = chipsDataSource
        _ = gridDataSource
    }

    private func setupLayout() {
        [chipsView, gridView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        [contentView, skeletonView, errorView, emptyView, headerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.alpha = $0 === headerView ? 1 : 0
            view.addSubview($0)
        }

        let chipsHeight = chipsView.heightAnchor.constraint(equalToConstant: Layout.chipHeight)
        chipsHeightConstraint = chipsHeight
        var constraints = [
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            chipsView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.chipsTopInset),
            chipsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chipsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chipsHeight,

            gridView.topAnchor.constraint(equalTo: chipsView.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ]
        for stateView in [contentView, skeletonView, errorView, emptyView] {
            constraints += [
                stateView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
                stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func makeChipsLayout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(widthDimension: .estimated(Layout.chipHeight * 2), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Layout.chipSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Layout.sideInset, bottom: 0, trailing: Layout.sideInset)

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }

    private func makeGridLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Layout.cardHeight)),
            subitems: [item, item]
        )
        group.interItemSpacing = .fixed(Layout.gridSpacing)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Layout.gridSpacing
        section.contentInsets = Layout.gridInsets
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func makeChipsDataSource() -> UICollectionViewDiffableDataSource<Section, String> {
        let registration = UICollectionView.CellRegistration<CategoryChipCell, String> { cell, _, category in
            cell.configure(with: category)
        }
        return UICollectionViewDiffableDataSource(collectionView: chipsView) { collectionView, indexPath, category in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: category)
        }
    }

    private func makeGridDataSource() -> UICollectionViewDiffableDataSource<Section, VideoTemplate.ID> {
        let registration = UICollectionView.CellRegistration<TemplateCardCell, VideoTemplate.ID> { [weak self] cell, _, id in
            guard let template = self?.templatesByID[id] else { return }
            cell.configure(with: template)
        }
        return UICollectionViewDiffableDataSource(collectionView: gridView) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
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

    private func render(_ state: VideoTemplatesViewModel.State) {
        if case .failed(let error) = state.templates {
            errorView.message = error.message
        }
        if state.templates.value != nil {
            applyCategories(state.categories, selected: state.selectedCategory)
            applyTemplates(state.visibleTemplates, category: state.selectedCategory)
        }
        show(visibleView(for: state))
    }

    private func visibleView(for state: VideoTemplatesViewModel.State) -> UIView {
        switch state.templates {
        case .loading:
            skeletonView
        case .failed:
            errorView
        case .loaded(let templates):
            templates.isEmpty ? emptyView : contentView
        }
    }

    private func applyCategories(_ categories: [String], selected: String?) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(categories)
        chipsDataSource.apply(snapshot, animatingDifferences: false)

        guard let selected, let indexPath = chipsDataSource.indexPath(for: selected) else { return }
        chipsView.selectItem(at: indexPath, animated: false, scrollPosition: [])
    }

    private func applyTemplates(_ templates: [VideoTemplate], category: String?) {
        templatesByID = Dictionary(templates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var snapshot = NSDiffableDataSourceSnapshot<Section, VideoTemplate.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(templates.map(\.id))

        let isNewCategory = category != shownCategory
        shownCategory = category
        guard isNewCategory, view.window != nil else {
            gridDataSource.apply(snapshot, animatingDifferences: view.window != nil) { [weak self] in
                self?.autoplay.refresh()
            }
            return
        }
        // Другая категория — это другой набор карточек: плавно проявляем его с начала списка.
        UIView.transition(with: gridView, duration: Motion.standard, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.gridView.setContentOffset(CGPoint(x: 0, y: -self.gridView.adjustedContentInset.top), animated: false)
            self.gridDataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
                self?.autoplay.refresh()
            }
        }
    }

    /// Кроссфейд между контентом, skeleton, ошибкой и пустым состоянием.
    private func show(_ visibleView: UIView) {
        let views = [contentView, skeletonView, errorView, emptyView]
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            views.forEach { $0.alpha = $0 === visibleView ? 1 : 0 }
        }
        views.forEach {
            $0.isUserInteractionEnabled = $0 === visibleView
            $0.accessibilityElementsHidden = $0 !== visibleView
        }
    }

    private func handle(_ event: VideoTemplatesViewModel.Event) {
        switch event {
        case .openTemplate(let templates, let index):
            onOpenTemplate?(templates, index)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension VideoTemplatesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === chipsView {
            guard let category = chipsDataSource.itemIdentifier(for: indexPath) else { return }
            chipsView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            viewModel.selectCategory(category)
        } else {
            collectionView.deselectItem(at: indexPath, animated: false)
            guard let id = gridDataSource.itemIdentifier(for: indexPath) else { return }
            viewModel.selectTemplate(id: id)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard collectionView === gridView else { return }
        autoplay.refresh()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard collectionView === gridView else { return }
        autoplay.refresh()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === gridView else { return }
        autoplay.refresh()
    }
}
