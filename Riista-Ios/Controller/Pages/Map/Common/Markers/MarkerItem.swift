import Foundation
import GoogleMapsUtils

class MarkerItem<MarkerItemType>: NSObject, GMUClusterItem {
    let type: MarkerItemType
    var position: CLLocationCoordinate2D

    init(type: MarkerItemType, position: CLLocationCoordinate2D) {
        self.type = type
        self.position = position
        super.init()
    }
}
