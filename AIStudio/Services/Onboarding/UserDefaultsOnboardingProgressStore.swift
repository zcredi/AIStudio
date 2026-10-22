import Foundation

@MainActor
final class UserDefaultsOnboardingProgressStore: OnboardingProgressStoring {
    // MARK: - Types

    private enum Key {
        static let isOnboardingCompleted = "onboarding.isCompleted"
    }

    // MARK: - Properties

    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Key.isOnboardingCompleted) }
        set { defaults.set(newValue, forKey: Key.isOnboardingCompleted) }
    }

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}
