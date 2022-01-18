import Foundation

/**
 * A custom RadioButton that also is able to have a label.
 *
 * Implement SelectionIndicator so that label text can also indicate enabled status.
 */
class RadioButtonWithLabel: LabelAndControl, SelectionIndicator {
    var isSelected: Bool = false {
        didSet {
            radioButton.isSelected = isSelected
        }
    }

    var isEnabled: Bool = false {
        didSet {
            radioButton.isEnabled = isEnabled
        }
    }

    var controller: SelectionController?

    lazy var radioButton: RadioButton = {
        let btn = RadioButton(buttonHeight: minHeight, indicatorHeight: min(minHeight, RadioButton.defaultIndicatorHeight))
        // override button click handler so that our controller gets notified about selection
        btn.onClicked = { [weak self] in
            self?.onClicked()
        }
        return btn
    }()

    init(labelText: String, labelAlignment: LabelAndControl.LabelAlignment = .trailing, minHeight: CGFloat = AppConstants.UI.ButtonHeightSmall) {
        super.init(frame: CGRect.zero, labelText: labelText, minHeight: minHeight)
        self.labelAlignment = labelAlignment
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func getControlView() -> UIView {
        radioButton
    }

    override func setup() {
        super.setup()

        setupGestureDetector()

        // indicate clickability with text color
        label.textColor = UIColor.applicationColor(Primary)
    }

    private func setupGestureDetector() {
        // add a gesture detector for selecting the radiobutton also from the label area
        let tapDetector = UITapGestureRecognizer(target: self, action: #selector(onClicked))
        addGestureRecognizer(tapDetector)
    }

    @objc func onClicked() {
        controller?.onSelectableClicked(indicator: self)
    }
}
