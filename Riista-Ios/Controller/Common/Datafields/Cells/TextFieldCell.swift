import Foundation
import SnapKit
import RiistaCommon


class TextFieldCell<FieldId : DataFieldId, FieldType: DataField<FieldId>>: TypedDataFieldCell<FieldId, FieldType>  {

    private(set) lazy var textFieldAndLabel: TextFieldAndLabel = {
        let textFieldAndLabel = TextFieldAndLabel()
        configureTextField(textFieldAndLabel.textField)

        textFieldAndLabel.onTextChanged = { [weak self] text in
            self?.onTextChanged(text: text)
        }

        return textFieldAndLabel
    }()


    // convenience access to values and UI elements

    var isEnabled: Bool {
        get {
            textFieldAndLabel.isEnabled
        }
        set(newValue) {
            textFieldAndLabel.isEnabled = newValue
        }
    }

    var captionLabel: LabelView {
        get {
            textFieldAndLabel.captionLabel
        }
    }

    var textField: TextField {
        get {
            textFieldAndLabel.textField
        }
    }

    override var containerView: UIView {
        return textFieldAndLabel
    }

    override func createSubviews(for container: UIView) {
        // nop, but required by superview
    }

    override func fieldWasBound(field: FieldType) {
        // nop
    }

    func onTextChanged(text: String) {
        // nop
    }

    func configureTextField(_ textField: TextField) {
        // nop
    }
}
