import Combine
import StoreKit
import UIKit

final class SettingsViewController: UIViewController {
    // MARK: - Types

    private enum Layout {
        static let contentInsets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let sectionSpacing: CGFloat = 28
        static let rowSpacing = Spacing.s
        static let sectionTitleBottomSpacing: CGFloat = 6
        static let sectionTitleAlpha: CGFloat = 0.3
        static let versionColor = Palette.textPrimary.withAlphaComponent(0.6)
    }

    // MARK: - Properties

    var onBack: (@MainActor () -> Void)?
    var onOpenPaywall: (@MainActor () -> Void)?
    /// У документов контактов, конфиденциальности и правил пока нет URL; что открыть, решает координатор.
    var onContactUs: (@MainActor () -> Void)?
    var onPrivacyPolicy: (@MainActor () -> Void)?
    var onUsagePolicy: (@MainActor () -> Void)?

    private let viewModel: SettingsViewModel
    private let headerView = NavigationHeaderView(title: String(localized: "Settings"))
    private let scrollView = UIScrollView()
    private let notificationsRow = SettingsRowView(title: String(localized: "Notifications"), symbolName: "bell", accessory: .toggle)
    private let clearCacheRow = SettingsRowView(title: String(localized: "Clear cache"), symbolName: "trash")
    private let restoreRow = SettingsRowView(
        title: String(localized: "Restore purchases"),
        symbolName: "arrow.trianglehead.clockwise.icloud",
        fallbackSymbolName: "arrow.clockwise.icloud"
    )
    private lazy var toastPresenter = ToastPresenter(containerView: view)
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(viewModel: SettingsViewModel) {
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
        viewModel.refresh()
    }

    // MARK: - Private

    private func setupViews() {
        view.backgroundColor = Palette.background
        headerView.onBack = { [weak self] in self?.onBack?() }

        let content = UIStackView(arrangedSubviews: [
            makeSection(title: String(localized: "Support us"), rows: supportRows()),
            makeSection(title: String(localized: "Purchases & Actions"), rows: purchaseRows()),
            makeSection(title: String(localized: "Info & legal"), rows: infoRows()),
            makeVersionLabel(),
        ])
        content.axis = .vertical
        content.spacing = Layout.sectionSpacing
        content.setCustomSpacing(0, after: content.arrangedSubviews[2])

        [headerView, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        scrollView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        let insets = Layout.contentInsets
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: insets.top),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -insets.bottom),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: insets.leading),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -insets.trailing),
        ])
    }

    private func supportRows() -> [SettingsRowView] {
        let rate = SettingsRowView(title: String(localized: "Rate app"), symbolName: "star")
        rate.addAction(UIAction { [weak self] _ in self?.viewModel.rateTapped() }, for: .touchUpInside)
        let share = SettingsRowView(title: String(localized: "Share with friends"), symbolName: "square.and.arrow.up")
        share.addAction(UIAction { [weak self] _ in self?.viewModel.shareTapped() }, for: .touchUpInside)
        return [rate, share]
    }

    private func purchaseRows() -> [SettingsRowView] {
        let upgrade = SettingsRowView(title: String(localized: "Upgrade plan"), symbolName: "sparkles")
        upgrade.addAction(UIAction { [weak self] _ in self?.viewModel.upgradeTapped() }, for: .touchUpInside)
        notificationsRow.onToggle = { [weak self] isOn in
            guard let self else { return }
            viewModel.setNotificationsEnabled(isOn)
            // Уведомления выключаются в приложении «Настройки», поэтому переключатель показывает реальное состояние.
            notificationsRow.setToggleOn(viewModel.state.areNotificationsOn, animated: true)
        }
        clearCacheRow.addAction(UIAction { [weak self] _ in self?.viewModel.clearCacheTapped() }, for: .touchUpInside)
        restoreRow.addAction(UIAction { [weak self] _ in self?.viewModel.restoreTapped() }, for: .touchUpInside)
        return [upgrade, notificationsRow, clearCacheRow, restoreRow]
    }

    private func infoRows() -> [SettingsRowView] {
        let contact = SettingsRowView(title: String(localized: "Contact us"), symbolName: "text.bubble")
        contact.addAction(UIAction { [weak self] _ in self?.onContactUs?() }, for: .touchUpInside)
        let privacy = SettingsRowView(title: String(localized: "Privacy Policy"), symbolName: "folder.badge.person.crop")
        privacy.addAction(UIAction { [weak self] _ in self?.onPrivacyPolicy?() }, for: .touchUpInside)
        let usage = SettingsRowView(title: String(localized: "Usage Policy"), symbolName: "text.document", fallbackSymbolName: "doc.text")
        usage.addAction(UIAction { [weak self] _ in self?.onUsagePolicy?() }, for: .touchUpInside)
        return [contact, privacy, usage]
    }

    private func makeSection(title: String, rows: [UIView]) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typography.semibold16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.sectionTitleAlpha)
        titleLabel.accessibilityTraits = .header

        let section = UIStackView(arrangedSubviews: [titleLabel] + rows)
        section.axis = .vertical
        section.spacing = Layout.rowSpacing
        section.setCustomSpacing(Layout.sectionTitleBottomSpacing + Layout.rowSpacing, after: titleLabel)
        return section
    }

    private func makeVersionLabel() -> UIView {
        let label = UILabel()
        label.text = String(localized: "App Version: \(viewModel.state.appVersion)")
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Layout.versionColor
        label.textAlignment = .center

        let container = UIView()
        container.addSubview(label)
        label.pinEdges(to: container, insets: NSDirectionalEdgeInsets(top: Spacing.l, leading: 0, bottom: Spacing.l, trailing: 0))
        return container
    }

    private func bind() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)

        // Пользователь мог изменить разрешение на уведомления в приложении «Настройки».
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.viewModel.refresh() }
            .store(in: &cancellables)
    }

    private func render(_ state: SettingsViewModel.State) {
        notificationsRow.setToggleOn(state.areNotificationsOn, animated: view.window != nil)
        clearCacheRow.detail = state.cacheSize
        restoreRow.isEnabled = !state.isRestoring
        UIView.animate(withDuration: Motion.fast, delay: 0, options: [.beginFromCurrentState]) {
            self.restoreRow.alpha = state.isRestoring ? 0.5 : 1
        }
    }

    private func handle(_ event: SettingsViewModel.Event) {
        switch event {
        case .openPaywall:
            onOpenPaywall?()
        case .requestReview:
            guard let scene = view.window?.windowScene else { return }
            AppStore.requestReview(in: scene)
        case .shareApp:
            let text = String(localized: "Try AI Studio: chat with AI and turn photos into videos.")
            present(UIActivityViewController(activityItems: [text], applicationActivities: nil), animated: true)
        case .openSystemSettings:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        case .showToast(.cacheCleared):
            toastPresenter.show(.success, message: String(localized: "Cache cleared"))
        case .showToast(.purchasesRestored):
            toastPresenter.show(.success, message: String(localized: "Purchases restored"))
        case .showError(let error):
            let alert = UIAlertController(title: String(localized: "Something went wrong"), message: error.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default))
            present(alert, animated: true)
        }
    }
}
