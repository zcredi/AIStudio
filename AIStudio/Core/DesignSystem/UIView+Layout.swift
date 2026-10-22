import UIKit

/// Якоря краёв, общие для `UIView` и `UILayoutGuide`.
@MainActor
protocol EdgeAnchorProviding {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: EdgeAnchorProviding {}

extension UILayoutGuide: EdgeAnchorProviding {}

extension UIView {
    /// Прижимает все четыре края к виду или layout guide. Получатель уже должен быть в иерархии.
    func pinEdges(to target: some EdgeAnchorProviding, insets: NSDirectionalEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -insets.trailing),
            topAnchor.constraint(equalTo: target.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
