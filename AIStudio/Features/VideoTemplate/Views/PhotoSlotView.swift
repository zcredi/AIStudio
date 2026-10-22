import UIKit

/// Слот стартового кадра: «+» для выбора фото, прогресс во время загрузки, затем фото с кнопкой удаления.
final class PhotoSlotView: UIView {
    // MARK: - Types

    enum Content: Equatable {
        case empty
        case loading
        case photo(UIImage)
    }

    private enum Layout {
        static let size: CGFloat = 100
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let plusConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .light)
        static let removeButtonSize: CGFloat = 32
        /// Кнопка удаления перекрывает правый верхний угол фото, как в макете.
        static let removeButtonOffset = CGPoint(x: 76, y: -8)
    }

    // MARK: - Properties

    var onAdd: (() -> Void)?
    var onRemove: (() -> Void)?

    private let addButton = UIButton(type: .custom)
    private let borderLayer = CAGradientLayer()
    private let borderMask = CAShapeLayer()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let imageView = UIImageView()
    private let removeButton = UIButton(type: .custom)
    private var content: Content?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
        render(.empty)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        borderLayer.frame = addButton.bounds
        let inset = Layout.borderWidth / 2
        borderMask.path = UIBezierPath(
            roundedRect: addButton.bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: Layout.cornerRadius - inset
        ).cgPath
        CATransaction.commit()
    }

    /// Кнопка удаления выступает за пределы слота, поэтому вся её площадь должна оставаться нажимаемой.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event) || (!removeButton.isHidden && removeButton.frame.contains(point))
    }

    // MARK: - API

    func render(_ content: Content) {
        guard content != self.content else { return }
        let isFirstRender = self.content == nil
        self.content = content
        guard !isFirstRender, window != nil else {
            apply(content)
            return
        }
        UIView.transition(with: self, duration: Motion.fast, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.apply(content)
        }
    }

    // MARK: - Private

    private func apply(_ content: Content) {
        addButton.isHidden = content != .empty
        backgroundColor = content == .loading ? Palette.card : .clear
        if content == .loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        if case .photo(let image) = content {
            imageView.image = image
            imageView.isHidden = false
            removeButton.isHidden = false
        } else {
            imageView.image = nil
            imageView.isHidden = true
            removeButton.isHidden = true
        }
        accessibilityElements = content == .loading ? [spinner] : nil
        spinner.accessibilityLabel = String(localized: "Uploading photo")
    }

    private func setupViews() {
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous

        addButton.setImage(UIImage(systemName: "plus", withConfiguration: Layout.plusConfiguration), for: .normal)
        addButton.tintColor = Palette.textPrimary
        addButton.accessibilityLabel = String(localized: "Add photo")
        addButton.addAction(UIAction { [weak self] _ in self?.onAdd?() }, for: .touchUpInside)
        borderLayer.colors = [Palette.gradientStart.cgColor, Palette.gradientEnd.cgColor]
        borderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        borderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        borderMask.lineWidth = Layout.borderWidth
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderLayer.mask = borderMask
        addButton.layer.insertSublayer(borderLayer, at: 0)

        spinner.color = Palette.textPrimary
        spinner.hidesWhenStopped = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.cornerRadius
        imageView.layer.cornerCurve = .continuous
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = String(localized: "Selected photo")

        removeButton.backgroundColor = Palette.textPrimary
        removeButton.layer.cornerRadius = Layout.removeButtonSize / 2
        removeButton.setImage(UIImage(resource: .closeIcon), for: .normal)
        removeButton.accessibilityLabel = String(localized: "Remove photo")
        removeButton.addAction(UIAction { [weak self] _ in self?.onRemove?() }, for: .touchUpInside)
    }

    private func setupLayout() {
        [addButton, spinner, imageView, removeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Layout.size),
            heightAnchor.constraint(equalToConstant: Layout.size),
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            removeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.removeButtonOffset.x),
            removeButton.topAnchor.constraint(equalTo: topAnchor, constant: Layout.removeButtonOffset.y),
            removeButton.widthAnchor.constraint(equalToConstant: Layout.removeButtonSize),
            removeButton.heightAnchor.constraint(equalToConstant: Layout.removeButtonSize),
        ])
        addButton.pinEdges(to: self)
        imageView.pinEdges(to: self)
    }
}
