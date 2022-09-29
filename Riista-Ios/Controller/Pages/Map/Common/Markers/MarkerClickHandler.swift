import Foundation
import GoogleMapsUtils


class MarkerClickHandler<MarkerItemType : GMUClusterItem> {
    func onMarkerClusterClicked(cluster: GMUCluster) -> Bool {
        return false
    }

    func onMarkerItemClicked(item: MarkerItemType) -> Bool {
        return false
    }
}

/**
 * A default marker click handler that provides the default implementation for handling marker cluster clicks.
 */
class DefaulClusterClickHandler<MarkerItemType : GMUClusterItem> : MarkerClickHandler<MarkerItemType> {
    private weak var mapView: RiistaMapView?


    init(mapView: RiistaMapView) {
        super.init()
        self.mapView = mapView
    }

    override func onMarkerClusterClicked(cluster: GMUCluster) -> Bool {
        guard let mapView = mapView else {
            print("No mapview, cannot handle cluster click!")
            return false
        }

        if (cluster.areMarkersRoughlyInSameLocation()) {
            notifyClusterRequiresExpand(cluster: cluster)
        } else if (mapView.camera.zoom >= (mapView.maxZoom - 1)) {
            notifyClusterRequiresExpand(cluster: cluster)
        } else {
            mapView.zoomAnimated(
                direction: .zoomIn(amount: 2),
                targetCoordinate: cluster.position
            )
        }

        return true
    }

    func notifyClusterRequiresExpand(markerItems: [MarkerItemType]) {
        print("Don't know how to expand cluster.. maybe you should override this function in subclass?")
    }

    private func notifyClusterRequiresExpand(cluster: GMUCluster) {
        let markerItems = cluster.items.compactMap { clusterItem in
            clusterItem as? MarkerItemType
        }

        notifyClusterRequiresExpand(markerItems: markerItems)
    }
}

fileprivate extension GMUCluster {
    func areMarkersRoughlyInSameLocation() -> Bool {
        guard let centerMarkerLocation = items.first?.position.toLocation() else {
            return false
        }

        let radiusMeters: CLLocationDistance = 40
        for item in items {
            if (item.position.toLocation().distance(from: centerMarkerLocation) > radiusMeters) {
                return false
            }
        }

        return true
    }
}
