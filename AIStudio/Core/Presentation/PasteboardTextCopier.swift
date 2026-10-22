import UIKit

@MainActor
final class PasteboardTextCopier: TextCopying {
    // MARK: - Properties

    private let pasteboard: UIPasteboard

    // MARK: - Init

    init(pasteboard: UIPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    // MARK: - TextCopying

    func copy(_ text: String) -> Bool {
        pasteboard.string = text
        // На управляемых устройствах буфер обмена может молча блокироваться, поэтому проверяем, что текст дошёл.
        return pasteboard.hasStrings
    }
}
