import Foundation
import SnapKit
import RiistaCommon

class BaseDateAndTimeCell<FieldId : DataFieldId, FieldType : DataField<FieldId>>: TypedDataFieldCell<FieldId, FieldType> {

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

    private(set) lazy var dateAndTimeView: DateAndTimeView = {
        let dateAndTimeView = DateAndTimeView()
        dateAndTimeView.dateButton.onClicked = { [weak self] in
            self?.onDateButtonClicked()
        }
        dateAndTimeView.timeButton.onClicked = { [weak self] in
            self?.onTimeButtonClicked()
        }

        dateAndTimeView.snp.makeConstraints { make in
            // set a slightly lower priority for height constraint as that solves initial load
            // constraint issue when DateAndTimeView is displayed in UITableView
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        return dateAndTimeView
    }()

    override var containerView: UIView {
        return topLevelContainer
    }

    override var internalTopPadding: CGFloat { return 8 }
    override var internalBottomPadding: CGFloat { return 8 }

    weak var navigationControllerProvider: ProvidesNavigationController?

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
        container.addArrangedSubview(dateAndTimeView)
    }

    func bindLabel(label: String?, visiblyRequired: Bool) {
        if let label = label {
            captionLabel.text = label
            captionLabel.required = visiblyRequired
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }
    }

    func onDateButtonClicked() {
        // nop, should subclass
    }

    func onTimeButtonClicked() {
        // nop, should subclass
    }

    func showDatePicker(datePickerMode: UIDatePicker.Mode,
                        currentDate: Foundation.Date,
                        minDate: Foundation.Date? = nil,
                        maxDate: Foundation.Date? = nil,
                        onPicked: @escaping (Foundation.Date) -> Void) {
        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No NavigationController, cannot show selection controller")
            return
        }

        let selectAction = RMAction<UIDatePicker>(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"),
            style: .done
        ) { controller in
            onPicked(controller.contentView.date)
        }

        let cancelAction = RMAction<UIDatePicker>(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"),
            style: .default)
        { controller in
            // nop
        }

        guard let dateSelectionViewController: RMDateSelectionViewController = RMDateSelectionViewController(
            style: .default,
            select: selectAction,
            andCancel: cancelAction
        ) else {
            print("Failed to create RMDateSelectionViewController")
            return
        }

        dateSelectionViewController.datePicker.apply({ datepicker in
            datepicker.date = currentDate
            datepicker.locale = RiistaSettings.locale()
            datepicker.timeZone = RiistaDateTimeUtils.finnishTimezone()
            datepicker.minimumDate = minDate
            datepicker.maximumDate = maxDate
            datepicker.datePickerMode = datePickerMode
            if #available(iOS 13.4, *) {
                datepicker.preferredDatePickerStyle = .wheels
            }
        })

        navigationController.present(dateSelectionViewController, animated: true, completion: nil)
    }
}
