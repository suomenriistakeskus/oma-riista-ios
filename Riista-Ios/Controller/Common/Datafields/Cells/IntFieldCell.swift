import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.int

class IntFieldCell<FieldId : DataFieldId>: TextFieldCell<FieldId, IntField<FieldId>>, UITextFieldDelegate {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: IntEventDispatcher?

    override func fieldWasBound(field: IntField<FieldId>) {
        if let label = field.settings.label {
            captionLabel.text = label
            captionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }

        if (!field.settings.readOnly && eventDispatcher != nil) {
            isEnabled = true
        } else {
            isEnabled = false
            if (!field.settings.readOnly) {
                print("No event dispatcher, displaying field \(field.id_) in disabled mode!")
            }
        }

        if let value = field.value?.intValue {
            textField.text = String(value)
        } else {
            textField.text = ""
        }
    }

    override func onTextChanged(text: String) {
        let value = parseInt(text: text)?.toKotlinInt()

        dispatchNullableValueChanged(
            eventDispatcher: eventDispatcher,
            value: value
        ) { eventDispatcher, fieldId, value in
            eventDispatcher.dispatchIntChanged(fieldId: fieldId, value: value)
        }
    }

    private func parseInt(text: String) -> Int? {
        return Int(text)
    }

    override func configureTextField(_ textField: TextField) {
        super.configureTextField(textField)
        textField.delegate = self
        textField.keyboardType = .asciiCapableNumberPad
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let maxValue = boundField?.settings.maxValue?.intValue, let currentText = textField.text {
            let newText = NSString(string: currentText).replacingCharacters(in: range, with: string)
            if (newText.isEmpty) {
                return true
            } else if let intValue = parseInt(text: newText), intValue <= maxValue {
                return true
            }

            return false
        } else {
            return true
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: IntEventDispatcher?

        init(eventDispatcher: IntEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(IntFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! IntFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
