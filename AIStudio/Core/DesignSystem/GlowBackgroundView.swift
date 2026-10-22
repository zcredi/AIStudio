import UIKit

/// Фон экрана с мягким фирменным свечением сверху, как на пейволе и главной.
/// Свечение заранее отрисовано из эллипсов Figma: каталог ассетов теряет SVG-фильтры размытия.
final class GlowBackgroundView: UIView {
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.background
        isUserInteractionEnabled = false
        setupGlow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupGlow() {
        let image = UIImage(resource: .glowBackground)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        // Нижний край картинки совпадает с фоном, поэтому её можно масштабировать по ширине.
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(
                equalTo: imageView.widthAnchor,
                multiplier: image.size.height / image.size.width
            ),
        ])
    }
}
