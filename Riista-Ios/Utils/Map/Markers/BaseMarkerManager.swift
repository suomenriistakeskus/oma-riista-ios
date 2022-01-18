import Foundation
import GoogleMapsUtils


class BaseMarkerManager<MarkerType : Hashable, MarkerItemType : GMUClusterItem>:
    NSObject, MarkerManager, GMUClusterManagerDelegate, GMUClusterRendererDelegate {

    typealias MarkerType = MarkerType

    let mapView: GMSMapView
    weak var mapViewDelegate: GMSMapViewDelegate?

    /**
     * A click handler for the markers / clusters.
     */
    weak var markerClickHandler: MarkerClickHandler<MarkerItemType>?


    private(set) lazy var clusterManager: GMUClusterManager = {
        createConfiguredClusterManager()
    }()

    var markerSources = [MarkerType : MarkerSource]()

    init(mapView: GMSMapView, mapViewDelegate: GMSMapViewDelegate?) {
        self.mapView = mapView
        self.mapViewDelegate = mapViewDelegate
    }


    // MARK: MarkerManager

    func removeAllMarkers() {
        clusterManager.clearItems()
    }

    func addMarkerSource(markerType: MarkerType, source: MarkerSource) {
        markerSources[markerType] = source
    }

    func showMarkersOfType(markerTypes: [MarkerType]) {
        markerSources.forEach { (markerType, markerSource) in
            if (markerTypes.contains(markerType)) {
                markerSource.addMarkers(to: clusterManager)
            }
        }

        clusterManager.cluster()
    }


    // MARK: GMUClusterManagerDelegate

    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        return markerClickHandler?.onMarkerClusterClicked(cluster: cluster) ?? false
    }

    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        if let item = clusterItem as? MarkerItemType {
            return markerClickHandler?.onMarkerItemClicked(item: item) ?? false
        }

        return false
    }

    // MARK: Marker rendering

    /**
     * Catches the render call and propagates call to updateMarkerIcon() for non-cluster markers
     */
    func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
        if let markerItem = marker.userData as? MarkerItemType {
            updateMarkerIcon(marker: marker, markerItem: markerItem)
        }
    }

    /**
     * Needs to be subclassed in order to apply custom icons for markers.
     *
     * Superclass implementation should probably not be called..
     */
    func updateMarkerIcon(marker: GMSMarker, markerItem: MarkerItemType) {
        print("Custom markerIcon not applied!")
    }

    // MARK: Cluster Manager creation + configuration

    /**
     * Creates a GMUClusterManager based on mapView and results of createClusterAlgorithm(),
     * createClusterRenderer() and createClusterIconGenerator()
     *
     * Can be subclassed if necessary.
     */
    func createConfiguredClusterManager() -> GMUClusterManager {
        let algorithm = createClusterAlgorithm()
        let renderer = createClusterRenderer()

        let clusterManager =  GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager.setDelegate(self, mapDelegate: mapViewDelegate)
        return clusterManager
    }

    /**
     * Can be subclassed if necessary.
     */
    func createClusterAlgorithm() -> GMUClusterAlgorithm {
        GMUNonHierarchicalDistanceBasedAlgorithm(clusterDistancePoints: 50)
    }

    /**
     * Can be subclassed if necessary.
     */
    func createClusterRenderer() -> GMUClusterRenderer{
        GMUDefaultClusterRenderer(
            mapView: mapView,
            clusterIconGenerator: createClusterIconGenerator()
        ).apply { renderer in
            renderer.minimumClusterSize = 2
            renderer.delegate = self
        }
    }

    /**
     * Can be subclassed if necessary.
     */
    func createClusterIconGenerator() -> GMUClusterIconGenerator {
        GMUDefaultClusterIconGenerator()
    }
}
