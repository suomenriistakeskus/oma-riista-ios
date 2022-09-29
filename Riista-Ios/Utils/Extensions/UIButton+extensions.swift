import Foundation

extension UIButton {

    // according to https://stackoverflow.com/a/25559946
    // - RTL not supported
    func setSpacingBetweenImageAndTitle(spacing: CGFloat, contentEdgeInsets: UIEdgeInsets) {
        let insetAmount = spacing / 2

       imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
       titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        self.contentEdgeInsets = UIEdgeInsets(
            top: 0 + contentEdgeInsets.top,
            left: insetAmount + contentEdgeInsets.left,
            bottom: 0 + contentEdgeInsets.bottom,
            right: insetAmount + contentEdgeInsets.right
        )
    }
}
