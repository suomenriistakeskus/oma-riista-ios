import Foundation
import SnapKit
import RiistaCommon
import GoogleMaps
import Async

fileprivate let CELL_TYPE = DataFieldCellType.location

class LocationFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, LocationField<FieldId>>,
    GMSMapViewDelegate,
    LocationSelectionListener {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var mapView: RiistaMapView = {
        let mapView = RiistaMapView()
        mapView.setMapType(type: MmlMapType)
        mapView.addMapLayer(areaType: .Seura, zIndex: 10)
        mapView.settings.setAllGesturesEnabled(false)
        mapView.delegate = self
        return mapView
    }()

    private lazy var coordinatesLabel: MapLabel = {
        let label = MapLabel()
        label.textAlignment = .left
        label.numberOfLines = 1
        label.edgeInsets = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
        return label
    }()

    private lazy var locationMarker: GMSMarker = {
        let marker = GMSMarker()
        marker.map = mapView
        marker.icon = UIImage(named: "map-pin-generic")
        return marker
    }()

    private lazy var unknownLocationOverlay: OverlayView = {
        let view = OverlayView()
        view.backgroundColor = .black.withAlphaComponent(0.6)
        view.isHidden = true

        view.addSubview(setupLocationButton)
        setupLocationButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight)
        }
        return view
    }()

    private lazy var setupLocationButton: MaterialButton = {
        let button = MaterialButton()
        button.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        button.setTitle("MapPageSetLocation".localized(), for: .normal)
        button.setImage(UIImage(named: "map_pin")?.withRenderingMode(.alwaysTemplate), for: .normal)
        // adjust image position slightly
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 8)
        button.onClicked = { [weak self] in
            self?.navigateToMap()
        }
        return button
    }()

    override var containerView: UIView {
        return mapView
    }

    private var mapExternalId: String? {
        didSet {
            if let externalId = mapExternalId, externalId != oldValue {
                // invert colors so that map won't become green but instead illegal
                // areas are highlighted
                mapView.configureMapLayer(
                    areaType: .Seura,
                    externalId: externalId,
                    invertLayerColors: true
                )
            }
        }
    }

    private weak var navigationControllerProvider: ProvidesNavigationController?
    private weak var locationEventDispatcher: LocationEventDispatcher?
    private weak var mapExternalIdProvider: MapExternalIdProvider?

    override func addContainerViewToContentViewAndSpecifyConstraints(container: UIView) {
        assert(container === mapView, "mapView not container")

        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            topPaddingConstraint = make.top.equalToSuperview().constraint
            bottomPaddingConstraint = make.bottom.equalToSuperview().constraint
            make.height.equalTo(mapView.snp.width).multipliedBy(0.66).priority(999)
        }
    }

    override func createSubviews(for container: UIView) {
        container.addSubview(coordinatesLabel)
        coordinatesLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }

        container.addSubview(unknownLocationOverlay)
        unknownLocationOverlay.snp.makeConstraints { make in
            // let overlay cover the whole map
            make.edges.equalToSuperview()
        }
    }

    override func fieldWasBound(field: LocationField<FieldId>) {
        // update map external every time field is bound
        mapExternalId = mapExternalIdProvider?.getMapExternalId()

        if let knownLocation = field.location as? CommonLocation.Known {
            showKnownLocation(knownLocation: knownLocation)
        } else {
            indicateUnknownLocation()
        }
    }

    private func showKnownLocation(knownLocation: CommonLocation.Known) {
        unknownLocationOverlay.isHidden = true
        coordinatesLabel.isHidden = false

        let coordinate = knownLocation.etrsLocation.toCoordinate()
        mapView.camera = GMSCameraPosition(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: AppConstants.Map.DefaultZoomToLevel
        )
        locationMarker.position = coordinate

        coordinatesLabel.text = String(format: "CoordinatesFormat".localized(),
                                       knownLocation.etrsLocation.latitude,
                                       knownLocation.etrsLocation.longitude)
    }

    private func indicateUnknownLocation() {
        coordinatesLabel.isHidden = true

        // Schedule displaying unknown location overlay using Async instead of using animation
        // delays. Animation delays may get cancelled (probably will!) if other cells decide
        // to request cell updates with setCellNeedsLayout(animateChanges: false)
        // - having animateChanges false seems to cancel animations / delays
        Async.main(after: 2) { [weak self] in
            self?.showUnknownLocationOverlayIfStillUnknownLocation()
        }

        mapView.camera = GMSCameraPosition(
            latitude: AppConstants.DefaultMapLocation.Latitude,
            longitude: AppConstants.DefaultMapLocation.Longitude,
            zoom: AppConstants.DefaultMapLocation.Zoom
        )
    }

    private func showUnknownLocationOverlayIfStillUnknownLocation() {
        if ((boundField?.location as? CommonLocation.Unknown) == nil) {
            return
        }

        unknownLocationOverlay.alpha = 0
        unknownLocationOverlay.isHidden = false

        UIView.animate(withDuration: AppConstants.Animations.durationShort) { [weak self] in
            self?.unknownLocationOverlay.alpha = 1
        }
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        navigateToMap()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        navigateToMap()
        return true
    }

    func onLocationSelected(location: CLLocationCoordinate2D) {
        dispatchValueChanged(
            eventDispatcher: locationEventDispatcher,
            value: location
        ) { dispatcher, fieldId, location in
            dispatcher.dispatchLocationChanged(fieldId: fieldId, value: location.toETRSCoordinate(source: .manual))
        }
    }

    private func navigateToMap() {
        guard let navigationController = self.navigationControllerProvider?.navigationController,
              let field = boundField else {
            print("No navigation controller / boundField, cannot navigate to map!")
            return
        }
        let selectLocation = !field.settings.readOnly && locationEventDispatcher != nil

        let controller = ViewOrSelectLocationOnMapViewController()
        controller.locationSelectionListener = self
        controller.locationMode = selectLocation ? .select : .view
        controller.customMapLayerExternalId = mapExternalId
        controller.customMapLayerInvertColors = true
        if let knownLocation = field.location as? CommonLocation.Known {
            controller.initialCoordinate = knownLocation.etrsLocation.toCoordinate()
        } else {
            controller.initialCoordinate = AppConstants.DefaultMapLocation.Coordinate
            controller.initialZoom = AppConstants.DefaultMapLocation.Zoom
        }


        navigationController.pushViewController(controller, animated: true)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        private weak var navigationControllerProvider: ProvidesNavigationController?
        private weak var locationEventDispatcher: LocationEventDispatcher?
        private weak var mapExternalIdProvider: MapExternalIdProvider?

        init(navigationControllerProvider: ProvidesNavigationController?,
             locationEventDispatcher: LocationEventDispatcher?,
             mapExternalIdProvider: MapExternalIdProvider?) {
            self.navigationControllerProvider = navigationControllerProvider
            self.locationEventDispatcher = locationEventDispatcher
            self.mapExternalIdProvider = mapExternalIdProvider
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(LocationFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! LocationFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.locationEventDispatcher = locationEventDispatcher
            cell.mapExternalIdProvider = mapExternalIdProvider

            return cell
        }
    }
}
