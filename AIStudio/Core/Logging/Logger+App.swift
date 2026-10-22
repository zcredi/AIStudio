import Foundation
import OSLog

extension Logger {
    /// Logger в подсистеме приложения. Одна категория на тип.
    init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier ?? "AIStudio", category: category)
    }
}
