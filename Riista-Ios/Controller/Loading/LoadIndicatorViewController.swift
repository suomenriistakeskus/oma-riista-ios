import Foundation
import SnapKit

class LoadIndicatorViewController: UIViewController {
    lazy var loadingIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            indicator.style = .large
        } else {
            indicator.style = .whiteLarge
        }
        indicator.color = .white
        return indicator
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.6)

        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingIndicatorView.startAnimating()
    }

    func showIn(parentViewController: UIViewController,
                viewToOverlay: UIView? = nil) -> LoadIndicatorViewController {
        let parentView: UIView
        if let viewToOverlay = viewToOverlay, let parentViewCandidate = viewToOverlay.superview {
            // try to add as a sibling to viewToOverlay as that allows preventing touches from passing
            // to view that is being overlaid
            // -> no need for separate user input disabling (e.g. uitableview) which can be an issue
            //    (e.g. uitableview seems to jump slightly when is isScrollEnabled is toggled)
            self.view.frame = viewToOverlay.frame
            parentView = parentViewCandidate
        } else if let parentViewCandidate = parentViewController.view {
            // no specific viewToOverlay i.e. fill the parentViewController.view
            self.view.frame = parentViewCandidate.bounds
            parentView = parentViewCandidate
        } else {
            print("No parent view, cannot display")
            return self
        }

        willMove(toParent: parentViewController)
        parentViewController.addChild(self)
        self.view.alpha = 0
        parentView.addSubview(self.view)
        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            self.view.alpha = 1
        }
        didMove(toParent: parentViewController)

        return self
    }

    func hide(_ completion: OnCompleted? = nil) {
        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            self.view.alpha = 0
        } completion: { [weak self] _ in
            self?.willMove(toParent: nil)
            self?.view.removeFromSuperview()
            self?.removeFromParent()

            completion?()
        }
    }
}
