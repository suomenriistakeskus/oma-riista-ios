import Foundation
import MaterialComponents
import RiistaCommon

class HuntingClubMembershipsHeaderCell: UITableViewCell {
    static let reuseIdentifier = "HuntingClubMembershipsHeaderCell"

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .header, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(header: HuntingClubViewModel.Header) {
        headerLabel.text = header.text
    }

    private func commonInit() {
        contentView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
    }
}
