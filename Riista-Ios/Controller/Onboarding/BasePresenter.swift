import UIKit

public struct OnboardingSlide {

    public let titleText: String
    public let image: UIImage?

    public init(titleText: String, image: UIImage?) {
        self.titleText = titleText
        self.image = image
    }
}

open class BasePresenter: OnboardingPresenter {
    // MARK: Customizable properties
    public var cellBackgroundColor: UIColor = .orange

    open var model: [OnboardingSlide] = []

    // MARK: OnboardingPresenter protocol
    public var onOnBoardingFinished: (() -> ())?
    public var onOnboardingSkipped: (() -> ())?

    public var cellProviders: [Int: CellProvider] {
        return [:]
    }

    public var defaultProvider: CellProvider? = .nib(
        name:"OnboardingImageCell",
        identifier: OnboardingImageCell.reuseIdentifier,
        bundle: Resources.bundle
    )

    public var landingProvider: CellProvider? = .nib(
        name: "OnboardingLandingCell",
        identifier: OnboardingLandingCell.reuseIdentifier,
        bundle: Resources.landingBundle
    )

    public var pageCount: Int {
        return model.count
    }

    public init() {}

    open func visibilityChanged(for cell: UICollectionViewCell, at index: Int, amount: CGFloat) {
        guard let cell = cell as? OnboardingImageCell, index == pageCount - 1  else { return }
//        cell.doneButtonBottomConstraint.constant = 60 * amount
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }

    open func style(pageControl: UIPageControl?) {
        pageControl?.backgroundColor = .clear
        pageControl?.numberOfPages = pageCount
        pageControl?.pageIndicatorTintColor = UIColor.applicationColor(GreyLight)
        pageControl?.currentPageIndicatorTintColor = UIColor.applicationColor(Primary)
    }

    open func style(collection: UICollectionView?) { }

    @objc open func didFinishOnboarding() {
        onOnBoardingFinished?()
    }

    open func didSkipOnboarding() {
        onOnboardingSkipped?()
    }

    open func style(cell: UICollectionViewCell, for page: Int) {
        guard let cell1 = cell as? OnboardingImageCell else {
            guard let cell2 = cell as? OnboardingLandingCell else {
                return
            }
            cell2.backgroundColor = cellBackgroundColor
            return
        }
        cell1.backgroundColor = cellBackgroundColor

        cell1.titleLabel.text = model[page].titleText
        cell1.imageView?.image = model[page].image
    }

}
