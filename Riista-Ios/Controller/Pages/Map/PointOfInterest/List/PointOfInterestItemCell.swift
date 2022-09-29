import Foundation
import RiistaCommon

protocol PointOfInterestItemCellListener: AnyObject {
    func onPointOfInterestClicked(item: PoiListItem.PoiItem)
}

class PointOfInterestItemCell: UITableViewCell {
    static let reuseIdentifier = "PointOfInterestItemCell"

    private static let stringProvider = LocalizedStringProvider()

    private lazy var itemTextAndDescriptionLabel: LabelAndIcon = {
        let label = LabelAndIcon()
        // font gets configured by attributed text
        label.label.numberOfLines = 1
        label.labelAlignment = .trailing
        label.spacingBetweenLabelAndIcon = 8
        label.iconSize = CGSize(width: 18, height: 18)
        label.iconImage = UIImage(named: "arrow_forward")?.withRenderingMode(.alwaysTemplate)
        label.iconTintColor = UIColor.applicationColor(Primary)
        return label
    }()

    private lazy var typeLabel: UILabel = UILabel().configure(for: .label)

    weak var listener: PointOfInterestItemCellListener?
    private var boundItem: PoiListItem.PoiItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(poiItem: PoiListItem.PoiItem) {
        let textAndDescription: NSAttributedString
        if let description = poiItem.description_ {
            textAndDescription = "\(poiItem.text): ".toAttributedString(textAttributesForIds)
                .appending(description.toAttributedString())
        } else {
            textAndDescription = poiItem.text.toAttributedString(textAttributesForDescription)
        }

        itemTextAndDescriptionLabel.label.attributedText = textAndDescription
        self.boundItem = poiItem
    }

    private func handleClicked() {
        if let listener = self.listener, let item = self.boundItem {
            listener.onPointOfInterestClicked(item: item)
        } else {
            print("cannot notify about POI item click event, no listener / group item")
        }
    }

    private func commonInit() {
        // detect cell clicks using a view that is bottommost in the subview stack
        let clickDetectorButton = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                self?.handleClicked()
            }
        }
        contentView.addSubview(clickDetectorButton)
        contentView.addSubview(itemTextAndDescriptionLabel)

        clickDetectorButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        itemTextAndDescriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView.layoutMarginsGuide).inset(24)
            make.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
    }
}


fileprivate let textAttributesForIds = [
    NSAttributedString.Key.font : UIFont.appFont(for: .label, fontWeight: .semibold)
]

fileprivate let textAttributesForDescription = [
    NSAttributedString.Key.font : UIFont.appFont(for: .label, fontWeight: .regular)
]
