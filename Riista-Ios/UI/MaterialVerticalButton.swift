import Foundation
import MaterialComponents

class MaterialVerticalButton: MDCButton {

    private var iconSize = CGSize(width: 32, height: 32)
    private let padding: CGFloat = 16

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let titleLabel = titleLabel, let imageView = imageView else {
            return
        }

        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingMiddle
        imageView.contentMode = .scaleAspectFit

        titleLabel.frame.origin.x = 0
        titleLabel.frame.size.width = bounds.size.width

        imageView.frame.size = iconSize
        imageView.frame.origin.x = (bounds.size.width - imageView.bounds.size.width) / 2.0

        let contentHeight = imageView.bounds.size.height + padding + titleLabel.bounds.size.height
        imageView.frame.origin.y = (bounds.size.height - contentHeight) / 2.0
        titleLabel.frame.origin.y = imageView.frame.maxY + padding
    }
}


