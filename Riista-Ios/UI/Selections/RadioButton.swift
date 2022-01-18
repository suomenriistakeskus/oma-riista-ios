import Foundation
import SnapKit


/**
 * A SelectionIndicator that appears as a radio button.
 */
class RadioButton: UIButton, SelectionIndicator {
    static let defaultButtonHeight: CGFloat = AppConstants.UI.ButtonHeightSmall
    static let defaultIndicatorHeight: CGFloat = 32

    override var isSelected: Bool {
        didSet {
            updateSelectionIndicator()
            sendActions(for: .valueChanged)
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateEnabledIndication()
        }
    }

    /**
     * What to do when radio button has been clicked? Allows overriding default click behaviour.
     *
     * By default controller will be called when click is detected.
     */
    var onClicked: OnClicked?

    /**
     * The controller that handles the selection (if any).
     */
    var controller: SelectionController?


    private let indicatorImageView = UIImageView()

    var imageUnchecked = UIImage(named: "radiobutton_unchecked") {
        didSet {
            updateSelectionIndicator()
        }
    }
    var imageChecked = UIImage(named: "radiobutton_checked") {
        didSet {
            updateSelectionIndicator()
        }
    }

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: Self.defaultButtonHeight, height: Self.defaultButtonHeight))
    }

    convenience init(buttonHeight: CGFloat, indicatorHeight: CGFloat) {
        self.init(frame: CGRect(x: 0, y: 0, width: buttonHeight, height: buttonHeight))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    @objc func handleOnClicked() {
        if let onClicked = onClicked {
            onClicked()
        } else {
            controller?.onSelectableClicked(indicator: self)
        }
    }

    private func commonInit() {
        addTarget(self, action: #selector(handleOnClicked), for: .touchUpInside)

        addSubview(indicatorImageView)
        indicatorImageView.snp.makeConstraints { make in
            make.width.height.equalTo(Self.defaultIndicatorHeight)
            make.center.equalToSuperview()
        }

        self.snp.makeConstraints { make in
            make.width.equalTo(frame.width)
            make.height.equalTo(frame.height)
        }

        updateSelectionIndicator()
        updateEnabledIndication()
    }

    private func updateSelectionIndicator() {
        if (isSelected) {
            indicatorImageView.image = imageChecked
        } else {
            indicatorImageView.image = imageUnchecked
        }
    }

    private func updateEnabledIndication() {
        if (isEnabled) {
            indicatorImageView.tintColor = UIColor.applicationColor(Primary)
        } else {
            indicatorImageView.tintColor = UIColor.applicationColor(GreyDark)
        }
    }
}
