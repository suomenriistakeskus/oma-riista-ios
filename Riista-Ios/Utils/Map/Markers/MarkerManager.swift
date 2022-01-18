import Foundation

protocol MarkerManager {
    associatedtype MarkerType: Hashable

    func removeAllMarkers()

    func addMarkerSource(markerType: MarkerType, source: MarkerSource)

    func showMarkersOfType(markerTypes: [MarkerType])
}


extension MarkerManager {
    func showOnlyMarkersOfType(markerTypes: [MarkerType]) {
        removeAllMarkers()
        showMarkersOfType(markerTypes: markerTypes)
    }
}
