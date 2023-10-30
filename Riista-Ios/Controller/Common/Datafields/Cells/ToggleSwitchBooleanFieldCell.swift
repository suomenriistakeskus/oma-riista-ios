import Foundation
import SnapKit
import RiistaCommon
import UIKit

fileprivate let CELL_TYPE = DataFieldCellType.toggleSwitch

class ToggleSwitchBooleanFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, BooleanField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: BooleanEventDispatcher?

    private(set) lazy var toggleView: ToggleView = {
        ToggleView(labelText: "")
    }()

    private(set) lazy var descriptionLabel: UILabel = {
        UILabel().configure(
            for: .label,
            numberOfLines: 0
        )
    }()

    override func createSubviews(for container: UIView) {
        container.addSubview(toggleView)
        toggleView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        toggleView.onToggled = { [weak self] value in
            self?.dispatchValueChanged(
                eventDispatcher: self?.eventDispatcher,
                value: value
            ) { eventDispatcher, fieldId, value in
                eventDispatcher.dispatchBooleanChanged(fieldId: fieldId, value: value)
            }
        }

        container.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalTo(toggleView.label)
            make.top.equalTo(toggleView.snp.bottom)
        }
    }

    override func fieldWasBound(field: BooleanField<FieldId>) {
        if let labelText = field.settings.label {
            toggleView.labelText = labelText
        }

        toggleView.isToggledOn = field.value?.boolValue ?? false

        descriptionLabel.text = field.settings.text
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: BooleanEventDispatcher?

        init(eventDispatcher: BooleanEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ToggleSwitchBooleanFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ToggleSwitchBooleanFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
