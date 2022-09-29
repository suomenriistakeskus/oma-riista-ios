import Foundation
import MaterialComponents
import RiistaCommon

protocol ViewHuntingControlEventListener: AnyObject {
    func onViewHuntingControlEvent(eventId: Int64)
}

class HuntingControlEventCell: UITableViewCell {
    static let reuseIdentifier = "HuntingControlEventCell"

    private lazy var dateLabel: UILabel = {
        UILabel().configure(
            fontSize: .small,
            fontWeight: .semibold
        )
    }()

    private lazy var titleLabel: UILabel = {
        UILabel().configure(
            fontSize: .mediumLarge,
            fontWeight: .regular,
            numberOfLines: 2
        )
    }()

    private lazy var modifiedIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "upload")
        imageView.isHidden = true

        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return imageView
    }()

    private weak var boundEvent: SelectHuntingControlEvent?
    weak var listener: ViewHuntingControlEventListener?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(event: SelectHuntingControlEvent) {
        dateLabel.text = event.date.toFoundationDate().formatDateOnly()
        titleLabel.text = event.title

        modifiedIndicator.isHidden = !event.modified

        boundEvent = event
    }

    private func viewHuntingControlEvent() {
        guard let eventId = boundEvent?.id else {
            print("No bound event, cannot view")
            return
        }

        listener?.onViewHuntingControlEvent(eventId: eventId)
    }

    private func commonInit() {
        let viewHuntingControlEventButton = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                self?.viewHuntingControlEvent()
            }
        }
        contentView.addSubview(viewHuntingControlEventButton)

        // the actual visible views / data
        let topLevelContainer = OverlayView()
        contentView.addSubview(topLevelContainer)

        viewHuntingControlEventButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(topLevelContainer)
        }

        topLevelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(1) // inset by separator height
            make.height.greaterThanOrEqualTo(AppConstants.UI.ButtonHeightSmall - 1).priority(999)
        }

        topLevelContainer.addSubview(dateLabel)
        topLevelContainer.addSubview(titleLabel)
        topLevelContainer.addSubview(modifiedIndicator)

        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalTo(modifiedIndicator.snp.leading).offset(-4)
            make.top.equalToSuperview().inset(8)
        }

        modifiedIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(dateLabel)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(dateLabel.snp.bottom)
            make.bottom.lessThanOrEqualToSuperview().inset(4)
        }

        let separator = SeparatorView(orientation: .horizontal)
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.bottom.equalToSuperview()
        }
    }
}
