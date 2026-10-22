@testable import AIStudio

@MainActor
final class FakeOnboardingProgressStore: OnboardingProgressStoring {
    var isOnboardingCompleted = false
}
