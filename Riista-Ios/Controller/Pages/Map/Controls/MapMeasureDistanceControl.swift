import Foundation
import GoogleMaps

protocol MapMeasureDistanceControlObserver: AnyObject {
    func onMapMeasureStarted()
    func onMapMeasureEnded()
}

class MapMeasureDistanceControl: BaseMapControl {

    weak var observer: MapMeasureDistanceControlObserver?

    private weak var mapView: RiistaMapView?
    private weak var mapCrosshairOverlay: MapCrosshairOverlay?

    private weak var measureButtonsContainer: UIView?
    private weak var distanceLabel: MapLabel?

    private(set) var measureStarted: Bool = false
    private var measurePath = GMSMutablePath()
    private weak var measureLine: GMSPolyline?

    init(mapView: RiistaMapView, mapCrosshairOverlay: MapCrosshairOverlay) {
        super.init(type: .measureDistance)
        self.mapView = mapView
        self.mapCrosshairOverlay = mapCrosshairOverlay
    }

    override func onMapPositionChanged() {
        updateDisplayedValues()
    }

    override func registerControls(overlayControlsView: MapControlsOverlayView) {
        overlayControlsView.addEdgeControl(image: UIImage(named: "measure")) { [weak self] in
            self?.toggleMeasureEnabled()
        }

        let measureButtons = createMapMeasureButtons()
        measureButtons.isHidden = true
        measureButtonsContainer = measureButtons

        overlayControlsView.bottomCenterControls.addView(measureButtons)

        if let mapCrosshairOverlay = self.mapCrosshairOverlay {
            self.distanceLabel = MapLabel().apply { label in
                label.edgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
                label.roundedCorners = CACornerMask.allCorners()
                label.cornerRadius = 2
                label.isHidden = true
                mapCrosshairOverlay.addSubview(label)
                label.snp.makeConstraints { make in
                    make.centerX.equalTo(mapCrosshairOverlay.crosshairView)
                    make.top.equalTo(mapCrosshairOverlay.crosshairView.snp.bottom).offset(8)
                }
            }
        }
    }

    /**
     * Updates the displayed measurement data and line. Should be called when
     * - map is moved
     * - a point is added / removed
     */
    func updateDisplayedValues() {
        if (!measureStarted) {
            return
        }

        guard let mapView = self.mapView else {
            stopMeasurement()
            return
        }

        // extend the measurePath to the current map center location
        let linePath = GMSMutablePath(path: measurePath)
        let mapCenterLocation = mapView.camera.target
        linePath.add(mapCenterLocation)

        measureLine?.path = linePath

        if let distanceLabel = self.distanceLabel {
            let totalDistance = linePath.length(of: .geodesic)
            distanceLabel.text = MapUtils.formatDistance(distanceMeters: totalDistance)
        }
    }

    private func toggleMeasureEnabled() {
        if (!measureStarted) {
            startMeasurement()
        } else {
            stopMeasurement()
        }
    }

    private func startMeasurement() {
        guard let mapView = self.mapView else { return }

        measureStarted = true
        if (measureLine == nil) {
            self.measureLine = GMSPolyline().apply { line in
                line.strokeWidth = 3
                line.strokeColor = .red
                line.zIndex = 100
                line.map = mapView
            }
        }

        updateMeasureUIVisibility()
        addMeasurementPoint()

        observer?.onMapMeasureStarted()
    }

    private func stopMeasurement() {
        measurePath.removeAllCoordinates()

        if let measureLine = measureLine {
            measureLine.map = nil
            self.measureLine = nil
        }

        measureStarted = false
        updateMeasureUIVisibility { [weak self] in
            self?.observer?.onMapMeasureEnded()
        }
    }

    private func addMeasurementPoint() {
        guard let mapView = self.mapView else { return }

        let mapCenterLocation = mapView.camera.target
        if let lastCoordinate = measurePath.lastCoordinate() {
            if (lastCoordinate.toLocation().distance(from: mapCenterLocation.toLocation()) > 5) {
                measurePath.add(mapCenterLocation)
                updateDisplayedValues()
            } else {
                print("Not adding point, it is too close to the previous point")
            }
        } else {
            measurePath.add(mapCenterLocation)
            updateDisplayedValues()
        }
    }

    private func removeMeasurementPoint() {
        if (measurePath.count() > 1) {
            measurePath.removeLastCoordinate()
            updateDisplayedValues()
        } else {
            stopMeasurement()
        }
    }

    private func createMapMeasureButtons() -> UIView {
        let container = OverlayView()

        let removePointButton = createMeasurementButton(imageName: "minus")
        removePointButton.onClicked = { [weak self] in
            self?.removeMeasurementPoint()
        }

        let addPointButton = createMeasurementButton(imageName: "plus")
        addPointButton.onClicked = { [weak self] in
            self?.addMeasurementPoint()
        }

        container.addSubview(removePointButton)
        container.addSubview(addPointButton)
        removePointButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        addPointButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(removePointButton.snp.trailing).offset(32)
        }
        
        container.contentMode = .center

        return container
    }

    private func createMeasurementButton(imageName: String) -> MaterialButton {
        let btn = MaterialButton()
        AppTheme.shared.setupPrimaryButtonTheme(button: btn)
        btn.setImage(UIImage(named: imageName), for: .normal)
        btn.setBackgroundColor(UIColor.applicationColor(ViewBackground),
                               for: .normal)
        btn.snp.makeConstraints { make in
            make.width.height.equalTo(AppConstants.UI.DefaultButtonHeight)
        }
        return btn
    }

    private func updateMeasureUIVisibility(completion: OnCompleted? = nil) {
        guard let measureButtons = self.measureButtonsContainer,
              let distanceLabel = self.distanceLabel else {
            return
        }

        if (measureStarted) {
            measureButtons.alpha = 0
            measureButtons.isHidden = false
            distanceLabel.alpha = 0
            distanceLabel.isHidden = false
            UIView.animate(withDuration: AppConstants.Animations.durationShort) {
                measureButtons.alpha = 1
                distanceLabel.alpha = 1
            } completion: { _ in
                completion?()
            }
        } else {
            UIView.animate(withDuration: AppConstants.Animations.durationShort) {
                measureButtons.alpha = 0
                distanceLabel.alpha = 0
            } completion: { _ in
                measureButtons.isHidden = true
                distanceLabel.isHidden = true

                completion?()
            }
        }
    }
}

fileprivate extension GMSPath {
    func lastCoordinate() -> CLLocationCoordinate2D? {
        if (count() > 0) {
            return coordinate(at: count() - 1)
        } else {
            return nil
        }
    }
}
