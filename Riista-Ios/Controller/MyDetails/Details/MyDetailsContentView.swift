import Foundation
import SnapKit


class MyDetailsContentView: TwoColumnStackView {

    private lazy var nameRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsName")
    private lazy var dateOfBirthRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsDateOfBirth")
    private lazy var homeMunicipalityRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsHomeMunicipality")
    private lazy var addressRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsAddress")

    private(set) lazy var huntingCardButton: CardButton = createButton(labelKey: "MyDetailsTitleHuntingLicense")
    private(set) lazy var shootingTestsButton: CardButton = createButton(labelKey: "MyDetailsTitleShootingTests")
    private(set) lazy var mhPermitsButton: CardButton = createButton(labelKey: "MetsahallitusPermitsTitle")
    private(set) lazy var occupationsButton: CardButton = createButton(labelKey: "MyDetailsAssignmentsTitle")
    private(set) lazy var clubMembershipsButton: CardButton = createButton(labelKey: "MyDetailsClubMembershipsTitle")
    private(set) lazy var trainingsButton: CardButton = createButton(labelKey: "MyDetailsTrainingsTitle")

    override init() {
        super.init()
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func updateValues(user: UserInfo) {
        nameRow.valueLabel.text = "\(user.firstName ?? "") \(user.lastName ?? "")"
        dateOfBirthRow.valueLabel.text = user.birthDate.formatDateOnly()
        if let homeMunicipality = user.homeMunicipality[RiistaSettings.language()] {
            homeMunicipalityRow.valueLabel.text = homeMunicipality as? String
        } else {
            homeMunicipalityRow.valueLabel.text = user.homeMunicipality["fi"] as? String
        }
        if let userAddress = user.address {
            addressRow.valueLabel.text = String(format: "%@\n%@ %@\n%@",
                                                 userAddress.streetAddress ?? "",
                                                 userAddress.postalCode ?? "",
                                                 userAddress.city ?? "",
                                                 userAddress.country ?? "")
        } else {
            addressRow.valueLabel.text = nil
        }
    }


    private func commonInit() {
        spacing = 8

        let userDetailsHeadlineLabel = UILabel()
        userDetailsHeadlineLabel.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        userDetailsHeadlineLabel.textColor = UIColor.applicationColor(TextPrimary)
        userDetailsHeadlineLabel.text = "MyDetailsTitlePerson".localized()
        addArrangedSubview(userDetailsHeadlineLabel)

        addRow(row: nameRow)
        addRow(row: dateOfBirthRow)
        addRow(row: homeMunicipalityRow)
        addRow(row: addressRow)

        addSpacer(size: 12)

        addView(huntingCardButton)
        addView(shootingTestsButton)
        addView(mhPermitsButton)
        addView(occupationsButton)
        addView(clubMembershipsButton)
        addView(trainingsButton)
    }

    private func createUserDetailsLabel(labelKey: String) -> TitleAndValueRow {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.appFont(for: .label, fontWeight: .regular)
        titleLabel.textColor = UIColor.applicationColor(TextPrimary)
        titleLabel.text = labelKey.localized()
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        valueLabel.textColor = UIColor.applicationColor(TextPrimary)
        valueLabel.textAlignment = .left
        valueLabel.numberOfLines = 0
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        return TitleAndValueRow(titleLabel: titleLabel, valueLabel: valueLabel)
    }

    private func createButton(labelKey: String) -> CardButton {
        let button = CardButton(title: labelKey.localized())
        button.contentHorizontalAlignment = .left
        button.iconSize = CGSize(width: 24, height: 24)

        return button
    }
}
