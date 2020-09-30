import UIKit

public protocol OnboardingPresenter: class {

    var pageCount: Int {
        get
    }

    var cellProviders: [Int: CellProvider] {
        get
    }

    var defaultProvider: CellProvider? {
        get
    }

    var landingProvider: CellProvider? {
        get
    }

    var onOnboardingSkipped: ( () -> () )? {
        get
        set
    }

    var onOnBoardingFinished: ( () -> () )? {
        get
        set
    }

    func visibilityChanged(for cell: UICollectionViewCell, at index: Int, amount: CGFloat)

    func style(pageControl: UIPageControl?)

    func style(collection: UICollectionView?)

    func style(cell: UICollectionViewCell, for page: Int)

    func reuseIdentifier(for page: Int) -> String

}

extension OnboardingPresenter {

    public func reuseIdentifier(for page: Int) -> String {
        // guard let provider = cellProviders[page] == nil ? defaultProvider : cellProviders[page] else {
        guard let provider = page == 0 ? landingProvider : defaultProvider else {
            return ""
        }

        switch provider {
        case .nib(_, let identifier, _):
            return identifier
        case .cellClass(_, let identifier):
            return identifier
        }
    }

}

public enum CellProvider {

    case nib(name:String, identifier: String, bundle: Bundle?)
    case cellClass(className: Swift.AnyClass, identifier: String)

}
