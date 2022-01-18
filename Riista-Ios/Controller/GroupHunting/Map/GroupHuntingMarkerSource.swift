import Foundation
import GoogleMapsUtils
import RiistaCommon

class GroupHuntingMarkerSource: MarkerSource {

    // MARK: MarkerSources for harvests

    class func proposedHarvests(using storage: GroupHuntingMarkerStorage) -> MarkerSource {
        GroupHuntingMarkerSource(storage: storage) { storage in
            storage.harvests.filter { harvest in
                harvest.acceptStatus == AcceptStatus.proposed
            }.map { harvest in
                GroupHuntingMarkerItem(id: harvest.id, type: .harvestProposed, position: harvest.geoLocation.toCoordinate())
            }
        }
    }

    class func acceptedHarvests(using storage: GroupHuntingMarkerStorage) -> MarkerSource {
        GroupHuntingMarkerSource(storage: storage) { storage in
            storage.harvests.filter { harvest in
                harvest.acceptStatus == AcceptStatus.accepted
            }.map { harvest in
                GroupHuntingMarkerItem(id: harvest.id, type: .harvestAccepted, position: harvest.geoLocation.toCoordinate())
            }
        }
    }

    class func rejectedHarvests(using storage: GroupHuntingMarkerStorage) -> MarkerSource {
        GroupHuntingMarkerSource(storage: storage) { storage in
            storage.harvests.filter { harvest in
                harvest.acceptStatus == AcceptStatus.rejected
            }.map { harvest in
                GroupHuntingMarkerItem(id: harvest.id, type: .harvestRejected, position: harvest.geoLocation.toCoordinate())
            }
        }
    }


    // MARK: MarkerSources for observations

    class func proposedObservations(using storage: GroupHuntingMarkerStorage) -> MarkerSource {
        GroupHuntingMarkerSource(storage: storage) { storage in
            storage.observations.filter { observation in
                observation.acceptStatus == AcceptStatus.proposed
            }.map { observation in
                GroupHuntingMarkerItem(id: observation.id, type: .observationProposed, position: observation.geoLocation.toCoordinate())
            }
        }
    }

    class func acceptedObservations(using storage: GroupHuntingMarkerStorage) -> MarkerSource {
        GroupHuntingMarkerSource(storage: storage) { storage in
            storage.observations.filter { observation in
                observation.acceptStatus == AcceptStatus.accepted
            }.map { observation in
                GroupHuntingMarkerItem(id: observation.id, type: .observationAccepted, position: observation.geoLocation.toCoordinate())
            }
        }
    }

    class func rejectedObservations(using storage: GroupHuntingMarkerStorage) -> MarkerSource {
        GroupHuntingMarkerSource(storage: storage) { storage in
            storage.observations.filter { observation in
                observation.acceptStatus == AcceptStatus.rejected
            }.map { observation in
                GroupHuntingMarkerItem(id: observation.id, type: .observationRejected, position: observation.geoLocation.toCoordinate())
            }
        }
    }


    let storage: GroupHuntingMarkerStorage
    let createMarkers: (GroupHuntingMarkerStorage) -> [GroupHuntingMarkerItem]

    private init(storage: GroupHuntingMarkerStorage,
                 createMarkers: @escaping (GroupHuntingMarkerStorage) -> [GroupHuntingMarkerItem] ) {
        self.storage = storage
        self.createMarkers = createMarkers
    }

    func addMarkers(to clusterManager: GMUClusterManager) {
        clusterManager.add(createMarkers(storage))
    }
}
