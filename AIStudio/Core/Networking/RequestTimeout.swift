import Foundation

enum RequestTimeout {
    static let standard: TimeInterval = 30
    /// AI operations keep the connection open until the model answers.
    static let generation: TimeInterval = 120
}
