import Foundation
import GoogleMaps
import GoogleMapsUtils

@objc class MapMarkerItem: NSObject, GMUClusterItem {

    @objc var position: CLLocationCoordinate2D
    @objc var type: RiistaEntryType
    @objc var localId: NSManagedObjectID

    @objc init(position: CLLocationCoordinate2D, type: RiistaEntryType, localId: NSManagedObjectID) {
        self.position = position
        self.type = type
        self.localId = localId
    }
}
