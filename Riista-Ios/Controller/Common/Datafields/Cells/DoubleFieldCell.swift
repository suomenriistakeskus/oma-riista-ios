import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.double

class DoubleFieldCell<FieldId : DataFieldId>: TextFieldCell<FieldId, DoubleField<FieldId>>, UITextFieldDelegate {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: DoubleEventDispatcher?

    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.locale = RiistaSettings.locale()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        return numberFormatter
    }()

    override func fieldWasBound(field: DoubleField<FieldId>) {
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

        // don't update configuration if dispatching value
        // - i.e. we're receiving value that we just sent
        if (!dispatchingValueChanged) {
            if let decimals = field.settings.decimals?.intValue {
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = decimals

                if (decimals > 0) {
                    textField.keyboardType = .decimalPad
                } else {
                    textField.keyboardType = .asciiCapableNumberPad
                }
            } else {
                textField.keyboardType = .decimalPad
            }
        }

        if let value = field.value?.doubleValue {
            if (!equalsCurrentValue(value: value)) {
                textField.text = numberFormatter.string(for: value)
            }
        } else {
            textField.text = ""
        }
    }

    override func onTextChanged(text: String) {
        let value = text.parseDouble()?.toKotlinDouble()

        dispatchNullableValueChanged(
            eventDispatcher: eventDispatcher,
            value: value
        ) { eventDispatcher, fieldId, value in
            eventDispatcher.dispatchDoubleChanged(fieldId: fieldId, value: value)
        }
    }

    private func equalsCurrentValue(value: Double) -> Bool {
        let currentValue: Double = textField.text?.parseDouble() ?? 0.0
        return (abs(currentValue - value) < 0.00001)
    }

    override func configureTextField(_ textField: TextField) {
        super.configureTextField(textField)
        textField.delegate = self
        textField.keyboardType = .decimalPad
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let maxValue = boundField?.settings.maxValue?.doubleValue, let currentText = textField.text {
            let newText = NSString(string: currentText).replacingCharacters(in: range, with: string)
            if (newText.isEmpty) {
                return true
            } else if let doubleValue = newText.parseDouble(), doubleValue <= maxValue {
                if let decimals = boundField?.settings.decimals?.intValue {
                    return newText.numberOfDecimals() <= decimals
                }
                return true
            }

            return false
        } else {
            return true
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: DoubleEventDispatcher?

        init(eventDispatcher: DoubleEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(DoubleFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! DoubleFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}

fileprivate extension String {
    func numberOfDecimals() -> Int {
        let decimalsWithDot = self.substringAfter(needle: ".").count
        let decimalsWithComma = self.substringAfter(needle: ",").count

        return max(decimalsWithDot, decimalsWithComma)
    }
}
