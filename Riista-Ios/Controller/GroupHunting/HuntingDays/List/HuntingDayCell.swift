import Foundation
import MaterialComponents
import RiistaCommon

class HuntingDayCell: UITableViewCell {
    static let reuseIdentifier = "HuntingDayCell"

    /**
     * A listener for the cell actions.
     */
    weak var listener: HuntingDayActionListener?

    private lazy var dateLabel: LabelAndIcon = {
        let label = LabelAndIcon()
        label.labelAlignment = .trailing
        label.spacingBetweenLabelAndIcon = 4
        label.iconSize = CGSize(width: 18, height: 18)
        label.iconImage = UIImage(named: "arrow_forward")?.withRenderingMode(.alwaysTemplate)
        label.iconTintColor = UIColor.applicationColor(Primary)
        return label
    }()

    private lazy var hasProposedEntriesIndicator: UIView = {
        let label = LabelWithPadding()
        label.font = UIFont.appFont(fontSize: .xLarge)
        label.textColor = UIColor.applicationColor(Destructive)
        label.text = "*"
        label.isHidden = true
        // use bottom edgeInsets to push star a bit upwards
        // - stackview has .center alignment in order to align correctly with other labels on the cell
        label.edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        return label
    }()

    private lazy var dateLabelAndProposedIndicator: OverlayStackView = {
        let container = OverlayStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.addArrangedSubview(dateLabel)
        container.addArrangedSubview(hasProposedEntriesIndicator)
        return container
    }()

    private lazy var harvestCountLabel: LabelAndIcon = {
        let labelAndIcon = LabelAndIcon()
        labelAndIcon.labelAlignment = .leading
        labelAndIcon.label.textAlignment = .right
        labelAndIcon.spacingBetweenLabelAndIcon = 4
        labelAndIcon.iconSize = CGSize(width: 18, height: 18)
        labelAndIcon.iconImage = UIImage(named: "harvest")?.withRenderingMode(.alwaysTemplate)
        labelAndIcon.iconTintColor = UIColor.applicationColor(Primary)
        labelAndIcon.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(50)
        }
        return labelAndIcon
    }()

    private lazy var observationCountLabel: LabelAndIcon = {
        let labelAndIcon = LabelAndIcon()
        labelAndIcon.labelAlignment = .leading
        labelAndIcon.label.textAlignment = .right
        labelAndIcon.spacingBetweenLabelAndIcon = 4
        labelAndIcon.iconSize = CGSize(width: 18, height: 18)
        labelAndIcon.iconImage = UIImage(named: "observation")?.withRenderingMode(.alwaysTemplate)
        labelAndIcon.iconTintColor = UIColor.applicationColor(Primary)
        labelAndIcon.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(50)
        }
        return labelAndIcon
    }()

    private lazy var editHuntingDayButton: MaterialButton = {
        let button = MaterialButton()
        AppTheme.shared.setupTextButtonTheme(button: button)
        button.setImage(UIImage(named: "edit"), for: .normal)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        button.isHidden = true
        button.onClicked = { [weak self] in
            self?.requestEditHuntingDay()
        }
        return button
    }()

    private lazy var createHuntingDayButton: MaterialButton = {
        let button = MaterialButton()
        AppTheme.shared.setupTextButtonTheme(button: button)
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        button.isHidden = true
        button.onClicked = { [weak self] in
            self?.requestCreateHuntingDay()
        }
        return button
    }()

    /**
     * The bound hunting day viewmodel if any.
     */
    private weak var boundHuntingDayViewModel: HuntingDayViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(huntingDayViewModel: HuntingDayViewModel) {
        dateLabel.text = huntingDayViewModel.huntingDay.startDateTime.toFoundationDate().formatDateOnly()
        harvestCountLabel.text = "\(huntingDayViewModel.harvestCount)"
        observationCountLabel.text = "\(huntingDayViewModel.observationCount)"
        hasProposedEntriesIndicator.isHidden = !huntingDayViewModel.hasProposedEntries
        editHuntingDayButton.isHidden = !huntingDayViewModel.canEditHuntingDay
        createHuntingDayButton.isHidden = !huntingDayViewModel.canCreateHuntingDay

        boundHuntingDayViewModel = huntingDayViewModel
    }

    private func commonInit() {
        // detect cell clicks using a view that is bottommost in the subview stack
        let viewHuntingDayButton = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                self?.requestViewHuntingDay()
            }
        }
        contentView.addSubview(viewHuntingDayButton)

        // the actual visible views / data
        let viewContainer = OverlayStackView()
        viewContainer.axis = .horizontal
        viewContainer.distribution = .fill
        viewContainer.alignment = .center
        viewContainer.spacing = 8
        contentView.addSubview(viewContainer)

        viewHuntingDayButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(viewContainer)
        }
        viewContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(1) // inset by separator height
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight - 1).priority(999)
        }

        viewContainer.addView(dateLabelAndProposedIndicator)
        viewContainer.addSpacer(size: 8, canShrink: true, canExpand: true)
        viewContainer.addView(harvestCountLabel)
        viewContainer.addView(observationCountLabel)
        viewContainer.addView(editHuntingDayButton)
        viewContainer.addView(createHuntingDayButton)

        let separator = SeparatorView(orientation: .horizontal)
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.bottom.equalToSuperview()
        }
    }

    private func requestViewHuntingDay() {
        if let huntingDayViewModel = boundHuntingDayViewModel, let listener = self.listener {
            listener.onViewHuntingDay(viewModel: huntingDayViewModel)
        } else {
            print("No bound hunting day / listener, cannot requestViewHuntingDay")
        }
    }

    private func requestEditHuntingDay() {
        if let huntingDayViewModel = boundHuntingDayViewModel, let listener = self.listener {
            listener.onEditHuntingDay(huntingDayId: huntingDayViewModel.huntingDay.id)
        } else {
            print("No bound hunting day / listener, cannot requestEditHuntingDay")
        }
    }

    private func requestCreateHuntingDay() {
        if let huntingDayViewModel = boundHuntingDayViewModel, let listener = self.listener {
            listener.onCreateHuntingDay(preferredDate: huntingDayViewModel.huntingDay.id.date)
        } else {
            print("No bound hunting day / listener, cannot requestCreateHuntingDay")
        }
    }
}
