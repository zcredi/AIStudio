protocol VideoTemplateRepository: Sendable {
    /// Активные шаблоны в порядке каталога.
    func templates() async throws -> [VideoTemplate]
}
