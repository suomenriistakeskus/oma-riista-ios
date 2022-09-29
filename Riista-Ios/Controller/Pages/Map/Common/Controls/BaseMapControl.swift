import Foundation


class BaseMapControl: MapControl {
    let type: MapControlType

    private(set) var controlVisible: Bool = false

    init(type: MapControlType) {
        self.type = type
    }

    func onViewWillAppear() {
        controlVisible = true
    }

    func onViewWillDisappear() {
        controlVisible = false
    }

    func onMapPositionChanged() {
        // nop
    }

    func registerControls(overlayControlsView: MapControlsOverlayView) {
        // nop
    }
}
