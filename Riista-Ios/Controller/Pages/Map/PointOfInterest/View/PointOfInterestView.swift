import Foundation
import Async
import RiistaCommon


class PointOfInterestView: UIView {

    private lazy var mapView: RiistaMapView = {
        let mapView = RiistaMapView()
        mapView.setMapType(type: MmlMapType)
        mapView.addMapLayer(areaType: .Seura, zIndex: 10)
        mapView.settings.setAllGesturesEnabled(false)

        poiLocationMarker.map = mapView

        mapView.addSubview(coordinatesLabel)
        coordinatesLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }

        return mapView
    }()

    private lazy var coordinatesLabel: MapLabel = {
        let label = MapLabel()
        label.textAlignment = .left
        label.numberOfLines = 1
        label.edgeInsets = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
        return label
    }()

    private lazy var poiLocationMarker: GMSMarker = {
        let marker = GMSMarker()
        // don't set icon / iconView as we try to use cached image instead of iconView if possible
        return marker
    }()

    private lazy var poiLocationMarkerView: PointOfInterestMarkerView = PointOfInterestMarkerView()

    private lazy var returnToMapButton: CustomizableMaterialButton = {
        let button = CustomizableMaterialButton(
            config: CustomizableMaterialButtonConfig { config in
                config.titleTextColor = UIColor.applicationColor(Primary)
                config.titleTextTransform = { text in
                    text // don't transform
                }
                config.titleTextAlignment = .left
                config.titleNumberOfLines = 2 // probably fits 1..
                config.horizontalSpacing = 12
            }
        )

        button.setTitle("PointOfInterestCenterAndReturnToMap".localized(), for: .normal)
        button.leadingIcon = UIImage(named: "arrow_left")
        button.updateLayoutMargins(top: 2, left: 0, bottom: 2)

        button.onClicked = { [weak self] in
            self?.displayPointOfInterestOnMap()
        }

        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return button
    }()

    let locationIdAndGroupDescriptionlabel = UILabel().configure(fontSize: .large, numberOfLines: 0)

    let locationDescriptionlabel = UILabel().configure(fontSize: .medium, numberOfLines: 0)


    weak var navigationControllerProvider: ProvidesNavigationController?

    private var pointOfInterest: PoiLocationViewModel?

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func updateValues(pointOfInterest: PoiLocationViewModel) {
        let location = pointOfInterest.location.toCoordinate()
        mapView.camera = GMSCameraPosition(
            latitude: location.latitude,
            longitude: location.longitude,
            zoom: AppConstants.Map.DefaultZoomToLevel
        )
        poiLocationMarker.position = location

        let markerData = pointOfInterest.toMarkerData()
        PointOfInterestMarkerImageCache.shared.getOrRenderMarkerIcon(for: markerData) { [weak self] icon in
            guard let self = self else { return }
            if let icon = icon {
                self.poiLocationMarker.icon = icon
            } else {
                self.fallbackToDisplayingIconView(for: markerData)
            }
        }

        coordinatesLabel.text = String(format: "CoordinatesFormat".localized(),
                                       pointOfInterest.location.latitude,
                                       pointOfInterest.location.longitude)

        locationIdAndGroupDescriptionlabel.attributedText =
            "\(pointOfInterest.groupVisibleId)-\(pointOfInterest.visibleId): "
            .toAttributedString(textAttributesLocationId).appending(
                (pointOfInterest.groupDescription ?? "").toAttributedString(textAttributesGroupDescription)
            )

        locationDescriptionlabel.text = pointOfInterest.description_


        self.pointOfInterest = pointOfInterest
    }

    private func fallbackToDisplayingIconView(for markerData: PointOfInterestMarkerView.MarkerData) {
        poiLocationMarker.tracksViewChanges = true
        poiLocationMarker.iconView = poiLocationMarkerView

        poiLocationMarkerView.configureValues(markerData: markerData)

        // don't track view changes after a while. This allows the marker view to update itself and
        // googlemaps to display updated marker.
        // - by not tracking the CPU usage is lowered dramatically (90% -> 2% in simulator)
        Async.main(after: 0.1) {
            self.poiLocationMarker.tracksViewChanges = false
        }
    }

    private func displayPointOfInterestOnMap() {
        guard let navigationController = navigationControllerProvider?.navigationController else {
            print("No navigation controller, cannot return to map")
            return
        }

        if let centerMapAtLocationViewController: CanCenterMapAtLocation = navigationController.findViewController() {
            if let pointOfInterest = self.pointOfInterest {
                centerMapAtLocationViewController.centerMapAtLocation(
                    location: pointOfInterest.location.toCoordinate(),
                    zoomLevel: AppConstants.Map.DefaultZoomToLevel
                )
            }

            // assume map is the one that is able to center the map
            navigationController.popToViewControllerWithType(
                target: centerMapAtLocationViewController,
                animated: true
            )
        } else {
            // cannot do much as we don't have map support (we don't know how far in the backstack the map is)
            navigationController.popViewController(animated: true)
        }
    }

    private func setupView() {
        addSubview(mapView)

        // container for other than map views
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .leading

        addSubview(container)

        mapView.snp.makeConstraints { make in
            make.height.equalTo(mapView.snp.width).multipliedBy(0.66).priority(999)
            make.top.leading.trailing.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        container.addView(returnToMapButton, spaceAfter: 4)
        container.addView(locationIdAndGroupDescriptionlabel, spaceAfter: 8)
        container.addView(locationDescriptionlabel)
    }
}


fileprivate let textAttributesLocationId = [
    NSAttributedString.Key.font : UIFont.appFont(fontSize: .large, fontWeight: .semibold)
]

fileprivate let textAttributesGroupDescription = [
    NSAttributedString.Key.font : UIFont.appFont(fontSize: .large, fontWeight: .regular)
]
