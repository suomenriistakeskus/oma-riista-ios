import Foundation
import GoogleMaps
import SnapKit

/**
 * A base class for map view controllers
 */
class BaseMapViewController: UIViewController, GMSMapViewDelegate {
    lazy var mapView: RiistaMapView = {
        createMapView()
    }()

    lazy var mapCrosshairOverlay: MapCrosshairOverlay = {
        MapCrosshairOverlay()
    }()

    lazy var mapControlsOverlay: MapControlsOverlayView = {
        MapControlsOverlayView()
    }()

    /**
     * The map controls currently added.
     */
    var mapControls = [MapControl]()

    /**
     * Has the initial camera been setup been done?
     */
    var initialCameraLocationSet: Bool = false

    /**
     * The location manager.
     */
    let locationManager = LocationManager()

    private(set) lazy var userLocationOnMap: UserLocationOnMap = {
        UserLocationOnMap(mapView: mapView, locationManager: locationManager)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        createSubviews()
        configureSubviewConstraints()

        configureMapView()
        addMapOverlayControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeCamera()
        showUserLocationBasedOnSettings()
        updateMapTypeBasedOnSettings()
        updateHideEdgeControlsBasedOnSettings()
        enableMapLayersBasedOnSettings()
        notifyControlsViewWillAppear()

        if let navController = navigationController as? RiistaNavigationController {
            let barButtons = createNavigationBarItems()
            navController.setRightBarItems(barButtons)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLocationListening()
        notifyControlsViewWillDisappear()
    }

    func startLocationListening() {
        locationManager.start()
    }

    func stopLocationListening() {
        locationManager.stop()
    }

    func createNavigationBarItems() -> [UIBarButtonItem] {
        let barButton = UIBarButtonItem(image: UIImage(named: "settings_white"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(onSettingsClicked))
        return [barButton]
    }

    @objc func onSettingsClicked() {
        let settingsController = MapSettingsViewController()
        navigationController?.pushViewController(settingsController, animated: true)
    }

    /**
     * Will be called upon viewDidLoad. Allows subclasses to customize subviews.
     *
     * Should probably be called by the subclass.
     */
    func createSubviews() {
        view.addSubview(mapView)
        view.addSubview(mapCrosshairOverlay)
        view.addSubview(mapControlsOverlay)
    }

    /**
     * Will be called upon viewDidLoad. Allows subclasses to customize how subviews are constrained.
     *
     * Should probably be called by the subclass.
     */
    func configureSubviewConstraints() {
        configureMapConstraints()
        configureMapCrosshairOverlayConstraints()
        configureMapControlsOverlayConstraints()
    }

    /**
     * Will be called upon viewDidLoad. Allows subclasses to customize how mapview gets positioned.
     */
    func configureMapConstraints() {
        print("Configuring map view constraints..")
        mapView.snp.makeConstraints { make in
            // allow to reach bottom edge i.e don't stop at layout guide at bottom..
            make.leading.trailing.bottom.equalToSuperview()

            // ..but always ensure map is not going under statusbar
            make.top.equalTo(view.layoutMarginsGuide)
        }
    }

    /**
     * Will be called upon viewDidLoad. Allows subclasses to customize how mapControls are positioned.
     */
    func configureMapCrosshairOverlayConstraints() {
        print("Configuring map crosshair constraints..")
        mapCrosshairOverlay.snp.makeConstraints { make in
            // crosshair overlay covers the map with the exception of bottom as camera
            // is centered vertically within layout margins
            make.leading.trailing.top.equalTo(mapView)
            make.bottom.equalTo(view.layoutMarginsGuide)
        }
    }

    /**
     * Will be called upon viewDidLoad. Allows subclasses to customize how mapControls are positioned.
     */
    func configureMapControlsOverlayConstraints() {
        print("Configuring map controls view constraints..")
        mapControlsOverlay.snp.makeConstraints { make in
            // controls may reach both edges
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(view.layoutMarginsGuide)
        }
    }

    /**
     * Called when map view should be created.
     */
    func createMapView() -> RiistaMapView {
        let mapView = RiistaMapView()
        mapView.delegate = self
        return mapView
    }

    /**
     * Called when the mapview should be configured.
     */
    func configureMapView() {
        mapCrosshairOverlay.crosshairVisible = true
        addMapLayers()
    }

    func addMapOverlayControls() {
        mapControls.append(MoveToUserLocationControl(userLocationOnMap: userLocationOnMap))
        mapControls.append(MapZoomControls(mapView: mapView))
        mapControls.append(MapMeasureDistanceControl(mapView: mapView, mapCrosshairOverlay: mapCrosshairOverlay))
        mapControls.append(MapToggleFullscreenControl(viewController: self))

        mapControls.forEach { mapControl in
            mapControl.registerControls(overlayControlsView: mapControlsOverlay)
        }
    }

    func addMapLayers() {
        mapView.addMapLayer(areaType: .Seura, zIndex: 10)
        mapView.addMapLayer(areaType: .Valtionmaa, zIndex: 20)
        mapView.addMapLayer(areaType: .Rhy, zIndex: 30)
        mapView.addMapLayer(areaType: .Moose, zIndex: 40)
        mapView.addMapLayer(areaType: .Pienriista, zIndex: 50)
        mapView.addMapLayer(areaType: .GameTriangles, zIndex: 60)
    }

    func enableMapLayersBasedOnSettings() {
        mapView.configureMapLayer(areaType: .Seura,
                                  externalId: RiistaSettings.activeClubAreaMapId(),
                                  invertLayerColors: RiistaSettings.invertMapColors())
        mapView.configureMapLayer(areaType: .Moose,
                                  externalId: RiistaSettings.selectedMooseArea()?.getAreaNumberAsString())
        mapView.configureMapLayer(areaType: .Pienriista,
                                  externalId: RiistaSettings.selectedPienriistaArea()?.getAreaNumberAsString())

        mapView.setMapLayerVisibility(areaType: .Valtionmaa, visible: RiistaSettings.showStateOwnedLands())
        mapView.setMapLayerVisibility(areaType: .Rhy, visible: RiistaSettings.showRhyBorders())
        mapView.setMapLayerVisibility(areaType: .GameTriangles, visible: RiistaSettings.showGameTriangles())
    }

    func initializeCamera() {
        if (initialCameraLocationSet) {
            return
        }

        initialCameraLocationSet = true

        mapView.camera = GMSCameraPosition(
            latitude: AppConstants.DefaultMapLocation.Latitude,
            longitude: AppConstants.DefaultMapLocation.Longitude,
            zoom: AppConstants.DefaultMapLocation.Zoom
        )
    }

    func showUserLocationBasedOnSettings() {
        userLocationOnMap.setShowUserLocationOnMap(showUserLocation: RiistaSettings.showMyMapLocation())

        let mapControl = mapControls.first { control in
            control.type == .moveToUserLocation
        }
        if let moveControl = mapControl as? MoveToUserLocationControl {
            moveControl.showMoveToUserLocationButton = RiistaSettings.showMyMapLocation()
        }
    }

    func updateMapTypeBasedOnSettings() {
        let mapType = RiistaSettings.mapType()
        mapView.setMapType(type: mapType)
        mapControlsOverlay.setMapType(type: mapType)
    }

    func updateHideEdgeControlsBasedOnSettings() {
        mapControlsOverlay.setEdgeControlsHidden(isHidden: RiistaSettings.hideMapButtons(), animateChange: false)
        mapControlsOverlay.onEdgeControlsHiddenChanged = { isHidden in
            RiistaSettings.setHideMapButtons(isHidden)
        }
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        self.mapControlsOverlay.updateMapScaleLabelText(mapView: mapView)
        notifyControlsMapPositionChanged()
    }

    private func notifyControlsViewWillAppear() {
        mapControls.forEach { control in
            control.onViewWillAppear()
        }
    }

    private func notifyControlsViewWillDisappear() {
        mapControls.forEach { control in
            control.onViewWillDisappear()
        }
    }

    private func notifyControlsMapPositionChanged() {
        mapControls.forEach { control in
            control.onMapPositionChanged()
        }
    }
}

