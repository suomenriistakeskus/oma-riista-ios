import Foundation
import CoreLocation

protocol LocationListener: AnyObject {
    /**
     * Called when the location is changed.
     *
     * @param newLocation   The new location or nil, if last known location is cleared.
     */
    func onLocationChanged(newLocation: CLLocation?)
}

/**
 * Listens current GPS location. Allows multiple delegates.
 */
class LocationManager: NSObject, CLLocationManagerDelegate {

    /**
     * The configuration for the location listening.
     */
    struct Config {
        /**
         * Specifies the minimum update distance in meters. Client will not be notified of movements
         * of less than the stated value, unless the accuracy has improved. Pass in kCLDistanceFilterNone
         * to be notified of all movements.
         */
        var distanceFilter: CLLocationDistance = kCLDistanceFilterNone

        /**
         * The desired location accuracy. The location service will try its best to achieve your
         * desired accuracy. However, it is not guaranteed. To optimize power performance,
         * be sure to specify an appropriate accuracy for your usage scenario (eg, use a large
         * accuracy value when only a coarse location is needed). Use kCLLocationAccuracyBest to
         * achieve the best possible accuracy. Use kCLLocationAccuracyBestForNavigation for navigation.
         */
        var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    }

    /**
     * The actual location manager that tracks the user location.
     */
    private var locationManager: CLLocationManager?

    /**
     * Has the location listening started?
     */
    private var started: Bool = false

    /**
     * A configuration for the location manager. Values are applied only when starting location listening (start()).
     */
    var config: Config = Config()

    /**
     * The location listeners
     */
    private let delegates = MultiDelegate<LocationListener>()

    /**
     * The last observed location.
     */
    private(set) var lastLocation: CLLocation?

    /**
     * Adds a LocationListener and optionally notifies it about the last known location.
     *
     * Will keep a weak reference to listener.
     */
    func addListener(_ listener: LocationListener, notifyLastLocation: Bool = true) {
        delegates.add(delegate: listener)

        if (notifyLastLocation) {
            listener.onLocationChanged(newLocation: lastLocation)
        }
    }

    func removeListener(_ listener: LocationListener, stopIfLastListener: Bool = true) {
        delegates.remove(delegate: listener)

        if (stopIfLastListener && delegates.delegateCount == 0) {
            stop()
        }
    }

    /**
     * Is the app authorized to acces location?
     */
    func isAuthorized() -> Bool {
        switch (currentAuthorizationStatus()) {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            return false
        }
    }

    func start() {
        // nothing to do if already started
        if (locationManager != nil) {
            print("LocationManager: already started!")
            return
        }

        locationManager = CLLocationManager().apply { manager in
            manager.delegate = self
            manager.distanceFilter = config.distanceFilter
            manager.desiredAccuracy = config.desiredAccuracy
        }

        if (isAuthorized()) {
            doStart()
        } else {
            print("LocationManager: not yet authorized, requesting authorization")
            locationManager?.requestWhenInUseAuthorization()
        }
    }

    func stop(clearLastLocation: Bool = false) {
        if let locationManager = self.locationManager {
            print("LocationManager: stopping..")
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            self.locationManager = nil
        } else {
            print("LocationManager: already stopped!")
        }

        started = false

        if (clearLastLocation) {
            lastLocation = nil
            print("LocationManager: last location cleared.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let latestLocation = locations.last {
            delegates.invoke { delegate in
                delegate.onLocationChanged(newLocation: latestLocation)
            }

            self.lastLocation = latestLocation
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startIfAuthorizedOrStopIfDenied()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startIfAuthorizedOrStopIfDenied()
    }

    private func startIfAuthorizedOrStopIfDenied() {
        switch (currentAuthorizationStatus()) {
        case .restricted, .denied:
            stop()
        case .authorizedAlways, .authorizedWhenInUse:
            print("LocationManager: authorization granted")
            doStart()
        case .notDetermined: fallthrough
        @unknown default:
            // nop
            break
        }
    }

    private func doStart() {
        guard let locationManager = locationManager else {
            print("LocationManager: cannot start without internal locationManager implementation..")
            return
        }

        if (started) {
            print("LocationManager: already started..")
            return
        }

        if (delegates.delegateCount == 0) {
            print("LocationManager: starting with no delegates..")
        } else {
            print("LocationManager: starting..")
        }

        started = true
        locationManager.startUpdatingLocation()
    }

    private func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager?.authorizationStatus ?? .notDetermined
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
}
