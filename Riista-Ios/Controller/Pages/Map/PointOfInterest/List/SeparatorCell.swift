import Foundation

class SeparatorCell: UITableViewCell {
    static let reuseIdentifier = "SeparatorCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // use custom view as separator in order to allow using 999 as height constraint priority
        // - otherwise we'd have to alter SeparatorView constraint priority and that may have
        //   unwanted side effects elsewhere
        let separator = UIView()
        separator.backgroundColor = SeparatorView.separatorColor

        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(1).priority(999)
        }
    }
}
