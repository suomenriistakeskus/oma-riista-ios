import Foundation

/**
 * A custom UIStackView that can be used as an overlay to another view and has following characteristics:
 * - overlay subviews can react to touch events
 * - overlay does not react to touch events
 *
 * todo: add support to stealing touches i.e. if a 'stealTouches' flag is enabled, the view will steal all touch events
 */
class OverlayStackView: UIStackView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if (view == self) {
            return nil
        } else {
            return view
        }
    }
}
