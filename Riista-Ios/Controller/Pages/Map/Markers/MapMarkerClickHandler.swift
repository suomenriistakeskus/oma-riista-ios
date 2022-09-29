import Foundation
import GoogleMapsUtils
import RiistaCommon


struct ClusteredMapItems {
    fileprivate(set) var harvestIds: [MapMarkerItemId] = []
    fileprivate(set) var observationIds: [MapMarkerItemId] = []
    fileprivate(set) var srvaIds: [MapMarkerItemId] = []
    fileprivate(set) var pointOfInterests: [MapMarkerItemId] = []
}

/**
 * @return  True if click was handled, false otherwise.
 */
typealias OnMapMarkerClicked = (_ markerItemId: MapMarkerItemId) -> Bool

class MapMarkerClickHandler: DefaulClusterClickHandler<MapMarkerItem> {

    var onHarvestMarkerClicked: OnMapMarkerClicked?
    var onObservationMarkerClicked: OnMapMarkerClicked?
    var onSrvaMarkerClicked: OnMapMarkerClicked?
    var onPointOfInterstClicked: OnMapMarkerClicked?
    var onDisplayClusterItems: ((_ clusteredItems: ClusteredMapItems) -> Void)?

    override init(mapView: RiistaMapView) {
        super.init(mapView: mapView)
    }

    override func onMarkerItemClicked(item: MapMarkerItem) -> Bool {
        let itemType = item.type

        if let delegateHandler = getDelegateClickHandler(itemType: itemType) {
            return delegateHandler(item.itemId)
        } else {
            print("No click handler for MapMarkerItem of type \(itemType)")
            return false
        }
    }

    override func notifyClusterRequiresExpand(markerItems: [MapMarkerItem]) {
        guard let onDisplayClusterItems = self.onDisplayClusterItems else {
            print("Cannot expand cluster, no callback defined!")
            return
        }

        var clusteredItems = ClusteredMapItems()
        markerItems.forEach { markerItem in
            switch (markerItem.type) {
            case .harvest:
                clusteredItems.harvestIds.append(markerItem.itemId)
            case .observation:
                clusteredItems.observationIds.append(markerItem.itemId)
            case .srva:
                clusteredItems.srvaIds.append(markerItem.itemId)
            case .pointOfInterest:
                clusteredItems.pointOfInterests.append(markerItem.itemId)
                break
            }
        }

        onDisplayClusterItems(clusteredItems)
    }

    private func getDelegateClickHandler(itemType: MapMarkerType) -> OnMapMarkerClicked? {
        switch itemType {
        case .harvest:
            return onHarvestMarkerClicked
        case .observation:
            return onObservationMarkerClicked
        case .srva:
            return onSrvaMarkerClicked
        case .pointOfInterest:
            return onPointOfInterstClicked
        }
    }
}
