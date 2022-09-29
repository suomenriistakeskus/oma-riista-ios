import Foundation
import GoogleMapsUtils

class GroupHuntingMarkerItem: MarkerItem<GroupHuntingMarkerType> {
    let id: Int64

    init(id: Int64, type: GroupHuntingMarkerType, position: CLLocationCoordinate2D) {
        self.id = id
        super.init(type: type, position: position)
    }
}
