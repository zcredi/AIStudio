@MainActor
protocol OnboardingProgressStoring: AnyObject {
    var isOnboardingCompleted: Bool { get set }
}
