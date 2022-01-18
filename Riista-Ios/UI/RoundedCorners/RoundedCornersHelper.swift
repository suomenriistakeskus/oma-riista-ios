import Foundation

class RoundedCornersHelper {
    var cornerRadius: CGFloat = 0.0 {
        didSet {
            cornersInvalidated = true
        }
    }

    var roundedCorners: CACornerMask = [] {
        didSet {
            cornersInvalidated = true
        }
    }

    private var cornersInvalidated: Bool = false {
        didSet {
            if (cornersInvalidated) {
                view?.setNeedsLayout()
            }
        }
    }

    /**
     * The view which corners are being rounded.
     */
    private weak var view: UIView?

    private var cachedViewBounds: CGRect = CGRect.zero

    init(view: UIView) {
        self.view = view
    }

    func onLayoutSubviews() {
        guard let viewBounds = view?.bounds else {
            print("Cannot update rounded corners, no view")
            return
        }

        if (shouldUpdateRoundedCorners(viewBounds: viewBounds)) {
            updateRoundedCorners(viewBounds: viewBounds)
        }
    }

    private func shouldUpdateRoundedCorners(viewBounds: CGRect) -> Bool {
        if (cornersInvalidated) {
            return true
        }

        // rounded corners are implemented differently on iOS10 and thus rounded corners
        // need to be updated whenever bounds change
        if #available(iOS 11.0, *) {
            return false
        }

        return cachedViewBounds != viewBounds
    }

    private func updateRoundedCorners(viewBounds: CGRect) {
        cornersInvalidated = false
        cachedViewBounds = viewBounds
        view?.roundCorners(corners: roundedCorners, cornerRadius: cornerRadius)
    }
}
