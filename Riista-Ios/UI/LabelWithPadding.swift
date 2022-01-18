import Foundation

/**
 * A UILabel that supports padding / edge insets
 *
 * Heavily based on https://stackoverflow.com/a/58876988 with the exception of number of lines
 * i.e. doesn't allow multiline content unless set from outside.
 */
class LabelWithPadding: LabelWithRoundedCorners {
    var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero

    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height = contentSize.height + edgeInsets.top + edgeInsets.bottom
            contentSize.width = contentSize.width + edgeInsets.left + edgeInsets.right
            return contentSize
        }
    }

    override func drawText(in rect: CGRect) {
        let rectWithEdgeInsets = rect.inset(by: edgeInsets)
        super.drawText(in: rectWithEdgeInsets)
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let rectWithEdgeInsets = bounds.inset(by: edgeInsets)
        return super.textRect(forBounds: rectWithEdgeInsets, limitedToNumberOfLines: numberOfLines)
    }
}
