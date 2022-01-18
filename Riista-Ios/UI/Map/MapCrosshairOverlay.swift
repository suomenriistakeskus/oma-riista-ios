import Foundation
import SnapKit

/**
 * Wraps a crosshair view to be displayed on top of the map.
 *
 * Usage:
 * - cover the whole map with this overlay view (and take layoutMargins into account). Crosshair is centered within the overlay.
 *
 * Crosshair is not implemented internally in the mapview because centering the cross hair to camera is difficult if added as a map subview.
 * - map will probably be constrained to screen.top and bottom but map camera is constrained to centerY within layout margins
 * --> crosshair needs to be constrained similarly.
 */
class MapCrosshairOverlay: OverlayView {

    lazy var crosshairView: UIImageView = {
        let crosshair = UIImageView()
        crosshair.image = UIImage(named: "crosshair.png")
        return crosshair
    }()

    var crosshairVisible: Bool {
        get {
            !crosshairView.isHidden
        }
        set(visible) {
            crosshairView.isHidden = !visible
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

    private func setup() {
        addSubview(crosshairView)
        crosshairView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
