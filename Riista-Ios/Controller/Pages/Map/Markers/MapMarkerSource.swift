import Foundation
import GoogleMapsUtils
import RiistaCommon

class MapMarkerSource: MarkerSource<MapMarkerType, MapMarkerItem> {

    class func harvests(using storage: MapMarkerStorage) -> MarkerSource<MapMarkerType, MapMarkerItem> {
        MapMarkerSource(storage: storage) { storage in
            storage.harvests.compactMap { harvest in
                if let harvestId = harvest.localId {
                    return MapMarkerItem(
                        localId: harvestId,
                        type: .harvest,
                        position: harvest.geoLocation
                    )
                } else {
                    return nil
                }

            }
        }
    }

    class func observations(using storage: MapMarkerStorage) -> MarkerSource<MapMarkerType, MapMarkerItem> {
        MapMarkerSource(storage: storage) { storage in
            storage.observations.compactMap { observation in
                if let observationId = observation.localId {
                    return MapMarkerItem(
                        localId: observationId,
                        type: .observation,
                        position: observation.location
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
                if let srvaLocalId = srva.localId {
                    return MapMarkerItem(
                        localId: srvaLocalId,
                        type: .srva,
                        position: srva.location
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
