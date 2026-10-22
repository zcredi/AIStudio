import UIKit

/// Оформляет Markdown ассистента так, как ответы выглядят в макете: градиентные заголовки,
/// жирный, курсив, inline-код, ссылки и маркированные или нумерованные списки.
@MainActor
final class MarkdownRenderer {
    // MARK: - Types

    private enum Style {
        static let bodyColor = Palette.textPrimary.withAlphaComponent(0.8)
        static let emphasisColor = Palette.textPrimary
        static let listIndent: CGFloat = 20
        static let italicObliqueness: CGFloat = 0.2
        /// Ширина текста ответа в макете; на неё растягивается градиент заголовков.
        static let gradientWidth: CGFloat = 302
        static let bullet = "•"
    }

    // MARK: - Properties

    private let cache = NSCache<NSString, NSAttributedString>()
    private lazy var headingColor = Self.makeGradientColor()

    // MARK: - API

    /// Результаты кэшируются по `cacheKey`, чтобы переиспользуемые ячейки не разбирали тот же ответ заново.
    func render(_ markdown: String, cacheKey: String) -> NSAttributedString {
        if let cached = cache.object(forKey: cacheKey as NSString) {
            return cached
        }
        let rendered = renderDocument(markdown)
        cache.setObject(rendered, forKey: cacheKey as NSString)
        return rendered
    }

    // MARK: - Private

    private func renderDocument(_ markdown: String) -> NSAttributedString {
        let output = NSMutableAttributedString()
        for (index, line) in markdown.components(separatedBy: .newlines).enumerated() {
            if index > 0 {
                output.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
            }
            output.append(renderLine(line))
        }
        return output
    }

    private func renderLine(_ line: String) -> NSAttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if let heading = Self.headingText(in: trimmed) {
            return renderInline(heading, attributes: headingAttributes)
        }
        guard let listItem = Self.listItem(in: trimmed) else {
            return renderInline(line, attributes: bodyAttributes)
        }
        let item = NSMutableAttributedString(string: "\(listItem.marker)\t", attributes: listAttributes)
        item.append(renderInline(listItem.text, attributes: listAttributes))
        return item
    }

    private func renderInline(_ text: String, attributes base: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        // Некорректный Markdown — всё равно нормальный ответ, поэтому показываем его как обычный текст.
        guard let parsed = try? AttributedString(markdown: text, options: options) else {
            return NSAttributedString(string: text, attributes: base)
        }
        let output = NSMutableAttributedString()
        for run in parsed.runs {
            let runText = String(parsed[run.range].characters)
            output.append(NSAttributedString(string: runText, attributes: attributes(for: run, base: base)))
        }
        return output
    }

    private func attributes(for run: AttributedString.Runs.Run, base: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var attributes = base
        let intent = run.inlinePresentationIntent ?? []
        let isHeading = base[.foregroundColor] as? UIColor === headingColor
        if intent.contains(.stronglyEmphasized), !isHeading {
            attributes[.font] = Typography.semibold16
            attributes[.foregroundColor] = Style.emphasisColor
        }
        if intent.contains(.emphasized) {
            attributes[.obliqueness] = Style.italicObliqueness
        }
        if intent.contains(.code) {
            attributes[.font] = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .monospacedSystemFont(ofSize: 15, weight: .regular))
        }
        if run.link != nil {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
    }

    private var bodyAttributes: [NSAttributedString.Key: Any] {
        [.font: Typography.regular16, .foregroundColor: Style.bodyColor]
    }

    private var headingAttributes: [NSAttributedString.Key: Any] {
        [.font: Typography.bold16, .foregroundColor: headingColor]
    }

    private var listAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.headIndent = Style.listIndent
        paragraph.tabStops = [NSTextTab(textAlignment: .left, location: Style.listIndent)]
        return [.font: Typography.regular16, .foregroundColor: Style.bodyColor, .paragraphStyle: paragraph]
    }

    /// От `# Title` до `### Title`.
    private static func headingText(in line: String) -> String? {
        guard let match = line.firstMatch(of: /^#{1,3}\s+(.+)$/) else { return nil }
        return String(match.1)
    }

    /// `- item`, `* item`, `• item` или `1. item`.
    private static func listItem(in line: String) -> (marker: String, text: String)? {
        if let match = line.firstMatch(of: /^[-*•]\s+(.+)$/) {
            return (Style.bullet, String(match.1))
        }
        if let match = line.firstMatch(of: /^(\d+)[.)]\s+(.+)$/) {
            return ("\(match.1).", String(match.2))
        }
        return nil
    }

    /// Текст, нарисованный pattern-цветом, получает фирменный градиент по своей ширине.
    private static func makeGradientColor() -> UIColor {
        let size = CGSize(width: Style.gradientWidth, height: 1)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = [Palette.gradientStart.cgColor, Palette.gradientEnd.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: 0), options: [])
        }
        return UIColor(patternImage: image)
    }
}
