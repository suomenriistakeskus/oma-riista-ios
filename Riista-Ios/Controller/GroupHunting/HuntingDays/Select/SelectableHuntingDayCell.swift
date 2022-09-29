import Foundation
import MaterialComponents
import RiistaCommon

fileprivate let colorForegroundNormal: UIColor = UIColor.applicationColor(TextPrimary)!
fileprivate let colorBackgroundNormal: UIColor = UIColor.applicationColor(ViewBackground)!
fileprivate let colorForegroundSelected: UIColor = .white
fileprivate let colorBackgroundSelected: UIColor = UIColor.applicationColor(Primary)!


protocol SelectableHuntingDayCellListener: AnyObject {
    func onRequestSelectHuntingDay(huntingDayId: GroupHuntingDayId)
}

class SelectableHuntingDayCell: UITableViewCell {
    static let reuseIdentifier = "SelectableHuntingDayCell"

    private var huntingDayIsSelected: Bool = false {
        didSet {
            updateColors()
        }
    }

    private lazy var container: OverlayView = {
        let container = OverlayView()
        container.addSubview(startDateLabel)
        container.addSubview(lineBetweenDates)
        container.addSubview(endDateLabel)

        lineBetweenDates.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        startDateLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(lineBetweenDates.snp.leading)
        }
        endDateLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(lineBetweenDates.snp.trailing)
        }

        return container
    }()

    private lazy var startDateLabel: UILabel = createDateLabel()
    private lazy var endDateLabel: UILabel = createDateLabel()

    private lazy var lineBetweenDates: OverlayView = {
        let line = OverlayView()
        line.backgroundColor = colorBackgroundNormal
        line.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(2)
        }
        return line
    }()

    private func updateColors() {
        let foregroundColor: UIColor
        let backgroundColor: UIColor
        if (huntingDayIsSelected) {
            foregroundColor = colorForegroundSelected
            backgroundColor = colorBackgroundSelected
        } else {
            foregroundColor = colorForegroundNormal
            backgroundColor = colorBackgroundNormal
        }

        container.backgroundColor = backgroundColor
        startDateLabel.textColor = foregroundColor
        endDateLabel.textColor = foregroundColor
        lineBetweenDates.backgroundColor = foregroundColor
    }

    private func createDateLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = colorForegroundNormal
        label.textAlignment = .center
        return label
    }

    /**
     * The bound hunting day viewmodel if any.
     */
    private var huntingDayId: GroupHuntingDayId?
    weak var listener: SelectableHuntingDayCellListener?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(huntingDayViewModel: SelectableHuntingDayViewModel) {
        startDateLabel.text = huntingDayViewModel.startDateTime.toFoundationDate().formatDateAndTime()
        endDateLabel.text = huntingDayViewModel.endDateTime.toFoundationDate().formatDateAndTime()
        huntingDayIsSelected = huntingDayViewModel.selected

        huntingDayId = huntingDayViewModel.huntingDayId
    }

    private func requestSelectHuntingDay() {
        if let huntingDayId = self.huntingDayId {
            listener?.onRequestSelectHuntingDay(huntingDayId: huntingDayId)
        } else {
            print("No hunting day id, cannot select!")
        }
    }

    private func commonInit() {
        // detect cell clicks using a button that is bottommost in the subview stack
        let selectHuntingDayButton = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                self?.requestSelectHuntingDay()
            }
        }
        contentView.addSubview(selectHuntingDayButton)

        contentView.addSubview(container)
        let separator = SeparatorView(orientation: .horizontal)
        contentView.addSubview(separator)

        container.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview()
            make.bottom.equalTo(separator.snp.top)
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
        separator.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalTo(container)
        }

        selectHuntingDayButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(container)
        }
    }
}
