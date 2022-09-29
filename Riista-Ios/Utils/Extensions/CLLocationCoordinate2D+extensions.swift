import Foundation
import GoogleMaps

extension CLLocationCoordinate2D {
    func toLocation() -> CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /**
     * Can the location be considered valid i.e. it is not default-initialized one?
     */
    func isValid() -> Bool {
        // consider locations at (0,0) to be invalid
        return abs(latitude) > 0.01 || abs(longitude) > 0.01
    }
}
