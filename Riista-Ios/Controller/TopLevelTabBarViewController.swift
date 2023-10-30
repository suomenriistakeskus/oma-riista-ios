import Foundation
import FirebaseMessaging
import TypedNotification

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

    private let notificationObservationBag = NotificationObservationBag()

    deinit {
        NotificationCenter.default.removeObserver(self)
        notificationObservationBag.empty()
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

        UserAccountUnregisterRequestedViewController.notifyIfUnregistrationRequested(
            navigationController: self.navigationController,
            ignoreCooldown: true
        )
    }

    @objc private func onReloginFailed() {
        logout(navigateToLoginController: true)
    }

    @objc private func onLogoutRequested() {
        logout(navigateToLoginController: false)
    }

    func logout(navigateToLoginController: Bool) {
        RiistaSDKHelper.logout() { [weak self] in
            self?.onRiistaSDKLogoutCompleted(navigateToLoginController: navigateToLoginController)
        }
    }

    private func onRiistaSDKLogoutCompleted(navigateToLoginController: Bool) {
        AppSync.shared.disableSyncPrecondition(.credentialsVerified)

        RiistaSessionManager.sharedInstance().removeCredentials()
        RiistaSettings.setUserInfo(nil)
        RiistaSettings.setUseExperimentalMode(false)

        RiistaPermitManager.sharedInstance().clearPermits()
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

        if (navigateToLoginController) {
            self.navigationController?.popToRootViewController(animated: false)
            showLoginController(animated: true)
        }
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

    private func showGameLogAfterEntityModified() {
        switch selectedIndex {
        case 3: fallthrough // messages -> should not be possible, but switch anyway
        case 0:         selectViewControllerAt(index: 1)
        case 1: fallthrough // game log -> no need to switch
        case 2: fallthrough // map -> no need to switch
        case 4: fallthrough // more (i.e. probably gallery) -> no need to switch
        default:
            // no need to switch
            break
        }
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

        notificationCenter.addObserver(self, selector: #selector(updateNavigationBarForCurrentlySelectedViewController),
                                       name: .NavigationItemUpdated, object: nil)

        notificationCenter.addObserver(self, selector: #selector(onLogoutRequested),
                                       name: .RequestLogout, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onReloginFailed),
                                       name: RiistaReloginFailedKey.toNotificationName(), object: nil)

        notificationCenter.addObserver(self, selector: #selector(updateMenuTexts),
                                       name: .LanguageSelectionUpdated, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateMenuTexts),
                                       name: RiistaPushAnnouncementKey.toNotificationName(), object: nil)

        notificationCenter.addObserver(
            forType: EntityModified.self,
            object: nil,
            queue: .main
        ) { [weak self] entityModified in
            guard let self = self else {
                return
            }

            self.showGameLogAfterEntityModified()
        }.stored(in: notificationObservationBag)
    }

    @available(iOS 13.0, *)
    private class func getGlobalTabBarAppearance() -> UITabBarAppearance {
        let customTabBarAppearance = UITabBarAppearance()

        customTabBarAppearance.configureWithOpaqueBackground()
        customTabBarAppearance.backgroundColor = UIColor.applicationColor(PrimaryVariant)!

        return customTabBarAppearance
    }
}
