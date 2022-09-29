import Foundation
import MaterialComponents
import RiistaCommon

class HuntingClubMembershipCell: UITableViewCell {
    static let reuseIdentifier = "HuntingClubMembershipCell"

    private lazy var clubNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        return label
    }()

    private lazy var clubNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .regular)
        label.textColor = UIColor.applicationColor(Primary)
        label.numberOfLines = 0
        return label
    }()

    /**
     * The bound hunting day viewmodel if any.
     */
    private var boundMembership: HuntingClubViewModel.HuntingClub?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(membership: HuntingClubViewModel.HuntingClub) {
        clubNumberLabel.text = String(format: "HuntingClubOccupationCode".localized(), membership.officialCode)
        clubNameLabel.text = membership.name
        boundMembership = membership

    }

    private func commonInit() {
        let viewContainer = OverlayStackView()
        viewContainer.axis = .vertical
        viewContainer.alignment = .fill
        viewContainer.spacing = 4
        contentView.addSubview(viewContainer)

        viewContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8 + 1) // inset by separator height
        }

        viewContainer.addArrangedSubview(clubNumberLabel)
        viewContainer.addArrangedSubview(clubNameLabel)

        let separator = SeparatorView(orientation: .horizontal)
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.bottom.equalToSuperview()
        }
    }
}
