import Foundation

/// Группа чатов в истории с заголовком: «Pinned», «Today», «Yesterday» или день, например «March 4».
struct ChatHistorySection: Identifiable, Equatable, Sendable {
    struct Row: Identifiable, Equatable, Sendable {
        let id: Chat.ID
        let title: String
        let preview: String?
        let isPinned: Bool
    }

    let id: String
    let title: String
    let rows: [Row]
}

// MARK: - Building

extension ChatHistorySection {
    /// Сначала закреплённые чаты; остальные сгруппированы по дню последнего обновления, от новых к старым.
    static func sections(
        for chats: [Chat],
        localState: ChatLocalState,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ChatHistorySection] {
        let visibleChats = chats
            .filter { !localState.deletedChatIDs.contains($0.id) }
            .sorted { $0.updatedAt > $1.updatedAt }
        let pinned = visibleChats.filter { localState.pinnedChatIDs.contains($0.id) }
        let others = visibleChats.filter { !localState.pinnedChatIDs.contains($0.id) }

        var sections: [ChatHistorySection] = []
        if !pinned.isEmpty {
            let rows = pinned.map { Row($0, localState: localState, isPinned: true) }
            sections.append(ChatHistorySection(id: "pinned", title: String(localized: "Pinned"), rows: rows))
        }
        let days = Dictionary(grouping: others) { calendar.startOfDay(for: $0.updatedAt) }
        for day in days.keys.sorted(by: >) {
            let rows = (days[day] ?? []).map { Row($0, localState: localState, isPinned: false) }
            sections.append(ChatHistorySection(id: day.ISO8601Format(), title: title(for: day, now: now, calendar: calendar), rows: rows))
        }
        return sections
    }

    private static func title(for day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return String(localized: "Today")
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(day, inSameDayAs: yesterday) {
            return String(localized: "Yesterday")
        }
        let isThisYear = calendar.isDate(day, equalTo: now, toGranularity: .year)
        let style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
        let format = isThisYear ? style.month(.wide).day() : style.month(.wide).day().year()
        return day.formatted(format)
    }
}

// MARK: - Mapping

private extension ChatHistorySection.Row {
    init(_ chat: Chat, localState: ChatLocalState, isPinned: Bool) {
        self.init(
            id: chat.id,
            title: localState.customTitles[chat.id] ?? chat.title ?? String(localized: "New chat"),
            preview: chat.lastMessagePreview,
            isPinned: isPinned
        )
    }
}
