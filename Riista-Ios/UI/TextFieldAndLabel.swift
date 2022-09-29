import Foundation
import SnapKit
import RiistaCommon


class TextFieldAndLabel: UIStackView {

    var onTextChanged: OnTextChanged? = nil

    var isEnabled: Bool = false {
        didSet {
            if (isEnabled != oldValue) {
                onEnabledChanged()
            }
        }
    }

    private(set) var editingText: Bool = false {
        didSet {
            if (editingText != oldValue) {
                updateLineColor()
            }
        }
    }

    private lazy var topLevelContainer: UIStackView = {
        // use a vertical stackview for containing caption + textfield
        // -> allows hiding caption if necessary
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 2
        container.alignment = .fill
        return container
    }()

    private(set) lazy var captionLabel: LabelView = {
        let labelView = LabelView()
        return labelView
    }()

    private lazy var textFieldAndLine: UIView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        container.addView(textField)
        container.addView(lineUnderTextField)
        return container
    }()

    private(set) lazy var textField: TextField = {
        let textField = TextField()
        textField.textColor = UIColor.applicationColor(TextPrimary)
        textField.font = UIFont.appFont(for: .inputValue)
        textField.autocorrectionType = .no

        textField.textAlignment = .left

        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        return textField
    }()

    private(set) lazy var lineUnderTextField: SeparatorView = {
        // bg color of the separator updated when isEnabled status is taken into account
        SeparatorView(orientation: .horizontal)
    }()

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        axis = .vertical
        spacing = 2
        alignment = .fill

        addArrangedSubview(captionLabel)
        addArrangedSubview(textFieldAndLine)

        textField.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(30).priority(999)
        }

        onEnabledChanged()
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        onTextChanged?(text)
    }

    @objc private func textFieldEditingDidBegin(_ textField: UITextField) {
        editingText = true
    }

    @objc private func textFieldEditingDidEnd(_ textField: UITextField) {
        editingText = false
    }

    private func onEnabledChanged() {
        updateTextFieldEnabledIndication()
        updateLineColor()
    }

    private func updateTextFieldEnabledIndication() {
        textField.isEnabled = isEnabled
        if (isEnabled) {
            textField.textColor = UIColor.applicationColor(TextPrimary)
        } else {
            textField.textColor = UIColor.applicationColor(GreyMedium)
        }
    }

    private func updateLineColor() {
        let lineColor: UIColor
        if (editingText) {
            lineColor = UIColor.applicationColor(Primary)
        } else {
            if (isEnabled) {
                lineColor = UIColor.applicationColor(TextPrimary)
            } else {
                lineColor = UIColor.applicationColor(GreyMedium)
            }
        }

        if (lineUnderTextField.backgroundColor != lineColor) {
            UIView.animate(withDuration: AppConstants.Animations.durationShort) { [weak self] in
                self?.lineUnderTextField.backgroundColor = lineColor
            }
        }
    }
}
