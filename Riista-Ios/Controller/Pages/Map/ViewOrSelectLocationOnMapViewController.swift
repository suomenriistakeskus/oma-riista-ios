import Foundation

@objc protocol LocationSelectionListener: AnyObject {
    func onLocationSelected(location: CLLocationCoordinate2D)
}

class ViewOrSelectLocationOnMapViewController: BaseMapViewController {

    // A helper for creating the viewcontroller from the objective-c
    @objc class func create(
        selectMode: Bool,
        initialLocation: CLLocation?,
        listener: LocationSelectionListener? = nil
    ) -> ViewOrSelectLocationOnMapViewController {
        let controller = ViewOrSelectLocationOnMapViewController()
        controller.locationMode = selectMode ? .select : .view
        controller.initialCoordinate = initialLocation?.coordinate
        controller.locationSelectionListener = listener

        return controller
    }

    enum LocationMode {
        case view
        case select
    }

    // MARK: configuration & listener

    weak var locationSelectionListener: LocationSelectionListener?

    var locationMode: LocationMode = .view

    var customMapLayerExternalId: String? = nil
    var customMapLayerInvertColors: Bool = false

    var initialCoordinate: CLLocationCoordinate2D?
    var initialZoom: Float?


    // A marker for indicating the location
    private lazy var locationMarker: GMSMarker = {
        let marker = GMSMarker()
        marker.map = mapView
        marker.icon = UIImage(named: "map-pin-generic")
        return marker
    }()

    private lazy var selectLocationControls: OverlayStackView = {
        let controlsContainer = OverlayStackView()
        controlsContainer.axis = .vertical
        controlsContainer.alignment = .fill
        controlsContainer.spacing = 8

        controlsContainer.addArrangedSubview(moveToUserLocationButton)
        controlsContainer.addArrangedSubview(selectLocationButton)

        return controlsContainer
    }()

    private lazy var moveToUserLocationButton: MaterialButton = {
        let button = MaterialButton()
        button.applyOutlinedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        button.setBackgroundColor(.white)
        button.setTitle("MapPageGoToCurrentGps".localized(), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }

        button.onClicked = {
            self.moveToUserLocation()
        }

        return button
    }()

    private lazy var selectLocationButton: MaterialButton = {
        let button = MaterialButton()
        button.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        button.setTitle("MapPageSetNewLocation".localized(), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }

        button.onClicked = {
            self.selectLocation()
        }

        return button
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let coordinate = initialCoordinate {
            // accessing locationMarker will create it and add it to map to the
            // given position
            locationMarker.position = coordinate
        }
    }

    override func configureMapControlsOverlayConstraints() {
        super.configureMapControlsOverlayConstraints()
        mapControlsOverlay.constrainEdgeControlsAboveOfBottomCenterControls()
    }

    override func addMapOverlayControls() {
        mapControls.append(MoveToUserLocationControl(userLocationOnMap: userLocationOnMap))
        mapControls.append(MapZoomControls(mapView: mapView))
        mapControls.append(MapToggleFullscreenControl(viewController: self))

        mapControls.forEach { mapControl in
            mapControl.registerControls(overlayControlsView: mapControlsOverlay)
        }

        if (locationMode == .select) {
            addSelectLocationControls()
        }
    }

    private func addSelectLocationControls() {
        mapControlsOverlay.bottomCenterControls.addView(selectLocationControls)
        selectLocationControls.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }

        userLocationOnMap.onUserLocationKnownChanged.append({ [weak self] locationKnown in
            self?.moveToUserLocationButton.isEnabled = locationKnown
        })
    }

    override func addMapLayers() {
        super.addMapLayers()
        addCustomMapLayer()
    }

    private func addCustomMapLayer() {
        guard let externalId = customMapLayerExternalId else {
            return
        }
        let layerId = calculateLayerIdForCustomLayer()
        mapView.addMapLayer(layerId: layerId, areaType: .Seura, zIndex: 15)
        mapView.setMapLayerVisibility(layerId: layerId, visible: false)
        mapView.configureMapLayer(
            layerId: layerId,
            externalId: externalId,
            invertLayerColors: customMapLayerInvertColors
        )
    }

    private func calculateLayerIdForCustomLayer() -> MapLayerId {
        var candidateId: MapLayerId = mapView.maxOverlayLayerId + 100
        while (mapView.hasMapLayer(layerId: candidateId)) {
            candidateId += 1
        }
        return candidateId
    }

    override func getInitialCameraPosition() -> GMSCameraPosition {
        if let coordinate = initialCoordinate, coordinate.isValid() {
            return GMSCameraPosition(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                zoom: initialZoom ?? AppConstants.Map.DefaultZoomToLevel
            )
        } else {
            return super.getInitialCameraPosition()
        }
    }

    override func showUserLocationIfNeeded() {
        // track user location but don't show it on the map
        userLocationOnMap.trackUserLocation()

        let mapControl = mapControls.first { control in
            control.type == .moveToUserLocation
        }
        if let moveControl = mapControl as? MoveToUserLocationControl {
            moveControl.showMoveToUserLocationButton = true
        }
    }

    private func moveToUserLocation() {
        userLocationOnMap.moveMapToUserLocation()
    }

    private func selectLocation() {
        guard let listener = locationSelectionListener else {
            return
        }

        listener.onLocationSelected(location: mapView.camera.target)
        navigationController?.popViewController(animated: true)
    }
}
