import UIKit

extension UIAlertController {
    /// Показывается, если доступ к «Фото» уже запрещён и выдать его можно только в Настройках.
    static func makePhotoAccessAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: String(localized: "Allow access to Photos"),
            message: String(localized: "Turn on Photos access for AI Studio in Settings."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Open Settings"), style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        return alert
    }
}
