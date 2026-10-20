import Foundation
import OSLog

extension Logger {
    /// Logger in the app's subsystem. Use one category per type.
    init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier ?? "AIStudio", category: category)
    }
}
