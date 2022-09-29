import Foundation
import MaterialComponents

class MaterialVerticalButton: MDCButton {

    var iconSize = CGSize(width: 32, height: 32)
    private let padding: CGFloat = 4
    private let contentInsetHorizontal: CGFloat = 4

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let titleLabel = titleLabel, let imageView = imageView else {
            return
        }

        forceTitleLabelFrameSizeToTwoLines()

        // title label is forced to two lines. Move the whole content slightly downwards so that it appears
        // to be more balanced vertically in most cases (when not multilining content)
        let multilineTextAdjustment: CGFloat = 8

        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = iconSize
        imageView.frame.origin.x = (bounds.size.width - imageView.bounds.size.width) / 2.0

        let contentHeight = imageView.bounds.size.height + padding + titleLabel.bounds.size.height
        imageView.frame.origin.y = (bounds.size.height - contentHeight) / 2.0 + multilineTextAdjustment
        titleLabel.frame.origin.x = contentInsetHorizontal
        titleLabel.frame.origin.y = imageView.frame.maxY + padding
    }

    private func forceTitleLabelFrameSizeToTwoLines() {
        guard let titleLabel = titleLabel else { return }

        let titleLabelMaxWidth = bounds.size.width - 2 * contentInsetHorizontal

        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.preferredMaxLayoutWidth = titleLabelMaxWidth

        // text will be automatically wrapped to two lines now if needed. We do, however, need
        // to adjust frame to contain space for two lines in all cases in order to  make sure
        // that adjacent items such as SRVA and "my details" are aligned correctly.
        // - icons should be at same level
        // - text should align so that they appear vertically centered
        //
        // we could probably utilize label's intrinsicContentSize but there seemed to be
        // at least one infinite loop during testing with that approach. Instead of using that
        // calculate text size using the current font.
        guard let titleText = titleLabel.text, let titleFont = titleLabel.font else {
            // nothing we can do
            return
        }

        let textHeight = ceil((titleText as NSString).size(withAttributes: [NSAttributedString.Key.font: titleFont]).height)
        titleLabel.frame.size = CGSize(width: titleLabelMaxWidth, height: textHeight * 2)
    }
}


