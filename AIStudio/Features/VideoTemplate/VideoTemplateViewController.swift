import Combine
import PhotosUI
import UIKit

final class VideoTemplateViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let carouselTopInset = Spacing.l
        /// Карточки шириной 331 pt на экране 390 pt, поэтому соседние выглядывают с обеих сторон.
        static let cardWidthFraction: CGFloat = 331 / 390
        static let cardHeight: CGFloat = 311
        static let cardSpacing = Spacing.l
        static let sideInset = Spacing.l
        static let sectionSpacing = Spacing.xxl
        static let rowSpacing = Spacing.s
        static let buttonBottomInset = Spacing.l
        static let dropdownHiddenScale: CGFloat = 0.95
    }

    private enum Section {
        case main
    }

    private enum Menu {
        case format
        case quality
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    var onOpenGeneration: (@MainActor (VideoGeneration.ID) -> Void)?

    private let viewModel: VideoTemplateViewModel
    private let autoplay: AutoplayController
    private let headerView = NavigationHeaderView(title: "")
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private lazy var carouselView = UICollectionView(frame: .zero, collectionViewLayout: makeCarouselLayout())
    private lazy var carouselDataSource = makeCarouselDataSource()
    private let photoSlot = PhotoSlotView()
    private let formatRow = OptionRowView(title: String(localized: "Format"))
    private let qualityRow = OptionRowView(title: String(localized: "Quality"))
    private let createButton = PrimaryButton(title: String(localized: "Create"))
    private lazy var toastPresenter = ToastPresenter(containerView: view)
    private lazy var dismissMenuRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissMenuTapped))
    private var dropdown: OptionsDropdownView?
    private var openMenu: Menu?
    private var shownThumbnail: (data: Data, image: UIImage)?
    private var hasScrolledToInitialTemplate = false
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: VideoTemplateViewModel, autoplay: AutoplayController) {
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
        setupActions()
        applyTemplates()
        bind()
        autoplay.attach(to: carouselView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasScrolledToInitialTemplate, carouselView.bounds.width > 0 else { return }
        hasScrolledToInitialTemplate = true
        let indexPath = IndexPath(item: viewModel.state.currentIndex, section: 0)
        carouselView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoplay.resume()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoplay.suspend()
        closeMenu(animated: false)
    }

    // MARK: - API

    /// Шаблон, который сейчас на экране; карусель могла уйти от того, по которому тапнули.
    var currentTemplateID: VideoTemplate.ID {
        viewModel.state.template.id
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        carouselView.backgroundColor = .clear
        carouselView.delegate = self
        carouselView.alwaysBounceVertical = false
        createButton.isEnabled = false
        dismissMenuRecognizer.delegate = self
        dismissMenuRecognizer.isEnabled = false
        view.addGestureRecognizer(dismissMenuRecognizer)
    }

    private func setupLayout() {
        let rows = UIStackView(arrangedSubviews: [formatRow, qualityRow])
        rows.axis = .vertical
        rows.spacing = Layout.rowSpacing

        [carouselView, photoSlot, rows].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        scrollView.addSubview(contentView)
        [headerView, scrollView, createButton, contentView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            if $0 !== contentView { view.addSubview($0) }
        }

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -Layout.buttonBottomInset),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            carouselView.topAnchor.constraint(equalTo: contentView.topAnchor),
            carouselView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            carouselView.heightAnchor.constraint(equalToConstant: Layout.carouselTopInset + Layout.cardHeight),

            photoSlot.topAnchor.constraint(equalTo: carouselView.bottomAnchor, constant: Layout.sectionSpacing),
            photoSlot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.sideInset),

            rows.topAnchor.constraint(equalTo: photoSlot.bottomAnchor, constant: Layout.sectionSpacing),
            rows.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.sideInset),
            rows.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.sideInset),
            rows.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.buttonBottomInset),
        ])
    }

    private func setupActions() {
        headerView.onBack = { [weak self] in self?.onBack?() }
        photoSlot.onAdd = { [weak self] in self?.viewModel.addPhotoTapped() }
        photoSlot.onRemove = { [weak self] in self?.viewModel.removePhoto() }
        formatRow.addAction(UIAction { [weak self] _ in self?.toggleMenu(.format) }, for: .touchUpInside)
        qualityRow.addAction(UIAction { [weak self] _ in self?.toggleMenu(.quality) }, for: .touchUpInside)
        createButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self?.viewModel.createTapped()
        }, for: .touchUpInside)
    }

    private func makeCarouselLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(Layout.cardWidthFraction),
                heightDimension: .absolute(Layout.cardHeight)
            ),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = Layout.cardSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: Layout.carouselTopInset, leading: 0, bottom: 0, trailing: 0)
        section.visibleItemsInvalidationHandler = { [weak self] items, offset, environment in
            let center = offset.x + environment.container.contentSize.width / 2
            let centered = items.min { abs($0.frame.midX - center) < abs($1.frame.midX - center) }
            let index = centered?.indexPath.item
            // Раскладка вызывает это на главном потоке, пока карусель прокручивается.
            MainActor.assumeIsolated {
                self?.carouselDidScroll(centeredIndex: index)
            }
        }
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func makeCarouselDataSource() -> UICollectionViewDiffableDataSource<Section, VideoTemplate.ID> {
        let templates = Dictionary(viewModel.state.templates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let registration = UICollectionView.CellRegistration<TemplatePreviewCell, VideoTemplate.ID> { cell, _, id in
            guard let template = templates[id] else { return }
            cell.configure(with: template)
        }
        return UICollectionViewDiffableDataSource(collectionView: carouselView) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
        }
    }

    private func applyTemplates() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, VideoTemplate.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.state.templates.map(\.id))
        carouselDataSource.apply(snapshot, animatingDifferences: false)
    }

    private func carouselDidScroll(centeredIndex: Int?) {
        autoplay.refresh()
        // Первые вызовы приходят раньше, чем карусель доедет до шаблона, по которому тапнули.
        guard hasScrolledToInitialTemplate, let centeredIndex else { return }
        viewModel.selectTemplate(at: centeredIndex)
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

    private func render(_ state: VideoTemplateViewModel.State) {
        headerView.title = state.template.name
        photoSlot.render(slotContent(for: state.photo))
        formatRow.value = state.format.rawValue
        qualityRow.value = state.quality.rawValue
        createButton.isEnabled = state.canCreate
        createButton.isLoading = state.isStarting
    }

    private func slotContent(for photo: VideoTemplateViewModel.PhotoState) -> PhotoSlotView.Content {
        switch photo {
        case .empty:
            return .empty
        case .loading:
            return .loading
        case .loaded(let thumbnailData):
            // Миниатюра весит несколько килобайт; декодируем её один раз, а не на каждый render.
            if let shownThumbnail, shownThumbnail.data == thumbnailData {
                return .photo(shownThumbnail.image)
            }
            guard let image = UIImage(data: thumbnailData) else { return .empty }
            shownThumbnail = (thumbnailData, image)
            return .photo(image)
        }
    }

    private func handle(_ event: VideoTemplateViewModel.Event) {
        switch event {
        case .showPhotoPicker:
            present(PHPickerViewController.makeSingleImagePicker(delegate: self), animated: true)
        case .showPhotoAccessDenied:
            present(UIAlertController.makePhotoAccessAlert(), animated: true)
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


    // MARK: - Menus

    private func toggleMenu(_ menu: Menu) {
        let wasOpen = openMenu == menu
        closeMenu(animated: true)
        guard !wasOpen else { return }
        showMenu(menu)
    }

    private func showMenu(_ menu: Menu) {
        let dropdown = OptionsDropdownView(options: options(for: menu))
        dropdown.onSelect = { [weak self] index in self?.select(index, in: menu) }
        dropdown.onDismiss = { [weak self] in self?.closeMenu(animated: true) }
        let row = menu == .format ? formatRow : qualityRow
        dropdown.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dropdown)
        NSLayoutConstraint.activate([
            dropdown.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            dropdown.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        self.dropdown = dropdown
        openMenu = menu
        dismissMenuRecognizer.isEnabled = true
        // На маленьких экранах строка может оказаться ниже видимой области; список открывается от неё вверх, поэтому
        // прокручиваем его в поле зрения целиком.
        contentView.layoutIfNeeded()
        scrollView.scrollRectToVisible(dropdown.frame, animated: true)

        dropdown.alpha = 0
        if !UIAccessibility.isReduceMotionEnabled {
            dropdown.transform = CGAffineTransform(scaleX: Layout.dropdownHiddenScale, y: Layout.dropdownHiddenScale)
        }
        UIView.animate(withDuration: Motion.fast) {
            dropdown.alpha = 1
            dropdown.transform = .identity
        }
        UIAccessibility.post(notification: .screenChanged, argument: dropdown)
    }

    private func closeMenu(animated: Bool) {
        guard let dropdown else { return }
        self.dropdown = nil
        openMenu = nil
        dismissMenuRecognizer.isEnabled = false
        UIView.animate(withDuration: animated ? Motion.fast : 0) {
            dropdown.alpha = 0
        } completion: { _ in
            dropdown.removeFromSuperview()
        }
    }

    private func options(for menu: Menu) -> [OptionsDropdownView.Option] {
        let state = viewModel.state
        switch menu {
        case .format:
            return VideoFormat.allCases.map { format in
                OptionsDropdownView.Option(
                    title: format.rawValue,
                    subtitle: format.subtitle,
                    symbolName: format.symbolName,
                    isSelected: format == state.format
                )
            }
        case .quality:
            return state.template.qualities.map { quality in
                OptionsDropdownView.Option(
                    title: quality.rawValue,
                    subtitle: quality.subtitle(among: state.template.qualities),
                    symbolName: nil,
                    isSelected: quality == state.quality
                )
            }
        }
    }

    private func select(_ index: Int, in menu: Menu) {
        switch menu {
        case .format:
            let formats = VideoFormat.allCases
            if formats.indices.contains(index) {
                viewModel.selectFormat(formats[index])
            }
        case .quality:
            let qualities = viewModel.state.template.qualities
            if qualities.indices.contains(index) {
                viewModel.selectQuality(qualities[index])
            }
        }
        closeMenu(animated: true)
    }

    @objc private func dismissMenuTapped() {
        closeMenu(animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension VideoTemplateViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        autoplay.refresh()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        autoplay.refresh()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension VideoTemplateViewController: UIGestureRecognizerDelegate {
    /// Тапы внутри открытого списка достаются его строкам; любой другой тап закрывает список.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let dropdown else { return false }
        return !dropdown.bounds.contains(touch.location(in: dropdown))
    }
}

// MARK: - PHPickerViewControllerDelegate

extension VideoTemplateViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        // Cancel не возвращает результатов, и слот остаётся как был.
        guard let provider = results.first?.itemProvider else { return }
        viewModel.loadPhoto { try await PhotoLoader.load(from: provider) }
    }
}

// MARK: - Presentation

private extension VideoFormat {
    var subtitle: String {
        switch self {
        case .landscape: String(localized: "Landscape")
        case .portrait: String(localized: "Portrait · Stories")
        case .square: String(localized: "Square")
        }
    }

    var symbolName: String {
        switch self {
        case .landscape: "rectangle"
        case .portrait: "rectangle.portrait"
        case .square: "square"
        }
    }
}

private extension VideoQuality {
    /// В макете подписаны рекомендуемое качество, лучшее и более быстрые.
    func subtitle(among qualities: [VideoQuality]) -> String {
        if self == .recommended {
            return String(localized: "Recommended")
        }
        if self == qualities.max() {
            return String(localized: "Best quality")
        }
        return String(localized: "Faster generation")
    }
}
