import Foundation
import GoogleMaps

extension CLLocationCoordinate2D {
    func toLocation() -> CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
