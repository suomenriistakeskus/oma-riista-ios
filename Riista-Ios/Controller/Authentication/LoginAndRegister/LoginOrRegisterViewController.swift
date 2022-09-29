import Foundation
import SnapKit

import RiistaCommon

protocol LoginOrRegisterViewControllerDelegate: AuthenticationChildHelpers {
    func onLoggedIn()
    func startPasswordRecovery(username: String?)
    func startChangeUsername()
}

class LoginOrRegisterViewController: UIViewController, KeyboardHandlerDelegate {

    weak var delegate: LoginOrRegisterViewControllerDelegate?

    enum Mode {
        case login
        case register
    }

    private var currentMode: Mode? = nil


    private enum RegistrationPhase {
        case startRegistration
        case linkSent
    }

    private var currentRegistrationPhase: RegistrationPhase? = nil
    private let languageProvider = CurrentLanguageProvider()

    private lazy var loginTab: UIView = {
        let tab = createTab(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "LoginTabTitle"),
            isActive: true,
            onClicked: #selector(onLoginTabClicked)
        )
        return tab
    }()

    private lazy var loginView: LoginView = {
        let view = LoginView()
        view.onLogin = { [weak self] username, password in
            guard let self = self else { return }
            if let username = username, let password = password {
                self.login(username: username, password: password)
            } else {
                print("no username or no password given!")
            }
        }
        view.passwordForgottenButton.onClicked = { [weak self] in
            guard let self = self else {
                return
            }

            self.delegate?.startPasswordRecovery(username: self.loginView.usernameField.text)
        }
        view.changeUsernameButton.onClicked = { [weak self] in
            self?.delegate?.startChangeUsername()
        }
        return view
    }()

    private lazy var registerTab: UIView = {
        let tab = createTab(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "RegisterTabTitle"),
            isActive: false,
            onClicked: #selector(onRegisterTabClicked)
        )
        return tab
    }()

    /**
     * A container for register views.
     */
    private lazy var registerViewContainer: UIView = {
        let container = UIView().apply { view in
            // initially hidden as login should be displayed
            view.alpha = 0
        }
        container.addSubview(sendRegistrationLinkView)
        sendRegistrationLinkView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        container.addSubview(registrationLinkSentView)
        registrationLinkSentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return container
    }()

    private lazy var sendRegistrationLinkView: SendRegistrationLinkView = {
        let view = SendRegistrationLinkView()
        view.onSendLink = { [weak self] username in
            self?.hideKeyboardAndSendRegistrationLink(username: username)
        }
        return view
    }()

    private lazy var registrationLinkSentView: RegistrationLinkSentView = {
        RegistrationLinkSentView().apply { view in
            view.returnToLoginButton.onClicked = { [weak self] in
                self?.switchToMode(mode: .login)
            }
        }
    }()


    // MARK: Switching between tabs / registration phases

    @objc func onLoginTabClicked() {
        switchToMode(mode: .login)
    }

    @objc func onRegisterTabClicked() {
        switchToMode(mode: .register)
    }

    func switchToMode(mode: Mode) {
        if (currentMode == mode) {
            print("mode won't change, nothing to do")
            return
        }

        delegate?.hideKeyboard(completion: nil)

        currentMode = mode

        switch mode {
        case .login:
            activateTab(tab: loginTab, contentView: loginView)
            deactivateTab(tab: registerTab, contentView: registerViewContainer)
            break
        case .register:
            activateTab(tab: registerTab, contentView: registerViewContainer)
            deactivateTab(tab: loginTab, contentView: loginView)

            switchToRegistrationPhase(phase: .startRegistration)
            break
        }
    }

    private func switchToRegistrationPhase(phase: RegistrationPhase) {
        if (currentRegistrationPhase == phase) {
            print("registration phase won't change, nothing to do")
            return
        }

        currentRegistrationPhase = phase

        switch phase {
        case .startRegistration:
            sendRegistrationLinkView.alpha = 1
            registrationLinkSentView.alpha = 0

            sendRegistrationLinkView.updateSendLinkButtonStatus()
            break
        case .linkSent:
            sendRegistrationLinkView.alpha = 0
            registrationLinkSentView.alpha = 1
            break
        }
    }

    private func activateTab(tab: UIView, contentView: UIView) {
        contentView.alpha = 1
        tab.backgroundColor = AuthenticationUiConstants.activeTabBackgroundColor
    }

    private func deactivateTab(tab: UIView, contentView: UIView) {
        contentView.alpha = 0
        tab.backgroundColor = AuthenticationUiConstants.inactiveTabBackgroundColor
    }


    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        let mode =  currentMode ?? .login

        switch mode {
        case .login:                        return loginView.loginButton
        case .register:
            let registrationPhase = currentRegistrationPhase ?? .startRegistration

            switch registrationPhase {
            case .startRegistration:        return sendRegistrationLinkView.sendLinkButton
            case .linkSent:                 return nil
            }
        }
    }


    // MARK: Creating views

    override func loadView() {
        view = UIView()

        let container = UIView()
        container.backgroundColor = AuthenticationUiConstants.contentBackgroundColor

        let tabBar = UIStackView().apply { stackview in
            stackview.axis = .horizontal
            stackview.distribution = .fillEqually
            stackview.alignment = .fill
            stackview.spacing = 8
        }
        view.addSubview(tabBar)
        tabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AuthenticationUiConstants.horizontalMarginsToScreen)
            make.top.greaterThanOrEqualToSuperview()
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        tabBar.addArrangedSubview(loginTab)
        tabBar.addArrangedSubview(registerTab)

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(AuthenticationUiConstants.horizontalMarginsToScreen)
            make.top.equalTo(tabBar.snp.bottom)
        }

        container.addSubview(loginView)
        loginView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.addSubview(registerViewContainer)
        registerViewContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }


    // MARK: Logging in

    private func login(username: String, password: String) {
        RiistaNetworkManager.sharedInstance().login(username, password: password) { [weak self] error in
            guard let self = self else {
                return
            }

            if let error = error as NSError? {
                var errorMessageKey: String? = nil
                switch error.code {
                case LoginError.errorCodeNetworkUnreachable, LoginError.errorCodeTimeout:
                    errorMessageKey = "loginConnectFailed"
                    break
                case LoginError.errorCodeIncorrectCredentials:
                    errorMessageKey = "loginIncorrectCredentials"
                    break
                case LoginError.errorCodeOutdatedVersion:
                    errorMessageKey = "loginOutdatedVersion"
                    break
                default:
                    print("Unexpected error code while logging in \(error.code)")
                    break
                }

                self.delegate?.showErrorDialog(
                    title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "loginFailed"),
                    message: errorMessageKey?.localized()
                )
            } else {
                self.onLoginSucceeded(username: username, password: password)
            }
        }
    }

    private func onLoginSucceeded(username: String, password: String) {
        let credentials = RiistaCredentials().apply {
            $0.username = username
            $0.password = password
        }
        RiistaSessionManager.sharedInstance().store(credentials)

        self.delegate?.onLoggedIn()
    }


    // MARK: Registration

    private func hideKeyboardAndSendRegistrationLink(username: String?) {
        if let delegate = delegate {
            delegate.hideKeyboard { [weak self] in
                self?.sendRegistrationLink(username: username)
            }
        } else {
            sendRegistrationLink(username: username)
        }
    }

    private func sendRegistrationLink(username: String?) {
        guard let username = username else {
            return
        }

        RiistaSDK.shared.sendStartRegistrationEmail(
            email: username,
            language: languageProvider.getCurrentLanguage()
        ) { [weak self] response, _ in
            guard let self = self else { return }

            if (response?.isSuccess == true) {
                self.switchToRegistrationPhase(phase: .linkSent)
            } else {
                self.delegate?.showErrorDialog(title: "Error".localized(),
                                               message: "NetworkOperationFailed".localized())
            }
        }
    }

    private func createTab(title: String, isActive: Bool, onClicked: Selector) -> UIView {
        let tab = ViewWithRoundedCorners()
        tab.cornerRadius = 5
        tab.roundedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // top left, top right
        if (isActive) {
            tab.backgroundColor = AuthenticationUiConstants.activeTabBackgroundColor
        } else {
            tab.backgroundColor = AuthenticationUiConstants.inactiveTabBackgroundColor
        }

        let headerButton = UIButton().apply { btn in
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
            btn.backgroundColor = .clear
            btn.addTarget(self, action: onClicked, for: .touchUpInside)
        }
        tab.addSubview(headerButton)
        headerButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        return tab
    }
}


fileprivate enum LoginError {
    static let errorCodeNetworkUnreachable = 0;
    static let errorCodeTimeout = -1001;
    static let errorCodeIncorrectCredentials = 403;
    static let errorCodeOutdatedVersion = 418;
}
