import UIKit

extension UIImage {
    /// SF Symbol, залитый фирменным градиентом: так в макетах нарисованы иконки и шевроны настроек.
    /// `fallbackName` подменяет символы, которых нет на старых системах.
    static func gradientSymbol(named name: String, fallbackName: String? = nil, configuration: SymbolConfiguration) -> UIImage? {
        let symbol = UIImage(systemName: name, withConfiguration: configuration)
            ?? fallbackName.flatMap { UIImage(systemName: $0, withConfiguration: configuration) }
        guard let symbol else { return nil }

        let rect = CGRect(origin: .zero, size: symbol.size)
        let image = UIGraphicsImageRenderer(size: symbol.size).image { context in
            symbol.withTintColor(.black, renderingMode: .alwaysOriginal).draw(in: rect)
            context.cgContext.setBlendMode(.sourceIn)
            let colors = [Palette.gradientStart.cgColor, Palette.gradientEnd.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: 0), end: CGPoint(x: rect.maxX, y: 0), options: [])
        }
        // Сохраняет базовую линию символа, чтобы он стоял в строке с текстом, как исходный глиф.
        return image.withBaselineOffset(fromBottom: symbol.baselineOffsetFromBottom ?? 0)
    }
}
