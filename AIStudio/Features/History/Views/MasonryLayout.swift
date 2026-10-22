import UIKit

/// Две колонки карточек, высота которых следует пропорциям; каждая карточка уходит в более короткую колонку.
@MainActor
enum MasonryLayout {
    static func makeSection(
        aspectRatios: [CGFloat],
        environment: any NSCollectionLayoutEnvironment,
        spacing: CGFloat,
        insets: NSDirectionalEdgeInsets
    ) -> NSCollectionLayoutSection {
        let width = environment.container.effectiveContentSize.width - insets.leading - insets.trailing
        let columnWidth = ((width - spacing) / 2).rounded(.down)
        var columnHeights: [CGFloat] = [0, 0]
        var frames: [CGRect] = []
        for aspectRatio in aspectRatios {
            let column = columnHeights[0] <= columnHeights[1] ? 0 : 1
            let height = (columnWidth / max(aspectRatio, .ulpOfOne)).rounded()
            frames.append(CGRect(x: CGFloat(column) * (columnWidth + spacing), y: columnHeights[column], width: columnWidth, height: height))
            columnHeights[column] += height + spacing
        }

        // Группе нужна положительная высота даже без элементов.
        let contentHeight = max((columnHeights.max() ?? 0) - spacing, 1)
        let items = frames.map { NSCollectionLayoutGroupCustomItem(frame: $0) }
        let group = NSCollectionLayoutGroup.custom(layoutSize: NSCollectionLayoutSize(
            widthDimension: .absolute(width),
            heightDimension: .absolute(contentHeight)
        )) { _ in
            items
        }
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = insets
        return section
    }
}
