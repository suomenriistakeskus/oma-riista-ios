import Foundation
import SnapKit


/**
 * A label with an icon
 */
class LabelAndIcon: UIView {

    enum LabelAlignment: Int {
        // label is located at the leading side of the control
        case leading

        // label is located at the trailing side of the control
        case trailing
    }

    var labelAlignment: LabelAlignment = .leading {
        didSet {
            updateLabelAlignment()
        }
    }

    var text: String {
        get {
            label.text ?? ""
        }
        set(value) {
            label.text = value
        }
    }

    var spacingBetweenLabelAndIcon: CGFloat = 8 {
        didSet {
            spacingConstraint?.update(offset: spacingBetweenLabelAndIcon)
        }
    }

    var iconImage: UIImage? {
        get {
            iconImageView.image
        }
        set(value) {
            iconImageView.image = value
        }
    }

    var iconTintColor: UIColor {
        get {
            iconImageView.tintColor
        }
        set(value) {
            iconImageView.tintColor = value
        }
    }

    var iconSize: CGSize = CGSize(width: 24, height: 24) {
        didSet {
            iconWidthConstraint?.update(offset: iconSize.width)
            iconHeightConstraint?.update(offset: iconSize.height)
        }
    }

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelMedium)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 1
        return label
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.snp.remakeConstraints { make in
            iconWidthConstraint = make.width.equalTo(0).offset(iconSize.width).constraint
            iconHeightConstraint = make.height.equalTo(0).offset(iconSize.height).constraint
        }
        return imageView
    }()

    // A container for the iconImageView so that width/height constraints won't be removed
    // when iconSize is changed
    private lazy var iconImageViewContainer: UIView = {
        let view = UIView()
        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private var spacingConstraint: Constraint? = nil
    private var iconWidthConstraint: Constraint? = nil
    private var iconHeightConstraint: Constraint? = nil

    override var forFirstBaselineLayout: UIView {
        get {
            label
        }
    }

    override var forLastBaselineLayout: UIView {
        get {
            label
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        addSubview(label)
        addSubview(iconImageViewContainer)

        updateLabelAlignment()
    }

    private func updateLabelAlignment() {
        switch labelAlignment {
        case .leading:
            makeLeadingLabelConstraints()
            break
        case .trailing:
            makeTrailingLabelConstraints()
            break
        }
    }

    private func makeLeadingLabelConstraints() {
        remakeConstraints(leadingView: label, trailingView: iconImageViewContainer)
    }

    private func makeTrailingLabelConstraints() {
        remakeConstraints(leadingView: iconImageViewContainer, trailingView: label)
    }

    private func remakeConstraints(leadingView: UIView, trailingView: UIView) {
        leadingView.snp.remakeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        trailingView.snp.remakeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            spacingConstraint = make.leading.equalTo(leadingView.snp.trailing).offset(spacingBetweenLabelAndIcon).constraint
        }
    }
}
