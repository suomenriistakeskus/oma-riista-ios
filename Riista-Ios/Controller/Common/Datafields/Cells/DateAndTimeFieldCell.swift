import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.dateAndTime

class DateAndTimeFieldCell<FieldId : DataFieldId>: BaseDateAndTimeCell<FieldId, DateAndTimeField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    weak var eventDispatcher: LocalDateTimeEventDispatcher?
    weak var navigationControllerProvider: ProvidesNavigationController?

    override func fieldWasBound(field: DateAndTimeField<FieldId>) {
        bindLabel(label: field.settings.label,
                  visiblyRequired: field.settings.requirementStatus.isVisiblyRequired())

        let hasEventDispatcher = eventDispatcher != nil
        dateAndTimeView.isDateEnabled = !field.settings.readOnlyDate && hasEventDispatcher
        dateAndTimeView.isTimeEnabled = !field.settings.readOnlyTime && hasEventDispatcher

        dateAndTimeView.dateAndTime = field.dateAndTime.toFoundationDate()
    }

    override func onDateButtonClicked() {
        showDatePicker(datePickerMode: .date)
    }

    override func onTimeButtonClicked() {
        showDatePicker(datePickerMode: .time)
    }

    private func showDatePicker(datePickerMode: UIDatePicker.Mode) {
        guard let currentDate = boundField?.dateAndTime.toFoundationDate() else {
            print("No initial date for displaying picker")
            return
        }

        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot show selection controller")
            return
        }

        navigationController.showDatePicker(
            datePickerMode: datePickerMode,
            currentDate: currentDate,
            minDate: boundField?.settings.minDateTime?.toFoundationDate(),
            maxDate: boundField?.settings.maxDateTime?.toFoundationDate()
        ) { [weak self] date in
            self?.dispatchChangedDate(date: date)
        }
    }

    private func dispatchChangedDate(date: Foundation.Date) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: date.toLocalDateTime()
        ) { eventDispatcher, fieldId, localDateTime in
            eventDispatcher.dispatchLocalDateTimeChanged(fieldId: fieldId, value: localDateTime)
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        weak var navigationControllerProvider: ProvidesNavigationController?
        weak var eventDispatcher: LocalDateTimeEventDispatcher?

        init(navigationControllerProvider: ProvidesNavigationController?, eventDispatcher: LocalDateTimeEventDispatcher?) {
            self.navigationControllerProvider = navigationControllerProvider
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(DateAndTimeFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! DateAndTimeFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
