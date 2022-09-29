import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.gender

class GenderFieldCell<FieldId : DataFieldId>: SelectableButtonCell<FieldId, GenderField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: GenderEventDispatcher?

    private let genderSelectionController = RadioButtonGroup<RiistaCommon.Gender>()
    private lazy var unknownGenderButton: SelectableMaterialButton = {
        return addButton(text: "SpecimenGenderUnknown".localized(), iconName: nil)
    }()

    override func createSubviews(for container: UIView) {
        super.createSubviews(for: container)

        genderSelectionController.addSelectable(
            addButton(text: "SpecimenGenderFemale".localized(), iconName: "female"),
            data: .female
        )

        genderSelectionController.addSelectable(
            addButton(text: "SpecimenGenderMale".localized(), iconName: "male"),
            data: .male
        )

        genderSelectionController.addSelectable(
            unknownGenderButton,
            data: .unknown
        )

        captionLabel.text = "SpecimenGenderTitle".localized()

        genderSelectionController.animationContainerView = buttonContainer
        genderSelectionController.onSelectionChanged = { [weak self] gender in
            self?.dispatchValueChanged(
                eventDispatcher: self?.eventDispatcher,
                value: gender
            ) { eventDispatcher, fieldId, gender in
                eventDispatcher.dispatchGenderChanged(fieldId: fieldId, value: gender)
            }
        }
    }

    override func fieldWasBound(field: GenderField<FieldId>) {
        captionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
        if (!field.settings.readOnly && eventDispatcher != nil) {
            genderSelectionController.isEnabled = true
        } else {
            genderSelectionController.isEnabled = false
            if (!field.settings.readOnly) {
                print("No event dispatcher, displaying field \(field.id_) in disabled mode!")
            }
        }
        unknownGenderButton.isHidden = !field.settings.showUnknown
        genderSelectionController.select(data: field.gender)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: GenderEventDispatcher?

        init(eventDispatcher: GenderEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(GenderFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! GenderFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
