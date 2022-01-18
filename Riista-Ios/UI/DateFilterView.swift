import Foundation
import MaterialComponents
import SnapKit

fileprivate let spacing: CGFloat = 4

typealias OnDateChanged = (Date) -> Void

/**
 * A custom view providing possibility to filter between two dates.
 */
class DateFilterView: UIView {

    // MARK: Interface for viewcontroller / listener

    /**
     * Called when start date has been changed.
     */
    var onStartDateChanged: OnDateChanged?

    /**
     * Called when end date has been changed.
     */
    var onEndDateChanged: OnDateChanged?

    /**
     * The view controller that is displaying this view.
     */
    weak var presentingViewController: UIViewController?


    // MARK: Start date

    private lazy var startLabel: LabelView = {
        createLabel(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterStartDate"))
    }()

    var startDate: Date = Date() {
        didSet {
            startDateValueLabel.text = DatetimeUtil.dateToFormattedStringNoTime(date: startDate)
        }
    }

    private lazy var startDateValueLabel: UILabel = {
        createDateValueLabel(initialDate: startDate)
    }()

    private lazy var startDateButton: MaterialButton = {
        createDateButton(dateLabel: startDateValueLabel).apply { btn in
            btn.onClicked = onChangeStartDate
        }
    }()


    // MARK: End date

    private lazy var endLabel: LabelView = {
        createLabel(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterEndDate"))
    }()

    var endDate: Date = Date() {
        didSet {
            endDateValueLabel.text = DatetimeUtil.dateToFormattedStringNoTime(date: endDate)
        }
    }

    private lazy var endDateValueLabel: UILabel = {
        createDateValueLabel(initialDate: endDate)
    }()

    private lazy var endDateButton: MaterialButton = {
        createDateButton(dateLabel: endDateValueLabel).apply { btn in
            btn.onClicked = onChangeEndDate
        }
    }()


    // MARK: Allowed date range

    /**
     * The minimum start date.
     */
    var minStartDate: Date = Date()

    /**
     * The maximum end date.
     */
    var maxEndDate: Date = Date()


    // MARK: Constructors

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func onChangeStartDate() {
        changeDate(date: startDate, minDate: minStartDate, maxDate: endDate, onDateSelected: onStartDateChanged)
    }

    private func onChangeEndDate() {
        changeDate(date: endDate, minDate: startDate, maxDate: maxEndDate, onDateSelected: onEndDateChanged)
    }

    private func changeDate(date: Date, minDate: Date, maxDate: Date, onDateSelected: OnDateChanged?) {
        guard let onDateSelected = onDateSelected else {
            print("onDateSelected == nil")
            return
        }
        guard let viewController = self.presentingViewController else {
            print("No viewcontroller")
            return
        }

        let selectAction = RMAction<UIDatePicker>(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"),
            style: .done
        ) { controller in
            onDateSelected(controller.contentView.date)
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
            datepicker.date = date
            datepicker.locale = RiistaSettings.locale()
            datepicker.timeZone = RiistaDateTimeUtils.finnishTimezone()
            datepicker.minimumDate = minDate
            datepicker.maximumDate = maxDate
            datepicker.datePickerMode = .date
            if #available(iOS 13.4, *) {
                datepicker.preferredDatePickerStyle = .wheels
            }
        })

        viewController.present(dateSelectionViewController, animated: true, completion: nil)
    }

    private func setup() {
        backgroundColor = UIColor.applicationColor(ViewBackground)

        // wrap date labels and buttons into vertical stackviews and wrap stackviews
        // into horizontal stackview

        let startAndEndDateAreas = UIStackView().apply { stackView in
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.alignment = .center
            stackView.spacing = 4
            stackView.layoutMargins = UIEdgeInsets(
                top: 8,
                left: AppConstants.UI.DefaultHorizontalInset - spacing,
                bottom: 4,
                right: AppConstants.UI.DefaultHorizontalInset - spacing
            )
            stackView.isLayoutMarginsRelativeArrangement = true
        }
        addSubview(startAndEndDateAreas)
        startAndEndDateAreas.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let startDateArea = createLabelAndDateContainer()
        startAndEndDateAreas.addArrangedSubview(startDateArea)
        let endDateArea = createLabelAndDateContainer()
        startAndEndDateAreas.addArrangedSubview(endDateArea)

        startDateArea.addArrangedSubview(startLabel)
        startDateArea.addArrangedSubview(startDateButton)

        endDateArea.addArrangedSubview(endLabel)
        endDateArea.addArrangedSubview(endDateButton)
    }

    private func createLabelAndDateContainer() -> UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        return view
    }

    private func createDateButton(dateLabel: UILabel) -> MaterialButton {
        let button = MaterialButton()
        let containerScheme = MDCContainerScheme().apply { scheme in
            scheme.colorScheme = AppTheme.shared.colorScheme()
        }

        button.applyTextTheme(withScheme: containerScheme)

        // don't use buttons titleLabel / imageView as those are constrained by
        // the button and we want to position those elements differently.
        // -> Instead use custom UIImageView for the icon and given dateLabel as text label
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "calendar")
        button.addSubview(iconImageView)
        button.addSubview(dateLabel)

        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(spacing)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spacing)
        }

        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(AppConstants.UI.ButtonHeightSmall)
        }

        return button
    }

    func createLabel(text: String) -> LabelView {
        let label = LabelView()
        label.text = text
        label.layoutMargins = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        return label
    }

    private func createDateValueLabel(initialDate: Date) -> UILabel {
        let label = UILabel()
        label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelHuge)
        label.textColor = UIColor.applicationColor(Primary)
        label.textAlignment = .left
        label.text = DatetimeUtil.dateToFormattedStringNoTime(date: initialDate)
        return label
    }
}
