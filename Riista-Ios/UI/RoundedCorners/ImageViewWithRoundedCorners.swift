import Foundation
import SnapKit



/**
 * An imageview that can have rounded corners.
 *
 * Rounding corners works quite nicely on > iOS11 even without base class that has the support. For iOS 10 the rounding
 * needs to occur when bounds are known (i.e. layoutSubviews)
 */
class ImageViewWithRoundedCorners: UIImageView {

    var cornerRadius: CGFloat {
        get { roundedCornersHelper.cornerRadius }
        set(value) { roundedCornersHelper.cornerRadius = value }
    }

    var roundedCorners: CACornerMask {
        get { roundedCornersHelper.roundedCorners }
        set(value) { roundedCornersHelper.roundedCorners = value }
    }

    private lazy var roundedCornersHelper: RoundedCornersHelper = {
        RoundedCornersHelper(view: self)
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        roundedCornersHelper.onLayoutSubviews()
    }
}
