import UIKit

/// Варианты покупки во всех состояниях: skeleton при загрузке, карточки или ошибка с повтором.
/// Вид держит высоту самого высокого состояния, поэтому смена состояний никогда не двигает раскладку.
final class PaywallPlansView: UIView {
    // MARK: - Types

    private enum Layout {
        static let cardSpacing = Spacing.m
        static let skeletonCount = 2
        static let errorTextColor = Palette.textPrimary.withAlphaComponent(0.7)
    }

    // MARK: - Properties

    var onSelectPlan: ((PaywallPlan.ID) -> Void)?
    var onRetry: (() -> Void)?

    private let cardsStack = UIStackView()
    private let skeletonStack = UIStackView()
    private let errorStack = UIStackView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(configuration: .plain())
    private weak var visibleView: UIView?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    func render(_ plans: Loadable<[PaywallPlan]>, selectedPlanID: PaywallPlan.ID?, isInteractionEnabled: Bool) {
        cardsStack.isUserInteractionEnabled = isInteractionEnabled
        switch plans {
        case .loading:
            show(skeletonStack)
        case .loaded(let plans):
            updateCards(with: plans, selectedPlanID: selectedPlanID)
            show(cardsStack)
        case .failed(let error):
            errorLabel.text = error.message
            show(errorStack)
        }
    }

    // MARK: - Private

    private func setupViews() {
        [cardsStack, skeletonStack].forEach {
            $0.axis = .vertical
            $0.spacing = Layout.cardSpacing
        }
        (0..<Layout.skeletonCount).forEach { _ in skeletonStack.addArrangedSubview(PaywallPlanSkeletonView()) }

        errorLabel.font = Typography.regular14
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = Layout.errorTextColor
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        var retryConfiguration = UIButton.Configuration.plain()
        retryConfiguration.title = String(localized: "Try again")
        retryConfiguration.baseForegroundColor = Palette.textPrimary
        retryConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold14
            return attributes
        }
        retryButton.configuration = retryConfiguration
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        errorStack.axis = .vertical
        errorStack.alignment = .center
        errorStack.spacing = Spacing.s
        errorStack.addArrangedSubview(errorLabel)
        errorStack.addArrangedSubview(retryButton)

        [cardsStack, skeletonStack, errorStack].forEach {
            $0.alpha = 0
            addSubview($0)
        }
    }

    private func setupLayout() {
        [cardsStack, skeletonStack, errorStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // Каждое состояние может увеличить вид, но ни одно не сжимает его ниже высоты другого.
        let collapsedHeight = heightAnchor.constraint(equalToConstant: 0)
        collapsedHeight.priority = .defaultLow

        NSLayoutConstraint.activate([
            collapsedHeight,
            cardsStack.topAnchor.constraint(equalTo: topAnchor),
            cardsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardsStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            skeletonStack.topAnchor.constraint(equalTo: topAnchor),
            skeletonStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            skeletonStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            skeletonStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            errorStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])
    }

    private func updateCards(with plans: [PaywallPlan], selectedPlanID: PaywallPlan.ID?) {
        let cards = cardsStack.arrangedSubviews.compactMap { $0 as? PaywallPlanView }
        if cards.map(\.planID) == plans.map(\.id) {
            zip(cards, plans).forEach { $0.configure(with: $1) }
        } else {
            cards.forEach { $0.removeFromSuperview() }
            plans.forEach { cardsStack.addArrangedSubview(makeCard(for: $0)) }
        }
        cardsStack.arrangedSubviews
            .compactMap { $0 as? PaywallPlanView }
            .forEach { $0.isSelected = $0.planID == selectedPlanID }
    }

    private func makeCard(for plan: PaywallPlan) -> PaywallPlanView {
        let card = PaywallPlanView(plan: plan)
        card.addAction(UIAction { [weak self] _ in self?.onSelectPlan?(plan.id) }, for: .touchUpInside)
        return card
    }

    /// Кроссфейд к `view`; скрытые состояния остаются в раскладке, чтобы высота не менялась.
    private func show(_ view: UIView) {
        guard view !== visibleView else { return }
        visibleView = view
        let views = [cardsStack, skeletonStack, errorStack]
        views.forEach { $0.accessibilityElementsHidden = $0 !== view }
        UIView.animate(withDuration: Motion.standard, delay: 0, options: [.beginFromCurrentState]) {
            views.forEach { $0.alpha = $0 === view ? 1 : 0 }
        }
    }
}
