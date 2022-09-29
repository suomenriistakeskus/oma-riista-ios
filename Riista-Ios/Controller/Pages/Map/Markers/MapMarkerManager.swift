import Foundation

class MapMarkerManager: BaseMarkerManager<MapMarkerType, MapMarkerItem> {
    let markerStorage = MapMarkerStorage()

    private lazy var markerIcons: [MapMarkerType : UIImage] = {
        [
            // require marker images to exist -> use '!'
            .harvest : UIImage(named: "pin_harvest")!,
            .observation : UIImage(named: "pin_observation")!,
            .srva : UIImage(named: "pin_srva")!,
            .pointOfInterest : UIImage(named: "pin_harvest_rejected")!
        ]
    }()

    override init(mapView: GMSMapView, mapViewDelegate: GMSMapViewDelegate?) {
        super.init(mapView: mapView, mapViewDelegate: mapViewDelegate)

        addMarkerSource(markerType: .harvest,
                        source: MapMarkerSource.harvests(using: markerStorage))
        addMarkerSource(markerType: .observation,
                        source: MapMarkerSource.observations(using: markerStorage))
        addMarkerSource(markerType: .srva,
                        source: MapMarkerSource.srvas(using: markerStorage))
        addMarkerSource(markerType: .pointOfInterest,
                        source: MapMarkerSource.pointsOfInterest(using: markerStorage))
    }

    override func updateMarkerIcon(marker: GMSMarker, markerItem: MapMarkerItem) {
        if (markerItem.type == .pointOfInterest) {
            if case .pointOfInterest(let pointOfInterest) = markerItem.itemId {
                PointOfInterestMarkerImageCache.shared.getOrRenderMarkerIcon(for: pointOfInterest) { icon in
                    if let icon = icon {
                        marker.icon = icon
                    } else {
                        // Fallback to using iconView. It is possible that rendering the image fails
                        // on some devices for some unknown reason thus requiring this fallback.
                        //
                        // Prefer rendered image though as it is way more performant. Using 'iconView'
                        // causes higher CPU usage and thus battery won't last as long as with 'icon'
                        // if points of interest are displayed on the map.
                        let poiView = PointOfInterestMarkerView()
                        poiView.configureValues(markerData: pointOfInterest.toMarkerData())
                        marker.iconView = poiView
                    }
                }
            } else {
                print("Marker didn't have PointOfInterest even thought type was \(markerItem.type)")
            }
        } else {
            marker.icon = markerIcons[markerItem.type]
        }
    }
}

