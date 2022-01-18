import Foundation
import SnapKit
import RiistaCommon

fileprivate let colorAccepted = UIColor.applicationColor(Primary)!
fileprivate let colorProposed = UIColor.applicationColor(Destructive)!
fileprivate let colorRejected = UIColor.applicationColor(GreyDark)!

class MapDiaryEntryCell: UITableViewCell {

    var diaryEntryIconImage: UIImage {
        fatalError("Should subclass MapDiaryEntryCell")
    }

    var itemType: MapClusteredItemViewModel.ItemType {
        fatalError("itemType needs to be overridden in subclass")
    }

    override var reuseIdentifier: String? {
        itemType.name
    }

    private lazy var speciesNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelMedium, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private lazy var pointOfTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelSmall, fontWeight: .regular)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelSmall, fontWeight: .regular)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = diaryEntryIconImage.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = iconTintColor
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return imageView
    }()

    private(set) var iconTintColor: UIColor = colorAccepted {
        didSet {
            if (iconTintColor != oldValue) {
                iconImageView.tintColor = iconTintColor
            }
        }
    }

    private let speciesNameResolver = SpeciesInformationResolver()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // add clickable background directly to contentView
        let background = ClickableCellBackground()
        background.onClicked = { [weak self] in
            self?.onClicked()
        }
        let topLevelContainer = OverlayView()

        contentView.addSubview(background)
        contentView.addSubview(topLevelContainer)
        contentView.addSeparatorToBottom(respectLayoutMarginsGuide: true)

        background.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(topLevelContainer)
        }

        topLevelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(1) // inset(1) == separator
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight + 1).priority(999)
        }

        let textContainer = OverlayStackView()
        textContainer.axis = .vertical
        textContainer.alignment = .fill

        textContainer.addView(createContainerForSpeciesNameAndDateLabels())
        textContainer.addView(descriptionLabel)

        topLevelContainer.addSubview(iconImageView)
        topLevelContainer.addSubview(textContainer)
        iconImageView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        textContainer.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
        }
    }

    func bindValues(speciesCode: Int32,
                    pointOfTime: LocalDateTime,
                    acceptStatus: AcceptStatus,
                    description: String?) {
        let locale = RiistaSettings.locale()

        speciesNameLabel.text = speciesNameResolver.getSpeciesName(speciesCode: speciesCode)?.uppercased(with: locale)
        pointOfTimeLabel.text = pointOfTime.toFoundationDate().formatDateAndTime()
        iconTintColor = getImageTintColor(acceptStatus: acceptStatus)
        descriptionLabel.text = description ?? ""
    }

    func onClicked() {
        print("Cell clicked, should probably handle it")
    }

    private func getImageTintColor(acceptStatus: AcceptStatus) -> UIColor {
        switch acceptStatus {
        case .accepted:     return colorAccepted
        case .proposed:     return colorProposed
        case .rejected:     return colorRejected
        default:
            print("Unexpected acceptStatus \(acceptStatus) observed!")
            return colorAccepted
        }
    }

    private func createContainerForSpeciesNameAndDateLabels() -> UIView {
        let container = OverlayView()
        container.addSubview(speciesNameLabel)
        container.addSubview(pointOfTimeLabel)

        speciesNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(pointOfTimeLabel.snp.leading)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        pointOfTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.firstBaseline.equalTo(speciesNameLabel.snp.firstBaseline)
        }

        return container
    }
}
