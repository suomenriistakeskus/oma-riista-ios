import Foundation
import GoogleMapsUtils

protocol MarkerSource: AnyObject {
    func addMarkers(to clusterManager: GMUClusterManager)
}
