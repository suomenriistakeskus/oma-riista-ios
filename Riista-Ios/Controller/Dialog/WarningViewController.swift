import Foundation


class WarningViewController: UIViewController {

    /**
     * A convenience function for displaying `WarningViewController` is non-dismissible way i.e.
     * by replacing all viewcontrollers with it)
     */
    class func showAsNonDismissible(
        parentViewController: UIViewController,
        navBarTitle: String?,
        messageTitle: String?,
        message: String?,
        buttonText: String?,
        buttonOnClicked: OnClicked?
    ) {
        let viewController = WarningViewController(
            navBarTitle: navBarTitle,
            messageTitle: messageTitle,
            message: message,
            buttonText: buttonText,
            buttonOnClicked: buttonOnClicked
        )

        parentViewController.navigationController?.setViewControllers([viewController], animated: true)
    }

    private(set) var warningView: WarningView

    init(
        navBarTitle: String?,
        messageTitle: String?,
        message: String?,
        buttonText: String?,
        buttonOnClicked: OnClicked?
    ) {
        self.warningView = WarningView(
            titleText: messageTitle,
            messageText: message,
            buttonText: buttonText,
            buttonOnClicked: buttonOnClicked
        )

        super.init(nibName: nil, bundle: nil)

        self.title = navBarTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * A convenience function for displaying `WarningViewController` is non-dismissible way i.e.
     * by replacing all viewcontrollers with it)
     */
    func showAsNonDismissible(
        parentViewController: UIViewController
    ) {
        parentViewController.navigationController?.setViewControllers([self], animated: true)
    }

    override func loadView() {
        // add constraints according to:
        // https://developer.apple.com/library/archive/technotes/tn2154/_index.html
        view = UIView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)

        view.addSubview(warningView)
        warningView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}
