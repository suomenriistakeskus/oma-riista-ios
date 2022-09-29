import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.date

class DateCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, DateField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private(set) lazy var topLevelContainer: UIStackView = {
        // use a vertical stackview for containing caption + buttons
        // -> allows hiding caption if necessary
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0
        container.alignment = .fill
        return container
    }()

    private lazy var captionLabelContainer: UIView = {
        let container = UIView()
        container.addSubview(captionLabel)
        captionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DateAndTimeView.defaultSpacing)
            make.top.bottom.equalToSuperview()
        }
        return container
    }()

    private(set) lazy var captionLabel: LabelView = {
        let labelView = LabelView()
        return labelView
    }()

    private lazy var dateButton: DateOrTimeButton = {
        let button = DateOrTimeButton(mode: .date)
        button.onClicked = { [weak self] in
            self?.onDateButtonClicked()
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

        container.addArrangedSubview(captionLabelContainer)
        container.addArrangedSubview(dateButton)
    }

    weak var eventDispatcher: LocalDateEventDispatcher?
    weak var navigationControllerProvider: ProvidesNavigationController?

    override func fieldWasBound(field: DateField<FieldId>) {
        if let label = field.settings.label {
            captionLabel.text = label
            captionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }

        let hasEventDispatcher = eventDispatcher != nil
        dateButton.isEnabled = !field.settings.readOnly && hasEventDispatcher

        dateButton.dateAndTime = field.date.toFoundationDate()
    }

    func onDateButtonClicked() {
        guard let currentDate = boundField?.date.toFoundationDate() else {
            print("No initial date for displaying picker")
            return
        }

        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot show selection controller")
            return
        }

        navigationController.showDatePicker(
            datePickerMode: .date,
            currentDate: currentDate,
            minDate: boundField?.settings.minDate?.toFoundationDate(),
            maxDate: boundField?.settings.maxDate?.toFoundationDate()
        ) { [weak self] date in
            self?.dispatchChangedDate(date: date)
        }
    }

    private func dispatchChangedDate(date: Foundation.Date) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: date.toLocalDate()
        ) { eventDispatcher, fieldId, localDate in
            eventDispatcher.dispatchLocalDateChanged(fieldId: fieldId, value: localDate)
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        weak var navigationControllerProvider: ProvidesNavigationController?
        weak var eventDispatcher: LocalDateEventDispatcher?

        init(navigationControllerProvider: ProvidesNavigationController?, eventDispatcher: LocalDateEventDispatcher?) {
            self.navigationControllerProvider = navigationControllerProvider
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(DateCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! DateCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
