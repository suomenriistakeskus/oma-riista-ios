import Foundation

class MapZoomControls: BaseMapControl {

    private weak var mapView: RiistaMapView?

    init(mapView: RiistaMapView) {
        super.init(type: .zoom)
        self.mapView = mapView
    }

    override func registerControls(overlayControlsView: MapControlsOverlayView) {
        overlayControlsView.addEdgeControl(image: UIImage(named: "zoom_in")) { [weak self] in
            if let mapView = self?.mapView {
                mapView.animate(toZoom: mapView.camera.zoom + 1)
            }
        }
        overlayControlsView.addEdgeControl(image: UIImage(named: "zoom_out")) { [weak self] in
            if let mapView = self?.mapView {
                mapView.animate(toZoom: mapView.camera.zoom - 1)
            }
        }
    }
}
