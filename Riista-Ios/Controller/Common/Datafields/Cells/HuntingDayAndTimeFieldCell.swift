import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.huntingDayAndTime

class HuntingDayAndTimeFieldCell<FieldId : DataFieldId>: BaseDateAndTimeCell<FieldId, HuntingDayAndTimeField<FieldId>>,
                                                         SelectGroupHuntingDayViewControllerListener {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var huntingGroupProvider: HuntingGroupTargetProvider?
    private weak var huntingDayEventDispatcher: HuntingDayIdEventDispatcher?
    private weak var localTimeEventDispatcher: LocalTimeEventDispatcher?
    weak var navigationControllerProvider: ProvidesNavigationController?

    override func fieldWasBound(field: HuntingDayAndTimeField<FieldId>) {
        bindLabel(label: field.settings.label,
                  visiblyRequired: field.settings.requirementStatus.isVisiblyRequired())

        if (!field.settings.readOnly && huntingDayEventDispatcher != nil && localTimeEventDispatcher != nil) {
            dateAndTimeView.isDateEnabled = !field.settings.readOnlyDate
            dateAndTimeView.isTimeEnabled = !field.settings.readOnlyTime
        } else {
            dateAndTimeView.isEnabled = false
            if (!field.settings.readOnly) {
                print("No event dispatcher, displaying field \(field.id_) in disabled mode!")
            }
        }

        if (field.huntingDayId != nil) {
            dateAndTimeView.dateButton.dateAndTime = field.dateAndTime.toFoundationDate()
        } else {
            dateAndTimeView.dateButton.valueLabel.text = "Select".localized()
        }
        dateAndTimeView.timeButton.dateAndTime = field.dateAndTime.toFoundationDate()
    }

    override func onDateButtonClicked() {
        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot launch day selection")
            return
        }
        guard let huntingGroupTarget = huntingGroupProvider?.huntingGroupTarget else {
            print("No hunting group, cannot launch day selection")
            return
        }

        let preferredHuntingDayDate = boundField?.dateAndTime.date

        let viewController = SelectGroupHuntingDayViewController(
            huntingGroupTarget: huntingGroupTarget,
            preferredHuntingDayDate: preferredHuntingDayDate
        )
        viewController.listener = self
        navigationController.pushViewController(viewController, animated: true)
    }

    func onHuntingDaySelected(huntingDayId: GroupHuntingDayId) {
        dispatchValueChanged(
            eventDispatcher: huntingDayEventDispatcher,
            value: huntingDayId
        ) { eventDispatcher, fieldId, huntingDayId in
            eventDispatcher.dispatchHuntingDayChanged(fieldId: fieldId, value: huntingDayId)
        }
    }

    override func onTimeButtonClicked() {
        showTimePicker()
    }

    private func showTimePicker() {
        guard let currentDate = boundField?.dateAndTime.toFoundationDate() else {
            print("No initial date for displaying picker")
            return
        }

        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot show selection controller")
            return
        }

        navigationController.showDatePicker(datePickerMode: .time,
                                            currentDate: currentDate) { [weak self] date in
            self?.dispatchChangedTime(date: date)
        }
    }

    private func dispatchChangedTime(date: Foundation.Date) {
        dispatchValueChanged(
            eventDispatcher: localTimeEventDispatcher,
            value: date.toLocalDateTime().time
        ) { eventDispatcher, fieldId, localTime in
            eventDispatcher.dispatchLocalTimeChanged(fieldId: fieldId, value: localTime)
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        private weak var navigationControllerProvider: ProvidesNavigationController?
        private weak var huntingGroupProvider: HuntingGroupTargetProvider?
        private weak var huntingDayEventDispatcher: HuntingDayIdEventDispatcher?
        private weak var localTimeEventDispatcher: LocalTimeEventDispatcher?


        init(navigationControllerProvider: ProvidesNavigationController?,
             huntingGroupProvider: HuntingGroupTargetProvider?,
             huntingDayEventDispatcher: HuntingDayIdEventDispatcher?,
             localTimeEventDispatcher: LocalTimeEventDispatcher?) {
            self.navigationControllerProvider = navigationControllerProvider
            self.huntingGroupProvider = huntingGroupProvider
            self.huntingDayEventDispatcher = huntingDayEventDispatcher
            self.localTimeEventDispatcher = localTimeEventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(HuntingDayAndTimeFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! HuntingDayAndTimeFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.huntingGroupProvider = huntingGroupProvider
            cell.huntingDayEventDispatcher = huntingDayEventDispatcher
            cell.localTimeEventDispatcher = localTimeEventDispatcher

            return cell
        }
    }
}
