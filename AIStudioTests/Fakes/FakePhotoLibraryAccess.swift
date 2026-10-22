@testable import AIStudio

final class FakePhotoLibraryAccess: PhotoLibraryAccessProviding {
    private let current: PhotoLibraryAccess
    private let answer: PhotoLibraryAccess

    /// `answer` — то, что пользователь выберет в системном запросе.
    init(current: PhotoLibraryAccess, answer: PhotoLibraryAccess = .granted) {
        self.current = current
        self.answer = answer
    }

    func currentAccess() -> PhotoLibraryAccess {
        current
    }

    func requestAccess() async -> PhotoLibraryAccess {
        current == .notDetermined ? answer : current
    }
}
