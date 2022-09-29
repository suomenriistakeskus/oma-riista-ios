import Foundation
import MaterialComponents.MaterialProgressView

@objc class MainNavigationController: UINavigationController, UINavigationControllerDelegate {

    @objc class func setupGlobalNavigationBarAppearance() {
        if #available(iOS 13.0, *) {
            let customAppearance = getGlobalNavBarAppearance()

            let navBarAppearance = UINavigationBar.appearance()
            navBarAppearance.scrollEdgeAppearance = customAppearance
            navBarAppearance.compactAppearance = customAppearance
            navBarAppearance.standardAppearance = customAppearance
            if #available(iOS 15.0, *) {
                navBarAppearance.compactScrollEdgeAppearance = customAppearance
            }
        } else {
            UINavigationBar.appearance().barStyle = .black
        }
    }

    private var synchronizationStatus: Bool = false {
        didSet {
            if (synchronizationStatus) {
                synchronizationIndicator.startAnimating()
                synchronizationIndicator.fadeIn()
            } else {
                synchronizationIndicator.fadeOut() { [weak self] in
                    self?.synchronizationIndicator.stopAnimating()
                }
            }
        }
    }

    private lazy var synchronizationIndicator: MDCProgressView = {
        let progressView = MDCProgressView()
        progressView.mode = .indeterminate
        progressView.progressTintColor = .white
        progressView.trackTintColor = .white.withAlphaComponent(0.3)

        progressView.alpha = 0
        return progressView
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        setup()
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        setup()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.addSubview(synchronizationIndicator)


        synchronizationIndicator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(3)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(onSynchronizationStatusChanged(notification:)),
                                               name: RiistaSynchronizationStatusKey.toNotificationName(), object: nil)
    }


    // MARK: - synchronization indication

    @objc private func onSynchronizationStatusChanged(notification: Notification) {
        self.synchronizationStatus = (notification.userInfo?["syncing"] as? NSNumber)?.boolValue ?? false
    }


    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }


    // MARK: - setup

    private func setup() {
        if #available(iOS 13.0, *) {
            navigationBar.overrideUserInterfaceStyle = .dark
        } else {
            navigationBar.barStyle = .black
        }

        var titleTextAttributes = self.navigationBar.titleTextAttributes ?? [:]
        titleTextAttributes[.font] = UIFont.appFont(for: .navigationBar)
        self.navigationBar.titleTextAttributes = titleTextAttributes

        if #available(iOS 11.0, *) {
            var largeTitleTextAttributes = self.navigationBar.largeTitleTextAttributes ?? [:]
            largeTitleTextAttributes[.font] = UIFont.appFont(for: .navigationBar)
            self.navigationBar.largeTitleTextAttributes = largeTitleTextAttributes
        }

        self.delegate = self
    }

    @available(iOS 13.0, *)
    private class func getGlobalNavBarAppearance() -> UINavigationBarAppearance {
        let customNavBarAppearance = UINavigationBarAppearance()

        let textAttributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.appFont(for: .navigationBar),
            .foregroundColor: UIColor.applicationColor(TextOnPrimary)!
        ]

        customNavBarAppearance.configureWithOpaqueBackground()
        customNavBarAppearance.backgroundColor = UIColor.applicationColor(Primary)!

        customNavBarAppearance.titleTextAttributes = textAttributes
        customNavBarAppearance.largeTitleTextAttributes = textAttributes

        let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
        barButtonItemAppearance.normal.titleTextAttributes = textAttributes
        barButtonItemAppearance.disabled.titleTextAttributes = textAttributes
        barButtonItemAppearance.highlighted.titleTextAttributes = textAttributes
        barButtonItemAppearance.focused.titleTextAttributes = textAttributes
        customNavBarAppearance.buttonAppearance = barButtonItemAppearance
        customNavBarAppearance.backButtonAppearance = barButtonItemAppearance
        customNavBarAppearance.doneButtonAppearance = barButtonItemAppearance

        return customNavBarAppearance
    }
}
