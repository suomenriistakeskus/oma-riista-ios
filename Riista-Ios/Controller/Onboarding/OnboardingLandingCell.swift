import Foundation
import UIKit

open class OnboardingLandingCell: UICollectionViewCell {

    static let reuseIdentifier = String(describing: OnboardingLandingCell.self)

    @IBOutlet public weak var descriptionLabel: UILabel!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var item1Label: UILabel!
    @IBOutlet public weak var item2Label: UILabel!
    @IBOutlet public weak var item3Label: UILabel!
    @IBOutlet public weak var item4Label: UILabel!

    override open func awakeFromNib() {
        super.awakeFromNib()

        descriptionLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingIntroduction")
        titleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingNewFeaturesTitle").uppercased()
        item1Label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingNewFeatureMaps")
        item2Label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingGalleryTitle")
        item3Label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingShootingTestTitle")
        item4Label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboaringMetsahallitusTitle")

        setNeedsLayout()
    }

}
