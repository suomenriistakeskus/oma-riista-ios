import Foundation

enum MapControlType {
    case moveToUserLocation
    case zoom
    case toggleFullscreen
    case measureDistance
}

protocol MapControl {
    var type: MapControlType { get }

    func onViewWillAppear()
    func onViewWillDisappear()

    func onMapPositionChanged()

    func registerControls(overlayControlsView: MapControlsOverlayView)
}
