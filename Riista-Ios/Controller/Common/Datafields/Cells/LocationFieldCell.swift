import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.location

class LocationFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, LocationField<FieldId>>,
    GMSMapViewDelegate,
    MapPageDelegate {

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
    }

    override func fieldWasBound(field: LocationField<FieldId>) {
        // update map external every time field is bound
        mapExternalId = mapExternalIdProvider?.getMapExternalId()

        let location = field.location.toCoordinate()
        mapView.camera = GMSCameraPosition(
            latitude: location.latitude,
            longitude: location.longitude,
            zoom: AppConstants.Map.DefaultZoomToLevel
        )
        locationMarker.position = location

        coordinatesLabel.text = String(format: "CoordinatesFormat".localized(),
                                       field.location.latitude, field.location.longitude)
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        navigateToMap()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        navigateToMap()
        return true
    }

    func locationSetManually(_ location: CLLocationCoordinate2D) {
        dispatchValueChanged(
            eventDispatcher: locationEventDispatcher,
            value: location) { dispatcher, fieldId, location in
            dispatcher.dispatchLocationChanged(fieldId: fieldId, value: location.toETRSCoordinate(source: .manual))
        }
    }

    private func navigateToMap() {
        guard let navigationController = self.navigationControllerProvider?.navigationController,
              let field = boundField else {
            print("No navigation controller / boundField, cannot navigate to map!")
            return
        }

        let storyboard = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "mapPageController") as? RiistaMapViewController else {
            print("No map page controller, cannot navigate to map!")
            return
        }

        controller.delegate = self
        controller.editMode = !field.settings.readOnly && locationEventDispatcher != nil
        controller.location = field.location.toCoordinate().toLocation()
        controller.hidePins = true

        controller.overrideAreaExternalId = true
        controller.overriddenAreaExternalId = mapExternalId
        controller.overriddenAreaInvertColors = true

        controller.riistaController = navigationController as? RiistaNavigationController

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
