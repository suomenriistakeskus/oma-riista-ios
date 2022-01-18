import Foundation
import GoogleMaps

typealias MapLayerId = Int

/**
 * A custom GMSMapView providing common configuration as well as common UI (e.g. crossHair).
 *
 * The controls as well as other overlay UI elements such as copyright labels are separated to MapControlsContainerView.
 * This separation allows constraining map to full screen while overlays are constrained to layout guides.
 */
class RiistaMapView: GMSMapView {

    /**
     * The tile layer to be used for displaying MML tiles.
     */
    private var tileLayerForBackgroundMaps: RiistaMmlTileLayer?

    /**
     * The overlay layers by type.
     */
    private var mapOverlayLayers: [MapLayerId : RiistaVectorTileLayer] = [:]

    /**
     * Gets the largest MapLayerId found in the overlay layers.
     */
    var maxOverlayLayerId: Int {
        get {
            return mapOverlayLayers.keys.sorted().last ?? -1
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }


    // MARK: Interaction

    enum ZoomDirection {
        case zoomIn(amount: Float = 1.0)
        case zoomOut(amount: Float = 1.0)
    }

    func zoomAnimated(direction: ZoomDirection) {
        let cameraUpdate = GMSCameraUpdate.zoom(by: getZoomDelta(direction: direction))
        animate(with: cameraUpdate)
    }

    /**
     * Zooms in or out so that given targetCoordinate will be placed at center of the screen.
     */
    func zoomAnimated(direction: ZoomDirection, targetCoordinate: CLLocationCoordinate2D) {
        let targetZoom = camera.zoom + getZoomDelta(direction: direction)
        let cameraUpdate = GMSCameraUpdate.setTarget(targetCoordinate, zoom: targetZoom)
        animate(with: cameraUpdate)
    }

    private func getZoomDelta(direction: ZoomDirection) -> Float {
        switch direction {
        case .zoomIn(let amount):   return abs(amount)
        case .zoomOut(let amount):  return -abs(amount)
        }
    }

    // MARK: Configuration

    func setMapType(type: RiistaMapType) {
        if (type == GoogleMapType) {
            self.mapType = .normal

            if let tileLayer = tileLayerForBackgroundMaps {
                tileLayer.map = nil
                self.tileLayerForBackgroundMaps = nil
            }
        } else {
            self.mapType = .none
            let tileLayer = self.tileLayerForBackgroundMaps ?? RiistaMmlTileLayer()
            tileLayer.setMapType(type)
            tileLayer.map = self

            self.tileLayerForBackgroundMaps = tileLayer
        }
    }

    func hasMapLayer(layerId: MapLayerId) -> Bool {
        return mapOverlayLayers[layerId] != nil
    }

    func addMapLayer(layerId: MapLayerId, areaType: AppConstants.AreaType, zIndex: Int) {
        removeMapLayer(layerId: layerId)

        let layer = RiistaVectorTileLayer()
        layer.setAreaType(areaType.rawValue)
        layer.zIndex = Int32(zIndex)
        layer.map = self
        mapOverlayLayers[layerId] = layer
    }

    func configureMapLayer(layerId: MapLayerId,
                           externalId: String?,
                           invertLayerColors: Bool = false) {
        guard let layer = mapOverlayLayers[layerId] else {
            print("No layer for \(layerId)!")
            return
        }

        layer.setExternalId(externalId)
        layer.setInvertColors(invertLayerColors)
    }

    func setMapLayerVisibility(layerId: MapLayerId, visible: Bool) {
        // layers manage their visibility internally based on external id
        configureMapLayer(layerId: layerId, externalId: visible ? "-1" : nil)
    }

    func removeMapLayer(layerId: MapLayerId) {
        if let layer = mapOverlayLayers.removeValue(forKey: layerId) {
            layer.map = nil
        }
    }

    private func setup() {
        settings.rotateGestures = false
        settings.tiltGestures = false
        setMinZoom(AppConstants.Map.MinZoom, maxZoom: AppConstants.Map.MaxZoom)
    }
}


internal extension RiistaMapView {
    func addMapLayer(areaType: AppConstants.AreaType, zIndex: Int) {
        addMapLayer(layerId: areaType.getDefaultLayerId(), areaType: areaType, zIndex: zIndex)
    }

    func configureMapLayer(areaType: AppConstants.AreaType,
                           externalId: String?,
                           invertLayerColors: Bool = false) {
        configureMapLayer(
            layerId: areaType.getDefaultLayerId(),
            externalId: externalId,
            invertLayerColors: invertLayerColors
        )
    }

    func setMapLayerVisibility(areaType: AppConstants.AreaType, visible: Bool) {
        setMapLayerVisibility(layerId: areaType.getDefaultLayerId(), visible: visible)
    }
}

internal extension AppConstants.AreaType {
    func getDefaultLayerId() -> Int {
        rawValue
    }
}
