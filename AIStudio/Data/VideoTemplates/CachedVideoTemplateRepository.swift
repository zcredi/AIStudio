/// Хранит каталог до конца сессии, чтобы при повторном входе генератор показывал его сразу.
/// За сессию каталог почти не меняется; неудачная загрузка не кэшируется и повторяется.
actor CachedVideoTemplateRepository: VideoTemplateRepository {
    // MARK: - Properties

    private let repository: any VideoTemplateRepository
    private var cachedTemplates: [VideoTemplate]?

    // MARK: - Init

    init(repository: any VideoTemplateRepository) {
        self.repository = repository
    }

    // MARK: - VideoTemplateRepository

    func templates() async throws -> [VideoTemplate] {
        if let cachedTemplates {
            return cachedTemplates
        }
        let templates = try await repository.templates()
        cachedTemplates = templates
        return templates
    }
}
