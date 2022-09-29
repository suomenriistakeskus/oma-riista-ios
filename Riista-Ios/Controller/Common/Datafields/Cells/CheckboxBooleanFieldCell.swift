import Foundation
import SnapKit
import RiistaCommon
import UIKit

fileprivate let CELL_TYPE = DataFieldCellType.checkbox

class CheckboxBooleanFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, BooleanField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: BooleanEventDispatcher?

    private(set) lazy var buttonContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }()

    private(set) lazy var button: CheckBoxButton = {
        let button = CheckBoxButton()
        return button
    }()

    override var containerView: UIView {
        return buttonContainer
    }

    override func createSubviews(for container: UIView) {
        guard let container = container as? UIStackView else {
            fatalError("Expected UIStackView as container!")
        }

        container.addArrangedSubview(button)
        button.onSelectionChanged = { [weak self] value in
            self?.dispatchValueChanged(
                eventDispatcher: self?.eventDispatcher,
                value: value
            ) { eventDispatcher, fieldId, value in
                eventDispatcher.dispatchBooleanChanged(fieldId: fieldId, value: value)
            }
        }

    }

    override func fieldWasBound(field: BooleanField<FieldId>) {
        if let labelText = field.settings.label {
            button.setTitle(labelText, for: .normal)
        }
        button.isSelected = field.value?.boolValue ?? false
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: BooleanEventDispatcher?

        init(eventDispatcher: BooleanEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(CheckboxBooleanFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! CheckboxBooleanFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
