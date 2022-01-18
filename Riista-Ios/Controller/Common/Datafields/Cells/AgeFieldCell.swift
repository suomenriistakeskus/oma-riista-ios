import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.age

class AgeFieldCell<FieldId : DataFieldId>: SelectableButtonCell<FieldId, AgeField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: AgeEventDispatcher?

    private let ageSelectionController = RadioButtonGroup<RiistaCommon.GameAge>()

    override func createSubviews(for container: UIView) {
        super.createSubviews(for: container)

        ageSelectionController.addSelectable(
            addButton(text: "SpecimenAgeAdult".localized(), iconName: nil),
            data: .adult
        )

        ageSelectionController.addSelectable(
            addButton(text: "SpecimenAgeYoung".localized(), iconName: nil),
            data: .young
        )

        captionLabel.text = "SpecimenAgeTitle".localized()
        ageSelectionController.isEnabled = false

        ageSelectionController.animationContainerView = buttonContainer
        ageSelectionController.onSelectionChanged = { [weak self] age in
            self?.dispatchValueChanged(
                eventDispatcher: self?.eventDispatcher,
                value: age
            ) { eventDispatcher, fieldId, age in
                eventDispatcher.dispatchAgeChanged(fieldId: fieldId, value: age)
            }
        }
    }

    override func fieldWasBound(field: AgeField<FieldId>) {
        captionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
        if (!field.settings.readOnly && eventDispatcher != nil) {
            ageSelectionController.isEnabled = true
        } else {
            ageSelectionController.isEnabled = false
            if (!field.settings.readOnly) {
                print("No event dispatcher, displaying field \(field.id_) in disabled mode!")
            }
        }
        ageSelectionController.select(data: field.age)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: AgeEventDispatcher?

        init(eventDispatcher: AgeEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(AgeFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! AgeFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
