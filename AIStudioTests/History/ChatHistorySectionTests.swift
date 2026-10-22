import XCTest
@testable import AIStudio

final class ChatHistorySectionTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    /// 2026-03-26 12:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_774_526_400)

    func test_sections_groupPinnedTodayYesterdayAndOlderDays() {
        // Дано
        let chats = [
            chat("today", hoursAgo: 1),
            chat("pinned", hoursAgo: 72),
            chat("yesterday", hoursAgo: 24),
            chat("older", hoursAgo: 22 * 24),
        ]
        let localState = ChatLocalState(pinnedChatIDs: ["pinned"])

        // Когда
        let sections = ChatHistorySection.sections(for: chats, localState: localState, now: now, calendar: calendar)

        // Тогда
        XCTAssertEqual(sections.map(\.title), ["Pinned", "Today", "Yesterday", "March 4"])
        XCTAssertEqual(sections.map { $0.rows.map(\.id) }, [["pinned"], ["today"], ["yesterday"], ["older"]])
    }

    func test_sections_hideDeletedChats() {
        let chats = [chat("kept", hoursAgo: 1), chat("deleted", hoursAgo: 2)]

        let sections = ChatHistorySection.sections(
            for: chats,
            localState: ChatLocalState(deletedChatIDs: ["deleted"]),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(sections.flatMap(\.rows).map(\.id), ["kept"])
    }

    func test_sections_useCustomTitleOverServerTitle() {
        let sections = ChatHistorySection.sections(
            for: [chat("renamed", hoursAgo: 1)],
            localState: ChatLocalState(customTitles: ["renamed": "Welcome email"]),
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(sections.first?.rows.first?.title, "Welcome email")
    }

    func test_sections_sortNewestFirstWithinDay() {
        let chats = [chat("earlier", hoursAgo: 3), chat("later", hoursAgo: 1)]

        let sections = ChatHistorySection.sections(for: chats, localState: ChatLocalState(), now: now, calendar: calendar)

        XCTAssertEqual(sections.first?.rows.map(\.id), ["later", "earlier"])
    }

    // MARK: - Private

    private func chat(_ id: String, hoursAgo: Double) -> Chat {
        Chat(id: id, title: "Chat \(id)", updatedAt: now.addingTimeInterval(-hoursAgo * 3600), lastMessagePreview: nil)
    }
}
