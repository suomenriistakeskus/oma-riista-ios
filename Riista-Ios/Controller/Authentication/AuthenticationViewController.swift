import Foundation
import MaterialComponents
import SnapKit

@objc protocol AuthenticationViewControllerDelegate {
    func onLoggedIn()
}


/**
 * The common functionality for child view controllers
 */
protocol AuthenticationChildHelpers: AnyObject {
    func hideKeyboard(completion: OnCompleted?)

    func showErrorDialog(title: String, message: String?)
}

/**
 * A view controller for authentication functionality. Provides:
 * - login
 * - password reset
 * - registering a new account (not implemented yet)
 * - changing email (not implemented yet)
 */
@objc class AuthenticationViewController: BaseViewController,
                                          AuthenticationChildHelpers,
                                          LoginOrRegisterViewControllerDelegate,
                                          RecoverPasswordViewControllerDelegate,
                                          ChangeUsernameViewControllerDelegate,
                                          KeyboardHandlerDelegate {

    @objc weak var delegate: AuthenticationViewControllerDelegate?


    private enum State {
        case loginOrRegister
        case recoverPassword
        case changeUsername
    }

    private var currentState: State? = nil
    private var currentChildViewController: UIViewController? = nil


    private lazy var backgroundImageView: UIImageView = {
        UIImageView().apply { imageView in
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: "Splash")
        }
    }()

    private lazy var logoImageView: UIImageView = {
        let view = UIImageView()
        let language = RiistaSettings.language() ?? "fi"
        let imageName = "logo-horizontal-\(language)"
        view.image = UIImage(named: imageName)
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var controlsContainer: UIView = {
        UIView()
    }()

    private var controlsBottomConstraint: Constraint? = nil
    private var keyboardHandler: KeyboardHandler?

    private lazy var loginOrRegisterVC: LoginOrRegisterViewController = {
        LoginOrRegisterViewController().apply { vc in
            vc.delegate = self
            addChild(vc)
        }
    }()

    private lazy var recoverPasswordVC: RecoverPasswordViewController = {
        RecoverPasswordViewController().apply { vc in
            vc.delegate = self
            addChild(vc)
        }
    }()

    private lazy var changeUsernameVC: ChangeUsernameViewController = {
        ChangeUsernameViewController().apply { vc in
            vc.delegate = self
            addChild(vc)
        }
    }()

    // the background is quite dark, use light status bar text
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            .lightContent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardHandler?.listenKeyboardEvents()
    }

    override func viewWillDisappear(_ animated: Bool) {
        keyboardHandler?.stopListenKeyboardEvents()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // subviews have been layouted and control area has a frame
        // -> enter initial state
        if (currentState == nil) {
            goToState(.loginOrRegister, direction: .forward)
        }
    }


    // MARK: AuthenticationChildHelpers

    func hideKeyboard(completion: OnCompleted? = nil) {
        if let keyboardHandler = keyboardHandler {
            keyboardHandler.hideKeyboard(completion)
        } else {
            completion?()
        }
    }

    func showErrorDialog(title: String, message: String?) {
        let alertController = MDCAlertController(title: title, message: message)
        alertController.addAction(MDCAlertAction(title: "OK".localized(), handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }


    // MARK: LoginOrRegisterViewControllerDelegate

    func onLoggedIn() {
        keyboardHandler?.hideKeyboard { [weak self] in
            self?.delegate?.onLoggedIn()
        }
    }

    func startPasswordRecovery(username: String?) {
        keyboardHandler?.hideKeyboard { [weak self] in
            guard let self = self else {
                return
            }

            self.recoverPasswordVC.initialUsername = username
            self.goToState(.recoverPassword, direction: .forward)
        }
    }

    func startChangeUsername() {
        keyboardHandler?.hideKeyboard { [weak self] in
            guard let self = self else {
                return
            }

            self.goToState(.changeUsername, direction: .forward)
        }
    }


    // MARK: RecoverPasswordViewControllerDelegate

    func cancelPasswordRecovery() {
        keyboardHandler?.hideKeyboard { [weak self] in
            self?.goToState(.loginOrRegister, direction: .backwards)
        }
    }


    // MARK: ChangeUsernameViewControllerDelegate

    func cancelChangeUserName() {
        goToState(.loginOrRegister, direction: .backwards)
    }

    func startRegistration() {
        loginOrRegisterVC.switchToMode(mode: .register)
        goToState(.loginOrRegister, direction: .backwards)
    }

    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        if let childDelegate = currentChildViewController as? KeyboardHandlerDelegate {
            // This view controller doesn't know the actual UI
            // -> let current child controller determine the view.
            return childDelegate.getBottommostVisibleViewWhileKeyboardVisible()
        } else {
            return nil
        }
    }

    // MARK: State changes / switching views

    private func goToState(_ state: State, direction: NavigationDirection) {
        let targetController = getChildViewControllerForState(state)

        switchToViewController(childController: targetController,
                               containerView: controlsContainer,
                               direction: direction)
        currentState = state
    }

    private func getChildViewControllerForState(_ state: State) -> UIViewController {
        switch state {
        case .loginOrRegister:  return loginOrRegisterVC
        case .recoverPassword:  return recoverPasswordVC
        case .changeUsername:   return changeUsernameVC
        }
    }

    private func switchToViewController(childController: UIViewController,
                                        containerView: UIView,
                                        direction: NavigationDirection) {
        childController.view.frame = containerView.bounds

        if let currentController = self.currentChildViewController {
            var framePositionOutsideOfScreen = containerView.bounds.width * 1.2
            if (direction == .backwards) {
                framePositionOutsideOfScreen *= -1
            }

            currentController.willMove(toParent: nil)
            if (childController.parent != self) {
                self.addChild(childController)
            }

            childController.view.frame.origin.x = framePositionOutsideOfScreen
            self.transition(from: currentController,
                            to: childController,
                            duration: AppConstants.Animations.durationDefault) {
                currentController.view.frame.origin.x = -framePositionOutsideOfScreen
                childController.view.frame.origin.x = 0
            } completion: { _ in
                currentController.removeFromParent()
                childController.didMove(toParent: self)
                self.currentChildViewController = childController
            }
        } else {
            displayChildViewController(childController, to: containerView)
        }
    }

    private func displayChildViewController(_ childViewController: UIViewController, to containerView: UIView) {
        containerView.addSubview(childViewController.view)
        if (childViewController.parent != self) {
            addChild(childViewController)
        }
        childViewController.didMove(toParent: self)
        currentChildViewController = childViewController
    }


    // MARK: View creation

    override func loadView() {
        view = UIView()
        addBackground()
        createAreaForControls()

        if let bottomConstraint = controlsBottomConstraint {
            keyboardHandler = KeyboardHandler(
                view: self.view,
                contentMovement: .usingSnapKitConstraint(constraint: bottomConstraint)
            )
            keyboardHandler?.delegate = self
        }
    }

    private func addBackground() {
        // use the same background image as on the launch/splash screen
        // -> transition from splash won't be noticeable
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AuthenticationUiConstants.horizontalMarginsToScreen)
            make.top.equalTo(view.layoutMarginsGuide).inset(24)
        }
    }

    private func createAreaForControls() {
        view.addSubview(controlsContainer)
        controlsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            controlsBottomConstraint = make.bottom.equalTo(view.layoutMarginsGuide).constraint

            // constrain height instead of top. Constraining top didn't work as intended
            // and for some reason the control area didn
            make.height.equalToSuperview()
        }
    }
}

