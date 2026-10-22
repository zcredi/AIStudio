#if DEBUG
import Foundation

/// Открывает экран сразу после запуска для проверки UI, например `-startScreen paywall`.
enum DebugStartScreen: String {
    case onboarding
    case paywall
    case main
    case chat
    case history
    case settings
    case videoTemplates

    private static let launchArgumentKey = "startScreen"

    /// Аргументы запуска вида `-key value` попадают в argument domain `UserDefaults`.
    static var current: DebugStartScreen? {
        UserDefaults.standard.string(forKey: launchArgumentKey).flatMap(DebugStartScreen.init(rawValue:))
    }
}
#endif
