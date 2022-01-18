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
        guard let parentView = viewToOverlay ?? parentViewController.view else {
            print("No parent view, cannot display")
            return self
        }

        self.view.frame = parentView.bounds

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

    func hide() {
        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            self.view.alpha = 0
        } completion: { [weak self] _ in
            self?.willMove(toParent: nil)
            self?.view.removeFromSuperview()
            self?.removeFromParent()
        }
    }
}
