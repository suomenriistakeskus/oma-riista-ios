import Foundation
import GoogleMapsUtils
import RiistaCommon

class MapMarkerSource: MarkerSource<MapMarkerType, MapMarkerItem> {

    class func harvests(using storage: MapMarkerStorage) -> MarkerSource<MapMarkerType, MapMarkerItem> {
        MapMarkerSource(storage: storage) { storage in
            storage.harvests.map { harvest in
                MapMarkerItem(
                    objectId: harvest.objectID,
                    type: .harvest,
                    position: harvest.coordinates.toWGS84Coordinate()
                )
            }
        }
    }

    class func observations(using storage: MapMarkerStorage) -> MarkerSource<MapMarkerType, MapMarkerItem> {
        MapMarkerSource(storage: storage) { storage in
            storage.observations.compactMap { observation in
                if let position = observation.coordinates?.toWGS84Coordinate() {
                    return MapMarkerItem(
                        objectId: observation.objectID,
                        type: .observation,
                        position: position
                    )
                } else {
                    return nil
                }
            }
        }
    }

    class func srvas(using storage: MapMarkerStorage) -> MarkerSource<MapMarkerType, MapMarkerItem> {
        MapMarkerSource(storage: storage) { storage in
            storage.srvas.compactMap { srva in
                if let position = srva.coordinates?.toWGS84Coordinate() {
                    return MapMarkerItem(
                        objectId: srva.objectID,
                        type: .srva,
                        position: position
                    )
                } else {
                    return nil
                }
            }
        }
    }

    class func pointsOfInterest(using storage: MapMarkerStorage) -> MarkerSource<MapMarkerType, MapMarkerItem> {
        MapMarkerSource(storage: storage) { storage in
            storage.pointsOfInterest.map { pointOfInterest in
                MapMarkerItem(pointOfInterest: pointOfInterest)
            }
        }
    }


    let storage: MapMarkerStorage
    let createMarkersFunc: (MapMarkerStorage) -> [MapMarkerItem]

    private init(storage: MapMarkerStorage,
                 createMarkers: @escaping (MapMarkerStorage) -> [MapMarkerItem] ) {
        self.storage = storage
        self.createMarkersFunc = createMarkers
    }

    override func createMarkers() -> [MapMarkerItem] {
        return createMarkersFunc(storage)
    }
}