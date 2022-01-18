import Foundation
import GoogleMapsUtils
import RiistaCommon

/**
 * @return  True if click was handled, false otherwise.
 */
typealias OnGroupHuntingDiaryEntryClicked = (_ diaryEntryId: Int64, _ acceptStatus: RiistaCommon.AcceptStatus) -> Bool

class GroupHuntingMarkerClickHandler: DefaulClusterClickHandler<GroupHuntingMarkerItem> {

    var onHarvestMarkerClicked: OnGroupHuntingDiaryEntryClicked?
    var onObservationMarkerClicked: OnGroupHuntingDiaryEntryClicked?
    var onDisplayClusterItems: ((_ harvestIds: [Int64], _ observationIds: [Int64]) -> Void)?

    override init(mapView: RiistaMapView) {
        super.init(mapView: mapView)
    }

    override func onMarkerItemClicked(item: GroupHuntingMarkerItem) -> Bool {
        let itemType = item.type

        if let delegateHandler = getDelegateClickHandler(itemType: itemType) {
            return delegateHandler(item.id, getItemAcceptStatus(itemType: itemType))
        } else {
            print("No click handler for GroupHuntingMarkerItem of type \(itemType)")
            return false
        }
    }

    override func notifyClusterRequiresExpand(markerItems: [GroupHuntingMarkerItem]) {
        guard let onDisplayClusterItems = self.onDisplayClusterItems else {
            print("Cannot expand cluster, no callback defined!")
            return
        }

        var harvestIds: [Int64] = []
        var observationIds: [Int64] = []
        markerItems.forEach { markerItem in
            switch (markerItem.type) {
            case .harvestProposed, .harvestAccepted, .harvestRejected:
                harvestIds.append(markerItem.id)
                break
            case .observationProposed, .observationAccepted, .observationRejected:
                observationIds.append(markerItem.id)
                break
            }
        }

        onDisplayClusterItems(harvestIds, observationIds)
    }

    private func getDelegateClickHandler(itemType: GroupHuntingMarkerType) -> OnGroupHuntingDiaryEntryClicked? {
        switch itemType {
        case .harvestProposed, .harvestAccepted, .harvestRejected:
            return onHarvestMarkerClicked
        case .observationProposed, .observationAccepted, .observationRejected:
            return onObservationMarkerClicked
        }
    }

    private func getItemAcceptStatus(itemType: GroupHuntingMarkerType) -> RiistaCommon.AcceptStatus {
        switch itemType {
        case .harvestProposed, .observationProposed:    return .proposed
        case .harvestAccepted, .observationAccepted:    return .accepted
        case .harvestRejected, .observationRejected:    return .rejected
        }
    }
}
