import Foundation
import GoogleMapsUtils

class GroupHuntingMarkerItem: NSObject, GMUClusterItem {
    let id: Int64
    let type: GroupHuntingMarkerType
    var position: CLLocationCoordinate2D

    init(id: Int64, type: GroupHuntingMarkerType, position: CLLocationCoordinate2D) {
        self.id = id
        self.type = type
        self.position = position
        super.init()
    }
}
