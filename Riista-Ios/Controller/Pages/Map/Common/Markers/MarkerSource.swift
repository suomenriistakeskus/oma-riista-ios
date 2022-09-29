import Foundation
import GoogleMapsUtils

class MarkerSource<MarkerType : Hashable, MarkerItemType : MarkerItem<MarkerType>> {
    func createMarkers() -> [MarkerItemType] {
        fatalError("Should override createMarkers()")
    }
}
