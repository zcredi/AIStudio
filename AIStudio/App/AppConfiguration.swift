import Foundation
import OSLog

/// Настройки, известные на этапе сборки. Ключи приходят из `Secrets.xcconfig` через Info.plist.
struct AppConfiguration: Sendable {
    // MARK: - Types

    private enum InfoKey: String {
        case apiToken = "APIToken"
        case apphudAPIKey = "ApphudAPIKey"
    }

    // MARK: - Properties

    /// Пути Dola в спеке уже начинаются с `/dola`, поэтому базовый путь — корень хоста.
    let dolaServer = APIServer(host: "nebulaapps.site", basePath: "")
    let pixverseServer = APIServer(host: "nebulaapps.site", basePath: "/pixverse")
    /// `app_id`, под которым приложение известно API. Это не bundle identifier.
    let apiAppID = "com.test.test"
    /// Идентификатор пейвола из дашборда Apphud.
    let paywallIdentifier = "main"
    let apiToken: String
    let apphudAPIKey: String

    // MARK: - Init

    init(bundle: Bundle = .main) {
        apiToken = Self.value(for: .apiToken, in: bundle)
        apphudAPIKey = Self.value(for: .apphudAPIKey, in: bundle)
    }

    // MARK: - Private

    private static let logger = Logger(category: "AppConfiguration")

    /// Отсутствующий ключ — ошибка настройки, а не повод падать: запросы просто будут явно отклоняться.
    private static func value(for key: InfoKey, in bundle: Bundle) -> String {
        let value = bundle.object(forInfoDictionaryKey: key.rawValue) as? String ?? ""
        if value.isEmpty {
            logger.fault("\(key.rawValue, privacy: .public) is empty, add it to Secrets.xcconfig")
        }
        return value
    }
}
