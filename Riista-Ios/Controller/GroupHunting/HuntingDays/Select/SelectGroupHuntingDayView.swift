import Foundation
import UIKit
import MaterialComponents
import SnapKit
import RiistaCommon


class SelectGroupHuntingDayView: UIView {

    // MARK: Common callbacks + settings

    var onCreateHuntingDayButtonClicked: OnClicked?
    var onSelectButtonClicked: OnClicked?
    var onCancelButtonClicked: OnClicked?

    var canSelectHuntingDay: Bool = false {
        didSet {
            selectButton.isEnabled = canSelectHuntingDay
        }
    }


    // MARK: Views to be displayed when there are hunting days

    private(set) lazy var contentArea: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill

        container.addView(dateLabelsHeaderArea)
        container.addView(suggestedDayArea)
        container.addView(tableView)
        container.addView(bottomButtonsArea)

        return container
    }()

    private lazy var dateLabelsHeaderArea: UIView = {
        let container = UIStackView()
        container.axis = .horizontal
        container.distribution = .fillEqually
        container.alignment = .center

        container.addArrangedSubview(createDateLabel(text: "FilterStartDate".localized()))
        container.addArrangedSubview(createDateLabel(text: "FilterEndDate".localized()))

        container.addSeparatorToBottom()

        // the actual area so that we can have empty space at bottom
        let area = UIView()
        area.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return area
    }()

    private lazy var suggestedDayArea: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.applicationColor(Primary)

        container.addSubview(suggestedDayLabel)
        suggestedDayLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(12)
        }

        let createDayButton = MaterialButton()
        createDayButton.applyTextTheme(withScheme: MDCContainerScheme().apply { containerScheme in
            containerScheme.colorScheme = AppTheme.shared.colorSchemeInverted()
            containerScheme.typographyScheme = AppTheme.shared.createTypographyCheme()
        })
        createDayButton.setTitle("GroupHuntingAddHuntingDay".localized(), for: .normal)
        createDayButton.setImage(UIImage(named: "plus")?.withRenderingMode(.alwaysTemplate), for: .normal)
        createDayButton.setImageTintColor(.white, for: .normal)
        createDayButton.onClicked = { [weak self] in
            self?.onCreateHuntingDayButtonClicked?()
        }
        container.addSubview(createDayButton)
        createDayButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(12)
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
            make.top.equalTo(suggestedDayLabel.snp.bottom).offset(4)
        }

        let area = UIView()
        area.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }
        return area
    }()

    private lazy var suggestedDayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = .white
        label.text = "GroupHuntingSuggestedHuntingDay".localized()
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension

        return tableView
    }()

    // area for the buttons at the bottom of the screen
    private(set) lazy var bottomButtonsArea: UIView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = AppConstants.UI.DefaultEdgeInsets

        view.addArrangedSubview(cancelButton)
        view.addArrangedSubview(selectButton)
        view.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight + view.layoutMargins.top + view.layoutMargins.bottom)
        }

        let separator = SeparatorView(orientation: .horizontal)
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        return view
    }()

    private lazy var cancelButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyOutlinedTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        btn.setTitle("Cancel".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onCancelButtonClicked?()
        }
        return btn
    }()

    private lazy var selectButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle("Select".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onSelectButtonClicked?()
        }
        btn.isEnabled = canSelectHuntingDay
        return btn
    }()



    // MARK: Views to be displayed when there are NO hunting days

    private lazy var noContentArea: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.alignment = .fill
        stackview.spacing = 12

        stackview.addArrangedSubview(noContentLabel)
        stackview.addArrangedSubview(noContentCreateHuntingDayButton)
        stackview.isHidden = true
        return stackview
    }()

    private lazy var noContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var noContentCreateHuntingDayButton: MaterialButton = {
        let button = MaterialButton()
        AppTheme.shared.setupPrimaryButtonTheme(button: button)
        button.setTitle("GroupHuntingAddHuntingDay".localized(), for: .normal)
        button.onClicked = { [weak self] in
            self?.onCreateHuntingDayButtonClicked?()
        }
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight)
        }
        button.isHidden = true

        return button
    }()




    // MARK: public API

    func displayHuntingDays(suggestedHuntingDayDate: RiistaCommon.LocalDate?) {
        noContentArea.isHidden = true
        contentArea.isHidden = false
        tableView.isScrollEnabled = true

        if let suggestedHuntingDayText = formatSuggestedHuntingDayText(date: suggestedHuntingDayDate) {
            suggestedDayLabel.text = suggestedHuntingDayText
            suggestedDayArea.isHidden = false
        } else {
            suggestedDayArea.isHidden = true
        }
    }

    func showNoContentText(suggestedHuntingDayDate: RiistaCommon.LocalDate?,
                           fallbackText: String?,
                           canCreateHuntingDay: Bool) {
        noContentLabel.text = formatSuggestedHuntingDayText(date: suggestedHuntingDayDate) ?? fallbackText ?? ""
        noContentCreateHuntingDayButton.isHidden = !canCreateHuntingDay

        noContentArea.isHidden = false
        contentArea.isHidden = true
        tableView.isScrollEnabled = false
    }
    private func formatSuggestedHuntingDayText(date: LocalDate?) -> String? {
        guard let date = date else { return nil }

        let format = "GroupHuntingSuggestedHuntingDayForEntry".localized()
        return String(format: format, date.toFoundationDate().formatDateOnly())
    }



    // MARK: Init

    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubview(noContentArea)
        noContentArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        addSubview(contentArea)
        contentArea.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func createDateLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .center
        label.text = text
        return label
    }
}
