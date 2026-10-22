import Foundation

enum OnboardingPage: CaseIterable, Sendable {
    case chat
    case video

    var title: String {
        switch self {
        case .chat:
            String(localized: "Ask AI anything")
        case .video:
            String(localized: "Turn photos into videos")
        }
    }

    var subtitle: String {
        switch self {
        case .chat:
            String(localized: "Answers, emails, ideas and plans in seconds")
        case .video:
            String(localized: "Pick a template — AI animates your photo")
        }
    }
}
