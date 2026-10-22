import Foundation

/// Composition root: создаёт долгоживущие сервисы. Экраны получают их протоколами через `init`.
@MainActor
final class AppContainer {
    // MARK: - Types

    private enum Media {
        /// Сетка в две колонки показывает до шести карточек одновременно.
        static let gridPlayers = 6
        /// Играет одна карточка по центру; второй плеер нужен на время свайпа к соседней.
        static let carouselPlayers = 2
        /// Стартовые кадры сетки истории, которые держим декодированными при прокрутке туда и обратно.
        static let thumbnailCacheLimit = 60
    }

    // MARK: - Properties

    var premiumStatus: any PremiumStatusProviding {
        subscriptionService
    }

    let onboardingProgress: any OnboardingProgressStoring = UserDefaultsOnboardingProgressStore()
    /// `AppCoordinator` подсказывает ему, как показать пейвол.
    let premiumGate: PremiumGate

    private let subscriptionService: ApphudSubscriptionService
    private let chatRepository: any ChatRepository
    private let videoTemplateRepository: any VideoTemplateRepository
    private let videoGenerationCenter: VideoGenerationCenter
    private let chatLocalStateRepository: any ChatLocalStateRepository = FileChatLocalStateRepository(
        store: CodableFileStore(fileName: "chat-local-state.json")
    )
    private let textCopier: any TextCopying = PasteboardTextCopier()
    private let videoCache = VideoCache()

    // MARK: - Init

    init(configuration: AppConfiguration = AppConfiguration()) {
        let subscriptionService = ApphudSubscriptionService(
            apiKey: configuration.apphudAPIKey,
            paywallIdentifier: configuration.paywallIdentifier,
            fallbackProductIDs: configuration.fallbackProductIDs
        )
        let interceptors: [any RequestInterceptor] = [
            BearerTokenInterceptor(token: configuration.apiToken),
            ClientIdentityInterceptor(appID: configuration.apiAppID) { await subscriptionService.userID },
        ]

        let pixverseRepository = PixVerseVideoRepository(
            client: URLSessionAPIClient(server: configuration.pixverseServer, interceptors: interceptors),
            appID: configuration.apiAppID
        )

        self.subscriptionService = subscriptionService
        chatRepository = DolaChatRepository(
            client: URLSessionAPIClient(server: configuration.dolaServer, interceptors: interceptors)
        )
        videoTemplateRepository = CachedVideoTemplateRepository(repository: pixverseRepository)
        videoGenerationCenter = VideoGenerationCenter(
            repository: pixverseRepository,
            library: FileVideoLibraryRepository(store: CodableFileStore(fileName: "video-generations.json"))
        )
        premiumGate = PremiumGate(premiumStatus: subscriptionService)
    }

    // MARK: - API

    /// Запускает SDK, которые должны стартовать раньше, чем первый экран обратится к API.
    func start() {
        subscriptionService.start()
        videoGenerationCenter.start()
    }

    func makeSplashViewController() -> SplashViewController {
        SplashViewController(viewModel: SplashViewModel(premiumStatus: subscriptionService))
    }

    func makeOnboardingViewController() -> OnboardingViewController {
        OnboardingViewController(viewModel: OnboardingViewModel(progressStore: onboardingProgress))
    }

    func makeMainViewController() -> MainViewController {
        MainViewController(viewModel: MainViewModel(premiumStatus: subscriptionService))
    }

    /// `chat` равен `nil` для нового диалога.
    func makeChatViewController(chat: Chat?) -> ChatViewController {
        let viewModel = ChatViewModel(
            chat: chat,
            chatRepository: chatRepository,
            localStateRepository: chatLocalStateRepository,
            premiumGate: premiumGate,
            textCopier: textCopier
        )
        return ChatViewController(viewModel: viewModel, shouldFocusInput: chat == nil)
    }

    func makeHistoryViewController() -> HistoryViewController {
        let viewModel = HistoryViewModel(
            chatRepository: chatRepository,
            localStateRepository: chatLocalStateRepository,
            generator: videoGenerationCenter,
            premiumGate: premiumGate
        )
        return HistoryViewController(
            viewModel: viewModel,
            autoplay: AutoplayController(maxPlayers: Media.gridPlayers, cache: videoCache),
            thumbnails: ThumbnailLoader(countLimit: Media.thumbnailCacheLimit)
        )
    }

    func makeSettingsViewController() -> SettingsViewController {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        return SettingsViewController(viewModel: SettingsViewModel(
            subscriptionService: subscriptionService,
            cache: FileCacheStorage(),
            notifications: UserNotificationPermissionProvider(),
            appVersion: appVersion
        ))
    }

    func makeVideoTemplatesViewController() -> VideoTemplatesViewController {
        VideoTemplatesViewController(
            viewModel: VideoTemplatesViewModel(repository: videoTemplateRepository),
            autoplay: AutoplayController(maxPlayers: Media.gridPlayers, cache: videoCache)
        )
    }

    func makeVideoTemplateViewController(template: VideoTemplate, templates: [VideoTemplate]) -> VideoTemplateViewController {
        let viewModel = VideoTemplateViewModel(
            template: template,
            templates: templates,
            generator: videoGenerationCenter,
            premiumGate: premiumGate,
            photoAccess: PhotoLibraryAccessProvider()
        )
        return VideoTemplateViewController(
            viewModel: viewModel,
            autoplay: AutoplayController(maxPlayers: Media.carouselPlayers, cache: videoCache)
        )
    }

    func makeGeneratingViewController(generationID: VideoGeneration.ID) -> GeneratingViewController {
        GeneratingViewController(viewModel: GeneratingViewModel(
            generationID: generationID,
            generator: videoGenerationCenter,
            premiumGate: premiumGate
        ))
    }

    func makeVideoResultViewController(generation: VideoGeneration) -> VideoResultViewController {
        VideoResultViewController(viewModel: VideoResultViewModel(
            generation: generation,
            generator: videoGenerationCenter,
            saver: PhotoLibraryVideoSaver(),
            premiumGate: premiumGate,
            photoAccess: PhotoLibraryAccessProvider()
        ))
    }

    func makePaywallViewController() -> PaywallViewController {
        PaywallViewController(viewModel: PaywallViewModel(subscriptionService: subscriptionService))
    }
}
