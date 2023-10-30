import Foundation
import MaterialComponents
import RiistaCommon

class MetsahallitusPermitCell: UITableViewCell {
    static let reuseIdentifier = "MetsahallitusPermitCell"

    private static let languageProvider = CurrentLanguageProvider()

    /**
     * A listener for the cell actions.
     */
    weak var listener: MetsahallitusPermitActionListener?

    private lazy var permitTypeAndIdentifierLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            fontWeight: .semibold,
            textAlignment: .left,
            numberOfLines: 0
        )
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var permitAreaCodeAndNameLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            textColor: UIColor.applicationColor(Primary)
        )
        return label
    }()

    private lazy var permitNameLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium
        )
        return label
    }()

    private lazy var permitPeriodLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            textAlignment: .right
        )
        return label
    }()

    /**
     * The bound permit if any.
     */
    private weak var boundPermit: CommonMetsahallitusPermit?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(permit: CommonMetsahallitusPermit) {
        let permitType = permit.permitType.localizedWithFallbacks(
            languageProvider: Self.languageProvider
        ) ?? "MetsahallitusPermitCardTitle".localized()

        permitTypeAndIdentifierLabel.setTextAllowingOrphanLines(text: "\(permitType), \(permit.permitIdentifier)")

        if let areaName = permit.areaName.localizedWithFallbacks(languageProvider: Self.languageProvider) {
            permitAreaCodeAndNameLabel.text = "\(permit.areaNumber) \(areaName)"
        } else {
            permitAreaCodeAndNameLabel.text = "\(permit.areaNumber)"
        }

        permitNameLabel.text = permit.permitName.localizedWithFallbacks(languageProvider: Self.languageProvider)
        permitPeriodLabel.text = permit.formattedPeriodDates


        boundPermit = permit
    }

    private func commonInit() {
        let contentCard = MDCCard()
        contentView.addSubview(contentCard)
        contentCard.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(6)
        }

        // detect cell clicks using a view that is bottommost in the subview stack
        let viewPermitButton = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                self?.requestViewPermit()
            }
            background.roundedCorners = .allCorners()
            background.cornerRadius = contentCard.cornerRadius
        }
        contentCard.addSubview(viewPermitButton)
        viewPermitButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentCard.addSubview(permitTypeAndIdentifierLabel)
        contentCard.addSubview(permitAreaCodeAndNameLabel)
        contentCard.addSubview(permitNameLabel)
        contentCard.addSubview(permitPeriodLabel)

        permitTypeAndIdentifierLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        permitAreaCodeAndNameLabel.snp.makeConstraints { make in
            make.leading.leading.trailing.equalTo(permitTypeAndIdentifierLabel)
            make.top.equalTo(permitTypeAndIdentifierLabel.snp.bottom).offset(8)
        }

        permitNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(permitAreaCodeAndNameLabel)
            make.top.equalTo(permitAreaCodeAndNameLabel.snp.bottom).offset(8)
        }

        permitPeriodLabel.snp.makeConstraints { make in
            make.firstBaseline.equalTo(permitNameLabel)
            make.trailing.equalTo(permitAreaCodeAndNameLabel)
            make.leading.greaterThanOrEqualTo(permitNameLabel)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    private func requestViewPermit() {
        if let permit = boundPermit, let listener = self.listener {
            listener.onViewMetsahallitusPermit(permit: permit)
        } else {
            print("No bound permit / listener, cannot requestViewPermit")
        }
    }
}
