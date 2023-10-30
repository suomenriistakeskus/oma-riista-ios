import Foundation
import MaterialComponents
import SnapKit

// the default horizontal padding for the title that would be used
// if the horizontalContentAlignment == .left
fileprivate let titleHorizontalPadding: CGFloat = 16
fileprivate let spacingBetweenLabelAndIcon: CGFloat = 8

class CardButton: MDCCard {
    lazy var button: MDCButton = {
        let button = MDCButton()
        button.applyTextTheme(withScheme: AppTheme.shared.cardButtonScheme())
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center

        button.addTarget(self, action: #selector(handleClicked), for: .touchUpInside)
        return button
    }()

    // click handler for the button
    var onClicked: OnClicked?

    /**
     * The constraint for adjusting titleLabel width in respect to button width
     */
    private var titleLabelWidthConstraint: Constraint?

    // how the button title should be aligned?
    override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        get {
            button.contentHorizontalAlignment
        }
        set(alignment) {
            button.contentHorizontalAlignment = alignment
            updateTitleLabelConstraint()
        }
    }

    /**
     * Should space be reserved for a trailing icon? If already reserved, the title won't jump if icon is displayed later.
     */
    var reserveSpaceForIcon: Bool = false {
        didSet {
            updateTitleLabelConstraint()
        }
    }

    override var isEnabled: Bool {
        get {
            button.isEnabled
        }
        set(enabled) {
            button.isEnabled = enabled
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

    var iconSize: CGSize = CGSize(width: 18, height: 18) {
        didSet {
            iconWidthConstraint?.update(offset: iconSize.width)
            iconHeightConstraint?.update(offset: iconSize.height)

            updateTitleLabelConstraint()
        }
    }

    private var iconWidthConstraint: Constraint?
    private var iconHeightConstraint: Constraint?

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
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var title: String? {
        get {
            button.title(for: .normal)
        }
        set(value) {
            button.setTitle(value, for: .normal)
        }
    }

    init(title: String? = "", height: CGFloat = AppConstants.UI.DefaultButtonHeight) {
        super.init(frame: CGRect.zero)
        self.title = title
        setup(height: height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    @objc private func handleClicked() {
        onClicked?()
    }

    private func setup(height: CGFloat = AppConstants.UI.DefaultButtonHeight) {
        addSubview(button)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview() // fill the card
        }

        button.addSubview(trailingIconImageView)
        if let titleLabel = button.titleLabel {
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                // use lessThanOrEqualToSuperview to attach icon to title label
                // inset would inset from left and right -> use offset to have more fine-grained control over width
                titleLabelWidthConstraint = make.width.equalToSuperview().offset(-2 * titleHorizontalPadding).constraint
            }
        }
        trailingIconImageView.snp.makeConstraints { make in
            iconWidthConstraint = make.width.equalTo(0).offset(iconSize.width).constraint
            iconHeightConstraint = make.height.equalTo(0).offset(iconSize.height).constraint

            if let titleLabel = button.titleLabel {
                make.leading.equalTo(titleLabel.snp.trailing).offset(spacingBetweenLabelAndIcon)
                make.centerY.equalTo(titleLabel)
            }
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(height)
        }
    }

    private func updateTitleLabelConstraint() {
        let allocateSpaceForIcon: CGFloat = (reserveSpaceForIcon || (trailingIcon != nil && !isTrailingIconHidden)) ? 1 : 0

        let offset: CGFloat
        switch contentHorizontalAlignment {
        case .center, .fill:
            // text is centered i.e. we need to reserve space that would equal the situation
            // where there would be also a leading icon:
            // |<padding><leading icon><spacing><centered text><spacing><trailing icon><padding>|
            offset = 2 * (titleHorizontalPadding + allocateSpaceForIcon * iconSize.width + spacingBetweenLabelAndIcon)
            break
        case .left, .right, .leading, .trailing: fallthrough
        @unknown default:
            // |<padding><text><spacing><trailing icon><padding>|
            offset = 2 * titleHorizontalPadding + allocateSpaceForIcon * (iconSize.width + spacingBetweenLabelAndIcon)
            break
        }

        titleLabelWidthConstraint?.update(offset: -offset)
    }
}
