import Foundation
import GoogleMapsUtils
import RiistaCommon

// the type of id of the item
enum MapMarkerItemId: Equatable {
    case objectId(_ objectId: NSManagedObjectID)
    case commonLocalId(_ localId: KotlinLong) // a local id of the item in RiistCommon
    case pointOfInterest(_ poi: PointOfInterest)

    static func == (lhs: MapMarkerItemId, rhs: MapMarkerItemId) -> Bool {
        switch (lhs, rhs) {
        case (let objectId(l_objectId), let objectId(r_objectId)):
            return l_objectId == r_objectId
        case (let commonLocalId(l_commonLocalId), let commonLocalId(r_commonLocalId)):
            return l_commonLocalId == r_commonLocalId
        case (let pointOfInterest(l_poi), let pointOfInterest(r_poi)):
            return l_poi.group.id == r_poi.group.id &&
                l_poi.poiLocation.id == r_poi.poiLocation.id
        default:
            return false
        }
    }
}

class MapMarkerItem: MarkerItem<MapMarkerType> {
    let itemId: MapMarkerItemId

    init(itemId: MapMarkerItemId, type: MapMarkerType, position: CLLocationCoordinate2D) {
        self.itemId = itemId
        super.init(type: type, position: position)
    }

    convenience init(objectId: NSManagedObjectID, type: MapMarkerType, position: CLLocationCoordinate2D) {
        self.init(itemId: .objectId(objectId), type: type, position: position)
    }

    convenience init(pointOfInterest: PointOfInterest) {
        self.init(
            itemId: .pointOfInterest(pointOfInterest),
            type: .pointOfInterest,
            position: pointOfInterest.poiLocation.geoLocation.toCoordinate()
        )
    }

}
