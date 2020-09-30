import UIKit
import MaterialComponents

open class RiistaOnbardingController: OnboardingViewController {

    weak var nextButton: MDCButton!
    weak var skipButton: MDCButton!

    override open func viewDidLoad() {
        presenter = RiistaPresenter()
        presenter.onOnBoardingFinished = { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        }

        super.viewDidLoad()

        setupSkipButton()
        setupNextButton()
    }

    open func setupNextButton() {
        AppTheme.shared.setupTextButtonTheme(button: nextButton)

        nextButton.setImage(UIImage(named: "arrow_forward.png")?.resizedImageToFit(in:CGSize(width: 20.0, height: 20.0),
                                                                                   scaleIfSmaller: false), for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped(sender:)), for: .touchUpInside)
    }

    open func setupSkipButton() {
        AppTheme.shared.setupTextButtonTheme(button: skipButton)

        skipButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingSkip"), for: .normal)
        skipButton?.addTarget(self, action: #selector(skipTapped(sender:)), for: .touchUpInside)
    }

    override open func pageChanged(to page: Int) {
        pageControl?.currentPage = page

        skipButton.isHidden = page == presenter.pageCount - 1

        nextButton.setTitle(page == presenter.pageCount - 1 ? RiistaBridgingUtils.RiistaLocalizedString(forkey: "OnboardingDone") : nil, for: .normal)
        nextButton.setImage(page == presenter.pageCount - 1 ? nil : UIImage(named: "arrow_forward.png")?.resizedImageToFit(in:CGSize(width: 20.0, height: 20.0), scaleIfSmaller: false), for: .normal)
    }

    override open func createPageControl() {
        let pageControl: UIPageControl = {
            let frame = CGRect(x: 0, y: 0, width: 100, height: 30)
            let control = UIPageControl(frame: frame)
            control.backgroundColor = UIColor.applicationColor(Primary)
            control.translatesAutoresizingMaskIntoConstraints = false
            return control
        }()

        view.addSubview(pageControl)
        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .centerX, relatedBy: .equal, toItem: pageControl, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        pageControl.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -pageControlBottomConstant).isActive = true
        view.bringSubviewToFront(pageControl)
        self.pageControl = pageControl

        let buttonFrame = CGRect(x: 0, y: 0, width: 100, height: 30)

        let localSkipButton = MDCButton(frame: buttonFrame)
        self.skipButton = localSkipButton
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipButton)
        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .left, relatedBy: .equal, toItem: skipButton, attribute: .left, multiplier: 1.0, constant: -10.0))
        skipButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -10.0).isActive = true
        view.bringSubviewToFront(skipButton)

        let localNextButton = MDCButton(frame: buttonFrame)
        self.nextButton = localNextButton
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .right, relatedBy: .equal, toItem: nextButton, attribute: .right, multiplier: 1.0, constant: 10.0))
        nextButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -10.0).isActive = true
        view.bringSubviewToFront(nextButton)
    }

    @objc open func nextTapped(sender: UIButton) {
        if currentPage == presenter.pageCount - 1 {
            dismiss(animated: true, completion: nil)
        } else {
            currentPage = currentPage + 1
            let index = IndexPath(row: currentPage, section: 0)
            collectionView?.scrollToItem(at: index, at: UICollectionView.ScrollPosition.left, animated: true)
        }
    }

    @objc open func skipTapped(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
