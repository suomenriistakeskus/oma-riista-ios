import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.selectDuration


class SelectDurationFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, SelectDurationField<FieldId>>,
    SelectSingleStringViewControllerDelegate {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var navigationControllerProvider: ProvidesNavigationController? = nil
    private weak var eventDispatcher: HoursAndMinutesEventDispatcher? = nil
    private let stringProvider = LocalizedStringProvider()


    // wrap other views inside of a button in order to get click events
    private let containerButton = UIButton()
    override var containerView: UIView {
        return containerButton
    }

    var isEnabled: Bool {
        get {
            containerButton.isEnabled
        }
        set(enabled) {
            containerButton.isEnabled = enabled
            updateEnabledIndication()
        }
    }

    private let label = LabelView()
    private let valueLabel: UILabel = {
        UILabel().configure(
            for: .inputValue,
            textColor: UIColor.applicationColor(GreyDark)
        )
    }()

    private let lineUnderValue: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.applicationColor(TextPrimary)
        return line
    }()

    private let arrowImageView: UIImageView = {
        let arrow = UIImageView()
        arrow.image = UIImage(named: "arrow_forward")?.withRenderingMode(.alwaysTemplate)
        arrow.tintColor = UIColor.applicationColor(Primary)
        return arrow
    }()


    override func createSubviews(for container: UIView) {
        containerButton.addSubview(label)
        containerButton.addSubview(valueLabel)
        containerButton.addSubview(lineUnderValue)
        containerButton.addSubview(arrowImageView)

        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().inset(4)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(label)
            make.top.equalTo(label.snp.bottom).offset(2)
            make.trailing.equalTo(arrowImageView.snp.leading).inset(2)
            // if the value is empty (i.e. ""), its height will become 0 and thus
            // the line will not be displayed similarly always
            // -> force the height to be larger. This value should also introduce small
            //    padding between label and value.
            make.height.greaterThanOrEqualTo(30).priority(999)
        }

        lineUnderValue.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalTo(valueLabel)
            make.trailing.equalTo(arrowImageView)
            make.top.equalTo(valueLabel.snp.bottom)
            make.bottom.equalToSuperview().inset(4)
        }

        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            // same height and value as in RiistaValueListButton.xib
            make.height.equalTo(18)
            make.width.equalTo(12)
        }

        containerButton.addTarget(self, action: #selector(onClicked), for: .touchUpInside)
    }

    override func fieldWasBound(field: SelectDurationField<FieldId>) {
        if let labelText = field.settings.label {
            label.text = labelText
            label.required = field.settings.requirementStatus.isVisiblyRequired()
            label.isHidden = false
        } else {
            label.isHidden = true
        }

        if (!field.settings.readOnly && field.possibleValues.count > 1) {
            isEnabled = (self.navigationControllerProvider != nil && self.eventDispatcher != nil)
            if (!isEnabled) {
                print("Displaying SelectStringFieldCell as read-only since there is no eventDispatcher / navController!")
            }
        } else {
            isEnabled = false
        }

        valueLabel.text = field.value.formatHoursAndMinutesString(
            stringProvider: stringProvider,
            zeroMinutesStringId: field.settings.zeroMinutesStringId
        )
    }

    @objc private func onClicked() {
        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot handle click")
            return
        }
        guard let field = boundField else {
            print("No field, cannot handle click")
            return
        }

        let controller = SelectSingleStringViewController()

        let values: [StringWithId] = field.possibleValues.map { hoursAndMinutes in
            let formattedValue = hoursAndMinutes.formatHoursAndMinutesString(
                stringProvider: stringProvider,
                zeroMinutesStringId: field.settings.zeroMinutesStringId
            )

            return StringWithId(string: formattedValue, id: Int64(hoursAndMinutes.toTotalMinutes()))
        }
        controller.setValues(values: values)
        controller.delegate = self
        controller.title = field.settings.label

        navigationController.pushViewController(controller, animated: true)
    }

    func onStringSelected(string: SelectSingleStringViewController.SelectableString) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: string
        ) { eventDispatcher, fieldId, string in
            let result = HoursAndMinutes(minutes: Int32(string.id))
            eventDispatcher.dispatchHoursAndMinutesChanged(fieldId: fieldId, value: result)
        }
    }

    private func updateEnabledIndication() {
        if (isEnabled) {
            arrowImageView.tintColor = UIColor.applicationColor(Primary)
        } else {
            arrowImageView.tintColor = UIColor.applicationColor(GreyMedium)
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        private weak var navigationControllerProvider: ProvidesNavigationController? = nil
        private weak var eventDispatcher: HoursAndMinutesEventDispatcher? = nil

        init(navigationControllerProvider: ProvidesNavigationController?,
             eventDispatcher: HoursAndMinutesEventDispatcher?
        ) {
            super.init(cellType: CELL_TYPE)
            self.navigationControllerProvider = navigationControllerProvider
            self.eventDispatcher = eventDispatcher
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(SelectDurationFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! SelectDurationFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
