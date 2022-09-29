import Foundation
import SnapKit
import RiistaCommon

fileprivate let BORDER_WIDTH: CGFloat = 4
fileprivate let BOTTOM_ARROW_IMAGE = UIImage(named: "arrow_drop_down")?.withRenderingMode(.alwaysTemplate)

// Note: markers are probably rendered as images and those can possibly be cached on disk
// -> ensure cache is either memory only or clear the cache if colors are changed!
fileprivate let MARKER_COLORS: [PointOfInterestType : UIColor] = [
    PointOfInterestType.sightingPlace : UIColor(hex: 0x0040D8),
    PointOfInterestType.feedingPlace : UIColor(hex: 0xF5B705),
    PointOfInterestType.mineralLick : UIColor(hex: 0x454540)
]

fileprivate let MARKER_COLOR_OTHER = UIColor(hex: 0xB800D8)

class PointOfInterestMarkerView: OverlayStackView {

    class MarkerData {
        let poiGroupVisibleId: Int32
        let poiLocationVisibleId: Int32
        let pointOfInterestType: PointOfInterestType?

        lazy var identifier: String = {
            let typeString = pointOfInterestType?.rawBackendEnumValue ?? ""
            return "\(poiGroupVisibleId)-\(poiLocationVisibleId)-\(typeString)"
        }()

        init(poiGroupVisibleId: Int32, poiLocationVisibleId: Int32, pointOfInterestType: PointOfInterestType?) {
            self.poiGroupVisibleId = poiGroupVisibleId
            self.poiLocationVisibleId = poiLocationVisibleId
            self.pointOfInterestType = pointOfInterestType
        }
    }

    private lazy var label: LabelWithPadding = {
        let label = LabelWithPadding().configure(for: .label)
        label.backgroundColor = .white
        label.roundedCorners = CACornerMask.allCorners()
        label.cornerRadius = 6
        label.layer.borderWidth = BORDER_WIDTH
        label.layer.borderColor = UIColor.red.cgColor
        label.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)

        // don't allow growing
        label.setContentHuggingPriority(.required, for: .horizontal)

        return label
    }()

    private let showBottomArrow: Bool

    private lazy var bottomArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BOTTOM_ARROW_IMAGE
        // don't respect aspect ratio in this case as we want to have
        // a full control over the size of the image
        imageView.contentMode = .scaleToFill
        imageView.isHidden = !showBottomArrow

        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }

        return imageView
    }()

    init(showBottomArrow: Bool = true) {
        self.showBottomArrow = showBottomArrow
        super.init(frame: .zero)
        setupView()
    }

    required init(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }

    func configureValues(markerData: MarkerData) {
        label.text = "\(markerData.poiGroupVisibleId)-\(markerData.poiLocationVisibleId)"

        let color = MARKER_COLORS[markerData.pointOfInterestType ?? .other] ?? MARKER_COLOR_OTHER
        bottomArrowImageView.tintColor = color
        label.layer.borderColor = color.cgColor
    }

    private func setupView() {
        axis = .vertical
        alignment = .center

        // ignore frame, use only constraints
        translatesAutoresizingMaskIntoConstraints = false

        addView(label)
        addView(bottomArrowImageView)

        label.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }
}

extension PointOfInterest {
    func toMarkerData() -> PointOfInterestMarkerView.MarkerData {
        PointOfInterestMarkerView.MarkerData(
            poiGroupVisibleId: group.visibleId,
            poiLocationVisibleId: poiLocation.visibleId,
            pointOfInterestType: group.type.value
        )
    }
}

extension PoiLocationViewModel {
    func toMarkerData() -> PointOfInterestMarkerView.MarkerData {
        PointOfInterestMarkerView.MarkerData(
            poiGroupVisibleId: groupVisibleId,
            poiLocationVisibleId: visibleId,
            pointOfInterestType: groupType.value
        )
    }
}
