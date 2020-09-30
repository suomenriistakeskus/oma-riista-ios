import Foundation

extension UIView {
    @objc func removeAllSubviews() {
        let subviewsToBeRemoved = self.subviews
        for subview in subviewsToBeRemoved {
            subview.removeFromSuperview()
        }
    }
}
