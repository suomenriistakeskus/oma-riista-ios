import Foundation

class MapUtils {
    class func formatDistance(distanceMeters: CLLocationDistance) -> String {
        if (distanceMeters >= 1000) {
            return String(format: "%.1f km", arguments: [distanceMeters / 1000.0])
        } else {
            return String(format: "%i m", arguments: [Int(distanceMeters)])
        }
    }
}
