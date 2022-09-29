import Foundation
import FirebaseMessaging

/**
 * A class that manages the top level tab navigation (i.e. front page, game log, map, announcements and more).
 */
@objc class TopLevelTabBarViewController: BaseTabBarViewController,
                                          AuthenticationViewControllerDelegate {

    @objc class func setupGlobalTabBarAppearance() {
        if #available(iOS 13.0, *) {
            let customAppearance = getGlobalTabBarAppearance()

            let tabBarAppearance = UITabBar.appearance()
            tabBarAppearance.standardAppearance = customAppearance
            if #available(iOS 15.0, *) {
                tabBarAppearance.scrollEdgeAppearance = customAppearance
            }
        } else {
            UITabBar.appearance().barStyle = .black
        }
    }

    @objc private(set) var isDisplayingLoginScreen: Bool = false

    /**
     * Exists if logging in.
     */
    private var authenticationController: AuthenticationViewController?

    override var childForStatusBarStyle: UIViewController? {
        get {
            authenticationController
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if (RiistaSessionManager.sharedInstance().userCredentials() == nil) {
            showLoginController(animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // hides edit button (just in case moreNavigationController happens to be used in the future)
        customizableViewControllers = nil
    }

    func onLoggedIn() {
        isDisplayingLoginScreen = false
        removeLoginController()

        RiistaGameDatabase.sharedInstance().initUserSession()
        selectViewControllerAt(index: 0)
    }

    @objc func logout() {
        RiistaSDKHelper.logout()

        RiistaSessionManager.sharedInstance().removeCredentials()
        RiistaSettings.setUserInfo(nil)
        RiistaSettings.setUseExperimentalMode(false)

        RiistaPermitManager.sharedInstance().clearPermits()
        RiistaGameDatabase.sharedInstance().autosync = false
        RiistaUtils.markAllAnnouncementsAsRead()
        RiistaClubAreaMapManager.clearCache()

        // Just delete the Firebase Cloud Messaging token. We don't want to delete the Installations id
        // as that would corrupt the analytics on how the app is updated etc
        FirebaseMessaging.Messaging.messaging().deleteToken { error in
            if (error == nil) {
                print("Completed removing FirebaseMessaging token.")
            } else {
                let errorMsg = error?.localizedDescription ?? "-"
                print("Failed to remove FirebaseMessaging token. Error: \(errorMsg)")
            }
        }

        self.navigationController?.popToRootViewController(animated: false)
        showLoginController(animated: true)
    }

    @objc private func updateMenuTexts() {
        guard let viewControllers = self.viewControllers else {
            return
        }

        viewControllers.forEach { viewController in
            if let tab = viewController as? RiistaTabPage {
                tab.refreshTabItem()
            }
        }
    }

    @objc private func logEntrySaved() {
        selectViewControllerAt(index: 1) // game log
    }

    private func selectViewControllerAt(index: Int) {
        guard let viewControllers = self.viewControllers, viewControllers.count > index else {
            print("Not enough viewcontrollers, cannot index \(index)")
            return
        }

        selectedViewController = viewControllers[index]
        updateNavigationBarForCurrentlySelectedViewController()
    }

    private func showLoginController(animated: Bool) {
        let authenticationController = AuthenticationViewController()
        authenticationController.delegate = self
        self.authenticationController = authenticationController

        isDisplayingLoginScreen = true

        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        addChild(authenticationController)

        self.view.addSubview(authenticationController.view)
        authenticationController.view.frame = self.view.frame
        authenticationController.willMove(toParent: self)

        setNeedsStatusBarAppearanceUpdate()

        if (animated) {
            authenticationController.view.alpha = 0
            // Not called automatically since adding to view hierarchy directly
            authenticationController.viewWillAppear(animated)
            UIView.animate(withDuration: AppConstants.Animations.durationDefault) {
                authenticationController.view.alpha = 1
            } completion: { _ in
                authenticationController.didMove(toParent: self)
            }
        } else {
            // Not called automatically since adding to view hierarchy directly
            authenticationController.viewWillAppear(animated)
            authenticationController.didMove(toParent: self)
        }
    }

    private func removeLoginController() {
        navigationController?.setNavigationBarHidden(false, animated: true)

        UIView.animate(withDuration: AppConstants.Animations.durationDefault) {
            self.authenticationController?.view.alpha = 0.0
        } completion: { [weak self] _ in
            if let authenticationController = self?.authenticationController {
                authenticationController.willMove(toParent: nil)
                authenticationController.view.removeFromSuperview()
                authenticationController.removeFromParent()

                self?.authenticationController = nil
            }

            self?.setNeedsStatusBarAppearanceUpdate()
        }
    }


    // MARK: - setup

    override func setup() {
        super.setup()

        registerAsObserver()
    }

    private func registerAsObserver() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(logout),
                                       name:RiistaReloginFailedKey.toNotificationName(), object: nil)

        notificationCenter.addObserver(self, selector: #selector(updateMenuTexts),
                                       name:RiistaLanguageSelectionUpdatedKey.toNotificationName(), object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateMenuTexts),
                                       name:RiistaPushAnnouncementKey.toNotificationName(), object: nil)

        notificationCenter.addObserver(self, selector: #selector(logEntrySaved),
                                       name:RiistaLogEntrySavedKey.toNotificationName(), object: nil)
    }

    @available(iOS 13.0, *)
    private class func getGlobalTabBarAppearance() -> UITabBarAppearance {
        let customTabBarAppearance = UITabBarAppearance()

        customTabBarAppearance.configureWithOpaqueBackground()
        customTabBarAppearance.backgroundColor = UIColor.applicationColor(PrimaryVariant)!

        return customTabBarAppearance
    }
}
