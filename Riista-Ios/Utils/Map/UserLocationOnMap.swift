import Foundation


class UserLocationOnMap: LocationListener {

    private weak var mapView: RiistaMapView?

    private weak var locationManager: LocationManager?

    private(set) var userLocationKnown: Bool = false {
        didSet {
            onUserLocationKnownChanged?(userLocationKnown)
        }
    }

    private var showUserLocationOnMap: Bool = false
    private var userLocationMarker: GMSMarker? = nil
    private var userLocationAccuracyCircle: GMSCircle? = nil

    var onUserLocationKnownChanged: ((_ locationKnown: Bool) -> Void)?

    init(mapView: RiistaMapView, locationManager: LocationManager) {
        self.mapView = mapView
        self.locationManager = locationManager
    }

    func setShowUserLocationOnMap(showUserLocation: Bool) {
        showUserLocationOnMap = showUserLocation
        if (showUserLocation) {
            trackUserLocation()
        } else {
            updateUserLocationOnMap(location: nil)
        }
    }

    func trackUserLocation() {
        if let locationManager = self.locationManager {
            locationManager.addListener(self, notifyLastLocation: true)
            locationManager.start()
        } else {
            print("UserLocationOnMap: Failed to add listener to LocationManager. No LocationManager!")
        }
    }

    func moveMapToUserLocation() {
        guard let mapView = self.mapView, let location = locationManager?.lastLocation else {
            userLocationKnown = false
            return
        }

        // Move then zoom in separate steps since animate route is unpredictable and may go
        // outside MML tile area if done at the same time.
        mapView.animate(toLocation: location.coordinate)
        mapView.animate(toZoom: max(AppConstants.Map.DefaultZoomToLevel, mapView.camera.zoom))
    }

    func updateUserLocationOnMap(location: CLLocation?) {
        if showUserLocationOnMap, let location = location {
            updateUserLocationMarker(location: location)
            updateUserLocationAccuracyCircle(location: location)
        } else {
            removeUserLocationMarker()
            removeUserLocationAccuracyCircle()
        }
    }

    private func updateUserLocationMarker(location: CLLocation) {
        let position = location.coordinate
        if let marker = userLocationMarker {
            marker.position = position
        } else {
            self.userLocationMarker = GMSMarker(position: position).apply { marker in
                marker.map = self.mapView
            }
        }
    }

    private func updateUserLocationAccuracyCircle(location: CLLocation) {
        let position = location.coordinate
        let radius = location.horizontalAccuracy
        if (radius <= 0) {
            removeUserLocationAccuracyCircle()
            return
        }

        if let circle = userLocationAccuracyCircle {
            circle.position = position
            circle.radius = radius
        } else {
            self.userLocationAccuracyCircle = GMSCircle(position: position, radius: radius).apply{ circle in
                circle.map = self.mapView
                circle.fillColor = UIColor(red: 0.25, green: 0, blue: 0.25, alpha: 0.2)
                circle.strokeColor = .red
                circle.zIndex = 90
                circle.strokeWidth = 1
            }
        }
    }

    private func removeUserLocationMarker() {
        if let marker = userLocationMarker {
            marker.map = nil
            self.userLocationMarker = nil
        }
    }

    private func removeUserLocationAccuracyCircle() {
        if let circle = userLocationAccuracyCircle {
            circle.map = nil
            self.userLocationAccuracyCircle = nil
        }
    }

    func onLocationChanged(newLocation: CLLocation?) {
        userLocationKnown = newLocation != nil

        updateUserLocationOnMap(location: newLocation)
    }
}
