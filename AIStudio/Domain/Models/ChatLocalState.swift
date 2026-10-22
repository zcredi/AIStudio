/// Изменения чатов, которые API не хранит: закрепление, переименование и удаление живут на устройстве.
struct ChatLocalState: Codable, Equatable, Sendable {
    // MARK: - Types

    private enum CodingKeys: String, CodingKey {
        case pinnedChatIDs
        case deletedChatIDs
        case customTitles
    }

    // MARK: - Properties

    var pinnedChatIDs: Set<String>
    var deletedChatIDs: Set<String>
    /// Названия, которые пользователь дал чатам, по ID чата.
    var customTitles: [String: String]

    // MARK: - Init

    init(pinnedChatIDs: Set<String> = [], deletedChatIDs: Set<String> = [], customTitles: [String: String] = [:]) {
        self.pinnedChatIDs = pinnedChatIDs
        self.deletedChatIDs = deletedChatIDs
        self.customTitles = customTitles
    }

    /// В старых файлах нет полей, добавленных позже, поэтому каждое по умолчанию пустое.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pinnedChatIDs = try container.decodeIfPresent(Set<String>.self, forKey: .pinnedChatIDs) ?? []
        deletedChatIDs = try container.decodeIfPresent(Set<String>.self, forKey: .deletedChatIDs) ?? []
        customTitles = try container.decodeIfPresent([String: String].self, forKey: .customTitles) ?? [:]
    }
}
