import Foundation

struct Chat: Identifiable, Equatable, Sendable {
    let id: String
    let title: String?
    let updatedAt: Date
    let lastMessagePreview: String?
}
