import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.stringSingleLine

class SingleLineStringFieldCell<FieldId : DataFieldId>: TextFieldCell<FieldId, StringField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: StringEventDispatcher?

    override func fieldWasBound(field: StringField<FieldId>) {
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
        textField.text = field.value
    }

    override func onTextChanged(text: String) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: text
        ) { eventDispatcher, fieldId, text in
            eventDispatcher.dispatchStringChanged(fieldId: fieldId, value: text)
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: StringEventDispatcher?

        init(eventDispatcher: StringEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(SingleLineStringFieldCell<FieldId>.self,
                               forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView,
                                 indexPath: IndexPath,
                                 dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! SingleLineStringFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
