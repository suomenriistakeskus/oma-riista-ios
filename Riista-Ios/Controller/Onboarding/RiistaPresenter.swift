import UIKit

open class RiistaPresenter: BasePresenter {

    override public init() {
        super.init()

        let language = RiistaSettings.language()
        let image_suffix: String

        switch language {
        case "en":
            image_suffix = "_en"
        case "sv":
            image_suffix = "_sv"
        default:
            image_suffix = ""
        }

        model = [
            OnboardingSlide(titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingIntroduction"),
                            image: nil),
            OnboardingSlide(titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingMapTitle"),
                            image: UIImage(named: "intro_map" + image_suffix)),
            OnboardingSlide(titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingGalleryTitle"),
                            image: UIImage(named: "intro_gallery" + image_suffix)),
            OnboardingSlide(titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingShootingTestTitle"),
                            image: UIImage(named: "intro_shooting_test" + image_suffix)),
            OnboardingSlide(titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboaringMetsahallitusTitle"),
                            image: UIImage(named: "intro_metsahallitus" + image_suffix)),
        ]

        cellBackgroundColor = .white
    }

    override open func style(cell: UICollectionViewCell, for page: Int) {
        super.style(cell: cell, for: page)
    }

    override open func visibilityChanged(for cell: UICollectionViewCell, at index: Int, amount: CGFloat) {
        guard let cell = cell as? OnboardingImageCell, index == pageCount - 1  else { return }

        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }
}
