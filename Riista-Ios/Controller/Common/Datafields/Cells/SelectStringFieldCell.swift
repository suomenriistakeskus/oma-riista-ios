import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.selectString


class SelectStringFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, StringListField<FieldId>>,
    SelectSingleStringViewControllerDelegate,
    SelectStringViewControllerDelegate {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var navigationControllerProvider: ProvidesNavigationController? = nil
    private weak var eventDispatcher: StringWithIdEventDispatcher? = nil

    private lazy var selectView: SelectStringView = {
        let view = SelectStringView()
        view.onClicked = { [weak self] in
            self?.onClicked()
        }
        return view
    }()

    override var containerView: UIView {
        return selectView
    }

    var isEnabled: Bool {
        get {
            selectView.isEnabled
        }
        set(enabled) {
            selectView.isEnabled = enabled
        }
    }

    override func createSubviews(for container: UIView) {
        // nop, but needed since superview will crash otherwise
    }

    override func fieldWasBound(field: StringListField<FieldId>) {
        if let labelText = field.settings.label {
            selectView.label.text = labelText
            selectView.label.required = field.settings.requirementStatus.isVisiblyRequired()
            selectView.label.isHidden = false
        } else {
            selectView.label.isHidden = true
        }

        let selectedValues = field.selected ?? []
        let hasSelectableValue = field.values.count > 1 || (field.values.count == 1 && selectedValues.isEmpty)

        if (!field.settings.readOnly && hasSelectableValue) {
            isEnabled = (self.navigationControllerProvider != nil && self.eventDispatcher != nil)
            if (!isEnabled) {
                print("Displaying SelectStringFieldCell as read-only since there is no eventDispatcher / navController!")
            }
        } else {
            isEnabled = false
        }

        var valueText: String?
        if let multiModeChooseText = field.settings.multiModeChooseText {
            valueText = multiModeChooseText
        } else {
            valueText = field.values
                .filter { selectedValues.contains(KotlinLong(value: $0.id)) }
                .map { $0.string }
                .joined(separator: ", ")
        }
        selectView.valueLabel.text = valueText ?? ""
    }

    private func onClicked() {
        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot handle click")
            return
        }
        guard let field = boundField else {
            print("No field, cannot handle click")
            return
        }

        if (field.settings.preferExternalViewForSelection || field.settings.mode == .multi) {
            launchSelectStringInExternalView(navigationController: navigationController, field: field)
        } else {
            launchDefaultStringSelection(navigationController: navigationController, field: field)
        }
    }

    private func launchSelectStringInExternalView(
        navigationController: UINavigationController,
        field: StringListField<FieldId>
    ) {
        let allValues: [StringWithId]
        if (!field.detailedValues.isEmpty) {
            allValues = field.detailedValues
        } else {
            allValues = field.values
        }

        let controller = SelectStringViewController(
            mode: field.settings.mode,
            allValues: allValues,
            selectedValues: field.selected ?? []
        )

        controller.delegate = self
        if let externalViewConfiguration = field.settings.externalViewConfiguration {
            controller.title = externalViewConfiguration.title
            controller.filterEnabled = externalViewConfiguration.filterEnabled
            controller.filterLabelText = externalViewConfiguration.filterLabelText
            controller.filterTextHint = externalViewConfiguration.filterTextHint
        } else {
            controller.title = selectView.label.text
        }

        navigationController.pushViewController(controller, animated: true)
    }

    private func launchDefaultStringSelection(
        navigationController: UINavigationController,
        field: StringListField<FieldId>
    ) {
        // todo: drop down for small amount of selectable strings
        let controller = SelectSingleStringViewController()

        controller.delegate = self
        controller.title = selectView.label.text
        if (!field.detailedValues.isEmpty) {
            controller.setValues(values: field.detailedValues)
        } else {
            controller.setValues(values: field.values)
        }
        navigationController.pushViewController(controller, animated: true)
    }

    func onStringSelected(string: SelectSingleStringViewController.SelectableString) {
        let result = StringWithId(string: string.value, id: string.id)
        onStringsSelected(selecteStrings: [result])
    }

    func onStringsSelected(selecteStrings: [StringWithId]) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: selecteStrings
        ) { eventDispatcher, fieldId, string in
            eventDispatcher.dispatchStringWithIdChanged(fieldId: fieldId, value: selecteStrings)
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        private weak var navigationControllerProvider: ProvidesNavigationController? = nil
        private weak var eventDispatcher: StringWithIdEventDispatcher? = nil

        init(navigationControllerProvider: ProvidesNavigationController?,
             eventDispatcher: StringWithIdEventDispatcher?
        ) {
            super.init(cellType: CELL_TYPE)
            self.navigationControllerProvider = navigationControllerProvider
            self.eventDispatcher = eventDispatcher
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(SelectStringFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! SelectStringFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
