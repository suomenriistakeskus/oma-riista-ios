import Foundation
import MaterialComponents
import RiistaCommon

class NoHuntingControlEventsCell: UITableViewCell {
    static let reuseIdentifier = "NoHuntingControlEventsCell"

    var text: String? {
        get {
            noContentsLabel.text
        }
        set(text) {
            noContentsLabel.text = text
        }
    }

    private lazy var noContentsLabel: UILabel = {
        UILabel().configure(
            for: .label,
            textColor: UIColor.applicationColor(GreyDark),
            textAlignment: .center,
            numberOfLines: 0
        )
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let topLevelContainer = UIView()
        contentView.addSubview(topLevelContainer)

        topLevelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(80).priority(999)
        }

        topLevelContainer.addSubview(noContentsLabel)
        noContentsLabel.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
        }
    }
}
