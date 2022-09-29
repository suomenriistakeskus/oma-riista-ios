import Foundation
import RiistaCommon

protocol PointOfInterestGroupCellListener: AnyObject {
    func onPointOfInterestGroupClicked(groupItem: PoiListItem.PoiGroupItem)
}

class PointOfInterestGroupCell: UITableViewCell {
    static let reuseIdentifier = "PointOfInterestGroupCell"

    private static let stringProvider = LocalizedStringProvider()

    private lazy var nameLabel: LabelAndIcon = {
        let label = LabelAndIcon()
        label.label.configure(
            for: .label,
            fontWeight: .semibold,
            numberOfLines: 2
        )
        label.labelAlignment = .trailing
        label.spacingBetweenLabelAndIcon = 6
        label.iconSize = CGSize(width: 18, height: 18)
        label.iconImage = UIImage(named: "arrow_forward")?.withRenderingMode(.alwaysTemplate)
        label.iconTintColor = UIColor.applicationColor(Primary)
        return label
    }()

    private lazy var typeLabel: UILabel = {
        let label = UILabel().configure(for: .label)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    weak var listener: PointOfInterestGroupCellListener?
    private var boundGroupItem: PoiListItem.PoiGroupItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(groupItem: PoiListItem.PoiGroupItem) {
        nameLabel.text = groupItem.text
        typeLabel.text = groupItem.type.localized(stringProvider: Self.stringProvider)

        let indicatorRotation: CGFloat
        if (groupItem.expanded) {
            indicatorRotation = .pi / 2.0
        } else {
            indicatorRotation = 0
        }
        // todo: consider animations here (would be nice!)
        // - requires rebind support from tableview controller though so let's implement it later
        //   if necessary..
        nameLabel.iconImageView.layer.transform = CATransform3DMakeRotation(indicatorRotation, 0, 0, 1)

        self.boundGroupItem = groupItem
    }

    private func handleClicked() {
        if let listener = self.listener, let item = self.boundGroupItem {
            listener.onPointOfInterestGroupClicked(groupItem: item)
        } else {
            print("cannot notify about POI group click event, no listener / group item")
        }
    }

    private func commonInit() {
        // detect cell clicks using a view that is bottommost in the subview stack
        let toggleGroupExpandButton = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                self?.handleClicked()
            }
        }
        contentView.addSubview(toggleGroupExpandButton)

        // the actual visible views / data
        let viewContainer = OverlayStackView()
        viewContainer.axis = .horizontal
        viewContainer.distribution = .fill
        viewContainer.alignment = .center
        viewContainer.spacing = 8
        contentView.addSubview(viewContainer)

        toggleGroupExpandButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        viewContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }

        viewContainer.addView(nameLabel)
        viewContainer.addSpacer(size: 8, canShrink: true, canExpand: true)
        viewContainer.addView(typeLabel)
    }
}
