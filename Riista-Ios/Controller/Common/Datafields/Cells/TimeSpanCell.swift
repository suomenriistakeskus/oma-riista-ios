import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.timeSpan

class TimeSpanCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, TimespanField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private(set) lazy var topLevelContainer: UIStackView = {
        // use a horizontal stackview for containing caption + button for both start and end time
        let container = UIStackView()
        container.distribution = .fillEqually
        container.alignment = .center
        container.spacing = DateAndTimeView.defaultSpacing
        return container
    }()

    private lazy var startCaptionLabelContainer: UIView = {
        let container = UIView()
        container.addSubview(startCaptionLabel)
        startCaptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DateAndTimeView.defaultSpacing)
            make.top.bottom.equalToSuperview()
        }
        return container
    }()

    private lazy var startCaptionLabel: LabelView = LabelView()

    private lazy var startTimeButton: DateOrTimeButton = {
        let button = DateOrTimeButton(mode: .time)
        button.onClicked = { [weak self] in
            self?.onStartTimeClicked()
        }

        return button
    }()
    
    private lazy var endCaptionLabelContainer: UIView = {
        let container = UIView()
        container.addSubview(endCaptionLabel)
        endCaptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DateAndTimeView.defaultSpacing)
            make.top.bottom.equalToSuperview()
        }
        return container
    }()

    private lazy var endCaptionLabel: LabelView = LabelView()

    private lazy var endTimeButton: DateOrTimeButton = {
        let button = DateOrTimeButton(mode: .time)
        button.onClicked = { [weak self] in
            self?.onEndTimeClicked()
        }

        return button
    }()

    override var containerView: UIView {
        return topLevelContainer
    }

    override var internalTopPadding: CGFloat { return 8 }
    override var internalBottomPadding: CGFloat { return 8 }


    override func addContainerViewToContentViewAndSpecifyConstraints(container: UIView) {
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            // date and timeview has internal spacing between leading edge and icon
            // -> take into account so that it aligns nicely when not clicked
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide).inset(-DateAndTimeView.defaultSpacing)
            topPaddingConstraint = make.top.equalToSuperview().constraint
            bottomPaddingConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    override func createSubviews(for container: UIView) {
        guard let container = container as? UIStackView else {
            fatalError("Expected UIStackView as container!")
        }

        container.addView(
            createContainerForLabelAndTime(
                label: startCaptionLabelContainer,
                timeButton: startTimeButton
            )
        )
        container.addView(
            createContainerForLabelAndTime(
                label: endCaptionLabelContainer,
                timeButton: endTimeButton
            )
        )
    }

    weak var eventDispatcher: LocalTimeEventDispatcher?
    weak var navigationControllerProvider: ProvidesNavigationController?

    override func fieldWasBound(field: TimespanField<FieldId>) {
        if let label = field.settings.startLabel {
            if (field.settings.readOnly) {
                // adjust to appear like read-only, single line cell
                startCaptionLabel.label.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
                startCaptionLabel.text = label.uppercased()
            } else {
                startCaptionLabel.label.configure(for: .label, fontWeight: .semibold)
                startCaptionLabel.text = label
            }
            startCaptionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
            startCaptionLabel.isHidden = false
        } else {
            startCaptionLabel.isHidden = true
        }

        if let label = field.settings.endLabel {
            if (field.settings.readOnly) {
                // adjust to appear like read-only, single line cell
                endCaptionLabel.label.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
                endCaptionLabel.text = label.uppercased()
            } else {
                endCaptionLabel.label.configure(for: .label, fontWeight: .semibold)
                endCaptionLabel.text = label
            }
            endCaptionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
            endCaptionLabel.isHidden = false
        } else {
            endCaptionLabel.isHidden = true
        }

        let hasEventDispatcher = eventDispatcher != nil
        startTimeButton.isEnabled = !field.settings.readOnly && hasEventDispatcher
        endTimeButton.isEnabled = !field.settings.readOnly && hasEventDispatcher

        if let startTime = field.startTime?.toFoundationDate() {
            startTimeButton.dateAndTime = startTime
        } else {
            startTimeButton.valueLabel.text = "Select".localized()
        }

        if let endTime = field.endTime?.toFoundationDate() {
            endTimeButton.dateAndTime = endTime
        } else {
            endTimeButton.valueLabel.text = "Select".localized()
        }
    }

    func onStartTimeClicked() {
        guard let navigationController = navigationControllerProvider?.navigationController,
              let field = boundField else {
            print("No NavigationController / bound field, cannot show selection controller for start time")
            return
        }

        navigationController.showDatePicker(
            datePickerMode: .time,
            currentDate: field.startTime?.toFoundationDate() ?? Date()
        ) { [weak self] date in
            self?.dispatchChangedDate(fieldId: field.startFieldId, date: date)
        }
    }

    func onEndTimeClicked() {
        guard let navigationController = navigationControllerProvider?.navigationController,
              let field = boundField else {
            print("No NavigationController / bound field, cannot show selection controller for end time")
            return
        }

        navigationController.showDatePicker(
            datePickerMode: .time,
            currentDate: field.endTime?.toFoundationDate() ?? Date()
        ) { [weak self] date in
            self?.dispatchChangedDate(fieldId: field.endFieldId, date: date)
        }
    }

    private func dispatchChangedDate(fieldId: FieldId, date: Foundation.Date) {
        dispatchValueChanged(
            fieldId: fieldId,
            eventDispatcher: eventDispatcher,
            value: date.toLocalTime()
        ) { eventDispatcher, fieldId, localTime in
            eventDispatcher.dispatchLocalTimeChanged(fieldId: fieldId, value: localTime)
        }
    }

    private func createContainerForLabelAndTime(label: UIView, timeButton: UIView) -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = 0

        container.addView(label)
        container.addView(timeButton)

        return container
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        weak var navigationControllerProvider: ProvidesNavigationController?
        weak var eventDispatcher: LocalTimeEventDispatcher?

        init(navigationControllerProvider: ProvidesNavigationController?, eventDispatcher: LocalTimeEventDispatcher?) {
            self.navigationControllerProvider = navigationControllerProvider
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(TimeSpanCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! TimeSpanCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
