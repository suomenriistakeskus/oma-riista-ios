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

    init(view: UIView) {
        self.view = view
    }

    func onLayoutSubviews() {
        guard let viewBounds = view?.bounds else {
            print("Cannot update rounded corners, no view")
            return
        }

        if (cornersInvalidated) {
            updateRoundedCorners(viewBounds: viewBounds)
        }
    }

    private func updateRoundedCorners(viewBounds: CGRect) {
        cornersInvalidated = false
        view?.roundCorners(corners: roundedCorners, cornerRadius: cornerRadius)
    }
}
