import Foundation

class GroupHuntingMarkerManager: BaseMarkerManager<GroupHuntingMarkerType, GroupHuntingMarkerItem> {
    let markerStorage = GroupHuntingMarkerStorage()

    private lazy var markerIcons: [GroupHuntingMarkerType : UIImage] = {
        [
            // require marker images to exist -> use '!'
            .harvestProposed : UIImage(named: "pin_harvest_proposed")!,
            .harvestAccepted : UIImage(named: "pin_harvest_accepted")!,
            .harvestRejected : UIImage(named: "pin_harvest_rejected")!,
            .observationProposed : UIImage(named: "pin_observation_proposed")!,
            .observationAccepted : UIImage(named: "pin_observation_accepted")!,
            .observationRejected : UIImage(named: "pin_observation_rejected")!,
        ]
    }()

    override init(mapView: GMSMapView, mapViewDelegate: GMSMapViewDelegate?) {
        super.init(mapView: mapView, mapViewDelegate: mapViewDelegate)

        addMarkerSource(markerType: .harvestProposed,
                        source: GroupHuntingMarkerSource.proposedHarvests(using: markerStorage))
        addMarkerSource(markerType: .harvestAccepted,
                        source: GroupHuntingMarkerSource.acceptedHarvests(using: markerStorage))
        addMarkerSource(markerType: .harvestRejected,
                        source: GroupHuntingMarkerSource.rejectedHarvests(using: markerStorage))
        addMarkerSource(markerType: .observationProposed,
                        source: GroupHuntingMarkerSource.proposedObservations(using: markerStorage))
        addMarkerSource(markerType: .observationAccepted,
                        source: GroupHuntingMarkerSource.acceptedObservations(using: markerStorage))
        addMarkerSource(markerType: .observationRejected,
                        source: GroupHuntingMarkerSource.rejectedObservations(using: markerStorage))
    }

    override func updateMarkerIcon(marker: GMSMarker, markerItem: GroupHuntingMarkerItem) {
        marker.icon = markerIcons[markerItem.type]
    }
}

