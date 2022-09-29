import Foundation
import SnapKit
import RiistaCommon


fileprivate let ITEM_TYPE: MapClusteredItemViewModel.ItemType = .pointOfInterest

protocol MapPointOfInterestCellClickHandler: AnyObject {
    func onPointOfInterestClicked(pointOfInterest: PointOfInterest)
}

class MapPointOfInterestCell: UITableViewCell {
    static let reuseIdentifier = ITEM_TYPE.name

    var itemType: MapClusteredItemViewModel.ItemType = ITEM_TYPE

    override var reuseIdentifier: String? {
        itemType.name
    }

    private lazy var markerRepresentationView: PointOfInterestMarkerView = {
        PointOfInterestMarkerView(showBottomArrow: false)
    }()

    private lazy var typeAndVisibleIdsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .left
        label.numberOfLines = 1

        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: .small, fontWeight: .regular)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .left
        label.numberOfLines = 1

        return label
    }()


    weak var clickHandler: MapPointOfInterestCellClickHandler?
    private var boundViewModel: MapPointOfInterestViewModel?

    private let localizedStringProvider = LocalizedStringProvider()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(viewModel: MapPointOfInterestViewModel) {
        let pointOfInterest = viewModel.pointOfInterest

        markerRepresentationView.configureValues(markerData: pointOfInterest.toMarkerData())

        let typeString = pointOfInterest.group.type.localized(stringProvider: localizedStringProvider)
        typeAndVisibleIdsLabel.text = "\(typeString): \(pointOfInterest.group.visibleId)-\(pointOfInterest.poiLocation.visibleId)"
        descriptionLabel.text = pointOfInterest.poiLocation.description_ ?? ""

        boundViewModel = viewModel
    }

    func onClicked() {
        guard let clickHandler = self.clickHandler else {
            print("No click handler, cannot handle point of interest click")
            return
        }
        guard let pointOfInterest = boundViewModel?.pointOfInterest else {
            print("No point of interest, cannot handle cell click")
            return
        }

        clickHandler.onPointOfInterestClicked(pointOfInterest: pointOfInterest)
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

        textContainer.addView(typeAndVisibleIdsLabel)
        textContainer.addView(descriptionLabel)

        topLevelContainer.addSubview(markerRepresentationView)
        topLevelContainer.addSubview(textContainer)

        markerRepresentationView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        textContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview() // in case shorter texs

            // always at least 64 pts from leading edge..
            make.leading.greaterThanOrEqualToSuperview().offset(64)

            // but still have a margin to marker view
            make.leading.greaterThanOrEqualTo(markerRepresentationView.snp.trailing).offset(8)
        }
    }
}
