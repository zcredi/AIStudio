@testable import AIStudio

@MainActor
final class FakeTextCopier: TextCopying {
    var isAvailable = true
    private(set) var copiedTexts: [String] = []

    func copy(_ text: String) -> Bool {
        guard isAvailable else { return false }
        copiedTexts.append(text)
        return true
    }
}
