import Foundation
import MaterialComponents
import SnapKit

fileprivate let iconSize: CGFloat = 18
fileprivate let labelHorizontalPadding: CGFloat = 8
fileprivate let spacingBetweenLabelAndIcon: CGFloat = 8

class CardButton: MDCCard {
    lazy var button: MDCButton = {
        let button = MDCButton()
        button.applyTextTheme(withScheme: AppTheme.shared.cardButtonScheme())
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        return button
    }()

    /**
     * The constraint for adjusting titleLabel width in respect to button width
     */
    private var titleLabelWidthConstraint: Constraint?

    /**
     * Should space be reserved for a trailing icon? If already reserved, the title won't jump if icon is displayed later.
     */
    var reserveSpaceForIcon: Bool = false {
        didSet {
            updateTitleLabelConstraint()
        }
    }

    /**
     * A convenience property for accessing trailing icon image.
     *
     * Prefer using this over accessing trailingIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var trailingIcon: UIImage? {
        get {
            trailingIconImageView.image
        }
        set(image) {
            trailingIconImageView.image = image
            updateTitleLabelConstraint()
        }
    }

    /**
     * A convenience property for showing/hiding trailing icon.
     *
     * Prefer using this over accessing trailingIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var isTrailingIconHidden: Bool {
        get {
            trailingIconImageView.isHidden
        }
        set(hidden) {
            trailingIconImageView.isHidden = hidden
            updateTitleLabelConstraint()
        }
    }

    lazy var trailingIconImageView: UIImageView = {
        UIImageView()
    }()

    var title: String? {
        get {
            button.title(for: .normal)
        }
        set(value) {
            button.setTitle(value, for: .normal)
        }
    }

    init(title: String? = "") {
        super.init(frame: CGRect.zero)
        self.title = title
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    open override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    private func setup() {
        addSubview(button)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview() // fill the card
        }

        button.addSubview(trailingIconImageView)
        if let titleLabel = button.titleLabel {
            titleLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
                titleLabelWidthConstraint = make.width.lessThanOrEqualToSuperview().inset(labelHorizontalPadding).constraint
            }
        }
        trailingIconImageView.snp.makeConstraints { make in
            make.width.height.lessThanOrEqualTo(iconSize)

            if let titleLabel = button.titleLabel {
                make.leading.equalTo(titleLabel.snp.trailing).offset(spacingBetweenLabelAndIcon)
                make.centerY.equalTo(titleLabel)
            }
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(AppConstants.UI.DefaultButtonHeight)
        }
    }

    private func updateTitleLabelConstraint() {
        if (reserveSpaceForIcon || (trailingIcon != nil && !isTrailingIconHidden)) {
            titleLabelWidthConstraint?.update(inset: iconSize + spacingBetweenLabelAndIcon + labelHorizontalPadding)
        } else {
            titleLabelWidthConstraint?.update(inset: labelHorizontalPadding)
        }
    }
}
