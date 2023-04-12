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
        guard let currentDate = boundField?.dateAndTime else {
            print("No initial date for displaying picker")
            return
        }

        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot show selection controller")
            return
        }

        navigationController.showDatePicker(
            datePickerMode: datePickerMode,
            currentDate: currentDate.toFoundationDate(),
            minDate: boundField?.settings.minDateTime?.toFoundationDate(),
            maxDate: boundField?.settings.maxDateTime?.toFoundationDate()
        ) { [weak self] date in
            guard let self = self else { return }

            // in datePickerMode == .date the picked date may lose the time part of the value. For example when
            // - currentDate = 20-01-2023T15:00:00
            // - datePickerMode = .date
            // - minDate = nil
            // - maxDate = 20-01-2023T16:00:00
            //
            // picking date 21-01-2023 will cause the date to be 20-01-2023T00:00:00 as UI prevents picking
            // dates beyond maxDate. But for some reason it also loses the timepart of the date in the process.
            //
            // Combine the oldValue and picked date to form the newDateTime (also take min/max into account)
            guard let newDateTime = self.getUpdatedDateTime(
                pickedDateTime: date.toLocalDateTime(),
                datePickerMode: datePickerMode,
                initialDateTime: currentDate,
                minDateTime: self.boundField?.settings.minDateTime,
                maxDateTime: self.boundField?.settings.maxDateTime
            ) else {
                return
            }

            self.dispatchChangedDate(dateTime: newDateTime)
        }
    }

    fileprivate func getUpdatedDateTime(
        pickedDateTime: LocalDateTime,
        datePickerMode: UIDatePicker.Mode,
        initialDateTime: LocalDateTime,
        minDateTime: LocalDateTime?,
        maxDateTime: LocalDateTime?
    ) -> LocalDateTime? {
        var newDateTime: LocalDateTime
        switch datePickerMode {
        case .time:
            newDateTime = LocalDateTime(date: initialDateTime.date, time: pickedDateTime.time)
        case .date:
            newDateTime = LocalDateTime(date: pickedDateTime.date, time: initialDateTime.time)
        case .dateAndTime:
            newDateTime = pickedDateTime
        case .countDownTimer: fallthrough
        @unknown default:
            return nil
        }

        if let minDateTime = minDateTime {
            newDateTime = max(minDateTime, newDateTime)
        }

        if let maxDateTime = maxDateTime {
            newDateTime = min(newDateTime, maxDateTime)
        }

        return newDateTime
    }

    private func dispatchChangedDate(dateTime: LocalDateTime) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: dateTime
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
