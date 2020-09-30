import Foundation
import UIKit

open class OnboardingImageCell: UICollectionViewCell {

    static let reuseIdentifier = String(describing: OnboardingImageCell.self)

    @IBOutlet public weak var imageView: UIImageView!
    @IBOutlet public weak var titleLabel: UILabel!

    override open func awakeFromNib() {
        super.awakeFromNib()

        setNeedsLayout()
    }

}
