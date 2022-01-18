import Foundation
import SnapKit

/**
 * A separator view to be used when creating layouts programmatically.
 *
 * Determines the thickness and color of the separator. The length of the separator is not constrained.
 */
class SeparatorView: UIView {

    private(set) var orientation: NSLayoutConstraint.Axis = .horizontal

    init(orientation: NSLayoutConstraint.Axis) {
        super.init(frame: CGRect.zero)
        self.orientation = orientation
        setup()
    }

    init(orientation: NSLayoutConstraint.Axis, frame: CGRect) {
        super.init(frame: frame)
        self.orientation = orientation
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor.applicationColor(GreyLight)
        self.snp.makeConstraints { make in
            if (self.orientation == .horizontal) {
                constrainSizeTo(height: 1)
            } else {
                constrainSizeTo(width: 1)
            }
        }
    }
}
