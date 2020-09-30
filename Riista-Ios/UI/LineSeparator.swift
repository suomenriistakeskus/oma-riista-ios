import UIKit

/**
    Horizontal line separator. One pixel visible height. Color defined in storyboard.
 */
class LineSeparator: UIView {

    override func awakeFromNib() {
        let sortaPixel: CGFloat = 1.0/UIScreen.main.scale

        let topSeparatorView = UIView()
        topSeparatorView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: sortaPixel)

        topSeparatorView.isUserInteractionEnabled = false
        topSeparatorView.backgroundColor = self.backgroundColor

        self.addSubview(topSeparatorView)
        self.backgroundColor = UIColor.clear

        self.isUserInteractionEnabled = false
    }
}
