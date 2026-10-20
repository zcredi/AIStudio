import UIKit

/// Edge anchors shared by `UIView` and `UILayoutGuide`.
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
    /// Pins all four edges to a view or a layout guide. The receiver must already be in the hierarchy.
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
