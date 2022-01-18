import Foundation


protocol YesNoChoiceViewDelegate: ProvidesNavigationController {
    func onYesNoValueChanged(sender: YesNoChoiceView, newValue: Bool?)
}

class YesNoChoiceView: UIView, ValueSelectionDelegate {
    private let yesNoButton: RiistaValueListButton
    // the titletext without any additional postfixes
    private var titleText: String
    private let validValueRequired: Bool
    private var required: Bool {
        didSet {
            self.updateTitle()
        }
    }
    private var requiredPostfix: String {
        get {
            return required ? " *" : ""
        }
    }
    var value: Bool? {
        didSet {
            if (value == oldValue) {
                return
            }

            if (validValueRequired) {
                updateRequired()
            }

            updateDisplayedValue()
        }
    }
    weak var delegate: YesNoChoiceViewDelegate?

    private var valueForYes: String {
        get {
            RiistaBridgingUtils.RiistaLocalizedString(forkey: "Yes")
        }
    }
    private var valueForNo: String {
        get {
            RiistaBridgingUtils.RiistaLocalizedString(forkey: "No")
        }
    }

    init(frame: CGRect, title: String, validValueRequired: Bool, value: Bool?) {
        self.yesNoButton = RiistaValueListButton(frame: frame)
        self.titleText = title
        self.validValueRequired = validValueRequired
        self.required = YesNoChoiceView.isRequired(validValueRequired: validValueRequired, currentValue: value)
        self.value = value

        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        yesNoButton.backgroundColor = UIColor.applicationColor(ViewBackground)
        yesNoButton.addTarget(self, action: #selector(onClicked), for: .touchUpInside)
        updateTitle()
        updateDisplayedValue()

        addSubview(yesNoButton)
    }

    private func updateTitle() {
        yesNoButton.titleText = self.titleText + self.requiredPostfix
    }

    private func updateRequired() {
        self.required = YesNoChoiceView.isRequired(
            validValueRequired: self.validValueRequired,
            currentValue: self.value
        )
    }

    private func updateDisplayedValue() {
        let valueText: String
        switch self.value {
        case .none:
            valueText = ""
            break
        case .some(let value):
            valueText = value ? valueForYes : valueForNo
            break
        }
        yesNoButton.valueText = valueText
    }

    private class func isRequired(validValueRequired: Bool, currentValue: Bool?) -> Bool {
        let valueIsInvalid = currentValue == nil
        return validValueRequired ? valueIsInvalid : false
    }

    @objc private func onClicked() {
        guard let navigationController = delegate?.navigationController else {
            print("No NavigationController, cannot handle click")
            return
        }

        let storyboard = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "valueListController") as? ValueListViewController else {
            print("Cannot instantiate ValueListViewController!")
            return
        }

        controller.titlePrompt = self.titleText
        controller.fieldKey = self.titleText
        controller.values = [valueForYes, valueForNo]
        controller.delegate = self

        navigationController.pushViewController(controller, animated: true)
    }

    func valueSelected(forKey key: String!, value: String!) {
        if (key == self.titleText) {
            let newValue: Bool?
            switch value {
            case valueForYes:
                newValue = true
                break
            case valueForNo:
                newValue = false
                break
            default:
                newValue = nil
                break
            }

            delegate?.onYesNoValueChanged(sender: self, newValue: newValue)
        }
    }
}
