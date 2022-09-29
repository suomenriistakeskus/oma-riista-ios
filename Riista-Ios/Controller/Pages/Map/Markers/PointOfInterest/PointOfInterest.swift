import Foundation
import RiistaCommon

class PointOfInterest {
    let group: PoiLocationGroup
    let poiLocation: PoiLocation

    init(group: PoiLocationGroup, poiLocation: PoiLocation) {
        self.group = group
        self.poiLocation = poiLocation
    }
}
