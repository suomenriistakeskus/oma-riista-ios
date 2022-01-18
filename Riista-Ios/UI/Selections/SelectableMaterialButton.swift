import Foundation
import MaterialComponents
import SnapKit


/**
 * A SelectionIndicator that appears as a selectable material button.
 */
class SelectableMaterialButton: ButtonWithRoundedCorners, SelectionIndicator {

    override var isSelected: Bool {
        didSet {
            updateColors()
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateColors()
        }
    }

    /**
     * The controller that handles the selection (if any).
     */
    var controller: SelectionController?


    // don't use buttons titleLabel / imageView as we want to have full control over
    // label and imageview positioning and hierarchy
    // -> use custom UILabel + UIImageView for the label and icon

    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.ButtonMedium, fontWeight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private(set) lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(32).priority(999)
        }
        return imageView
    }()

    /**
     * MDCStatefulRippleView seems to give better results than MDCRippleTouchController. The controller
     * approach had some flickering.
     */
    private let rippleView: MDCStatefulRippleView = MDCStatefulRippleView()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }


    @objc func onTouchUpInside() {
        controller?.onSelectableClicked(indicator: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        rippleView.touchesBegan(touches, with: event)
        super.touchesBegan(touches, with: event)

        rippleView.isRippleHighlighted = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        rippleView.touchesMoved(touches, with: event)
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        rippleView.touchesEnded(touches, with: event)
        super.touchesEnded(touches, with: event)

        rippleView.isRippleHighlighted = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        rippleView.touchesCancelled(touches, with: event)
        super.touchesCancelled(touches, with: event)
        rippleView.isRippleHighlighted = false
    }

    private func commonInit() {
        addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)

        addSubview(rippleView)
        rippleView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        roundedCorners = CACornerMask.allCorners()
        cornerRadius = 2

        // wrap icon + label into a separate container and center that
        // -> for some reason the click handling didn't work as intended with normal UIStackView
        let container = OverlayStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 2
        addSubview(container)

        container.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(8)
        }

        container.addArrangedSubview(iconImageView)
        container.addArrangedSubview(label)

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(AppConstants.UI.ButtonHeightSmall)
        }
    }

    private func updateColors() {
        if (isEnabled) {
            if (isSelected) {
                backgroundColor = UIColor.applicationColor(Primary)
                label.textColor = .white
                iconImageView.tintColor = .white
            } else {
                backgroundColor = UIColor.applicationColor(GreyLight)
                label.textColor = UIColor.applicationColor(Primary)
                iconImageView.tintColor = UIColor.applicationColor(Primary)
            }
        } else {
            if (isSelected) {
                backgroundColor = UIColor.applicationColor(GreyDark)
                label.textColor = .white
                iconImageView.tintColor = .white
            } else {
                backgroundColor = UIColor.applicationColor(GreyLight)
                label.textColor = UIColor.applicationColor(TextPrimary)
                iconImageView.tintColor = UIColor.applicationColor(TextPrimary)
            }
        }
    }
}
