import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.yesNoToggle

class YesNoBooleanFieldCell<FieldId : DataFieldId>: SelectableButtonCell<FieldId, BooleanField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: BooleanEventDispatcher?

    private let yesNoSelectionController = RadioButtonGroup<Bool>()

    override func createSubviews(for container: UIView) {
        super.createSubviews(for: container)

        yesNoSelectionController.addSelectable(
            addButton(text: "No".localized(), iconName: nil),
            data: false
        )

        yesNoSelectionController.addSelectable(
            addButton(text: "Yes".localized(), iconName: nil),
            data: true
        )

        yesNoSelectionController.isEnabled = false

        yesNoSelectionController.animationContainerView = buttonContainer
        yesNoSelectionController.onSelectionChanged = { [weak self] value in
            self?.dispatchValueChanged(
                eventDispatcher: self?.eventDispatcher,
                value: value
            ) { eventDispatcher, fieldId, value in
                eventDispatcher.dispatchBooleanChanged(fieldId: fieldId, value: value)
            }
        }
    }

    override func fieldWasBound(field: BooleanField<FieldId>) {
        if let label = field.settings.label {
            captionLabel.text = label
            captionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }

        if (!field.settings.readOnly && eventDispatcher != nil) {
            yesNoSelectionController.isEnabled = true
        } else {
            yesNoSelectionController.isEnabled = false
            if (!field.settings.readOnly) {
                print("No event dispatcher, displaying field \(field.id_) in disabled mode!")
            }
        }

        if let value = field.value {
            yesNoSelectionController.select(data: value.boolValue)
        } else {
            yesNoSelectionController.deselectAll()
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: BooleanEventDispatcher?

        init(eventDispatcher: BooleanEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(YesNoBooleanFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! YesNoBooleanFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
