import Foundation

class MoveToUserLocationControl: BaseMapControl {

    private weak var mapView: RiistaMapView?
    private weak var moveButton: MaterialButton?

    private weak var userLocationOnMap: UserLocationOnMap?

    var showMoveToUserLocationButton: Bool = false {
        didSet {
            if (oldValue != showMoveToUserLocationButton) {
                updateVisibility()
            }
        }
    }

    init(userLocationOnMap: UserLocationOnMap) {
        super.init(type: .moveToUserLocation)
        self.userLocationOnMap = userLocationOnMap
    }

    override func onViewWillAppear() {
        super.onViewWillAppear()

        updateVisibility()
    }

    private func updateVisibility() {
        if (!controlVisible) {
            return
        }

        if showMoveToUserLocationButton, let userLocation = userLocationOnMap {
            setButtonVisiblity(visible: true)

            setButtonEnabled(enabled: userLocation.userLocationKnown)
            userLocation.onUserLocationKnownChanged = { [weak self] locationKnown in
                self?.setButtonEnabled(enabled: locationKnown)
            }

            userLocation.trackUserLocation()
        } else {
            setButtonVisiblity(visible: false)
        }
    }

    override func registerControls(overlayControlsView: MapControlsOverlayView) {
        moveButton = overlayControlsView.addEdgeControl(image: UIImage(named: "gps_arrow")) { [weak self] in
            self?.moveMapToUserLocation()
        }
    }

    private func moveMapToUserLocation() {
        guard let userLocation = self.userLocationOnMap else {
            setButtonEnabled(enabled: false)
            return
        }

        userLocation.moveMapToUserLocation()
    }

    private func setButtonVisiblity(visible: Bool) {
        guard let button = moveButton else { return }
        button.isHidden = !visible
    }

    private func setButtonEnabled(enabled: Bool) {
        guard let button = moveButton else { return }
        button.isEnabled = enabled
    }
}
