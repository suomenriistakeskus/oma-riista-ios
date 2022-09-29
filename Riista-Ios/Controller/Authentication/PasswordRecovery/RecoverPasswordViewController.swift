import Foundation
import SnapKit
import RiistaCommon

protocol RecoverPasswordViewControllerDelegate: AuthenticationChildHelpers {
    func cancelPasswordRecovery()
}

class RecoverPasswordViewController: UIViewController, KeyboardHandlerDelegate {

    weak var delegate: RecoverPasswordViewControllerDelegate?
    private let languageProvider = CurrentLanguageProvider()

    var initialUsername: String? {
        didSet {
            startPasswordRecoveryView.usernameField.text = initialUsername
        }
    }

    private lazy var startPasswordRecoveryView: StartPasswordRecoveryView = {
        let view = StartPasswordRecoveryView()
        view.cancelButton.onClicked = { [weak self] in
            self?.delegate?.cancelPasswordRecovery()
        }
        view.onSendLink = { [weak self] username in
            self?.hideKeyboardAndSendPasswordResetLink(username: username)
        }
        return view
    }()

    private lazy var passwordResetLinkSentView: PasswordResetLinkSentView = {
        let view = PasswordResetLinkSentView()
        view.returnToLoginButton.onClicked = { [weak self] in
            self?.delegate?.cancelPasswordRecovery()
        }
        return view
    }()


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // always start from the "start" view
        startPasswordRecoveryView.alpha = 1
        startPasswordRecoveryView.updateSendLinkButtonStatus()
        passwordResetLinkSentView.alpha = 0
    }

    private func hideKeyboardAndSendPasswordResetLink(username: String?) {
        if let delegate = delegate {
            delegate.hideKeyboard { [weak self] in
                self?.sendPasswordResetLink(username: username)
            }
        } else {
            sendPasswordResetLink(username: username)
        }
    }

    private func sendPasswordResetLink(username: String?) {
        guard let username = username else {
            return
        }

        RiistaSDK.shared.sendPasswordForgottenEmail(
            email: username,
            language: languageProvider.getCurrentLanguage()
        ) { [weak self] response, _ in
            guard let self = self else { return }

            if (response?.isSuccess == true) {
                self.startPasswordRecoveryView.alpha = 0
                self.passwordResetLinkSentView.alpha = 1
            } else {
                self.delegate?.showErrorDialog(title: "Error".localized(),
                                               message: "NetworkOperationFailed".localized())
            }
        }
    }


    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        return startPasswordRecoveryView.sendLinkButton
    }


    // MARK: Creating views

    override func loadView() {
        view = UIView()

        let container = UIView()
        container.backgroundColor = .black.withAlphaComponent(0.7)

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(AuthenticationUiConstants.horizontalMarginsToScreen)
            make.top.greaterThanOrEqualToSuperview()
        }

        container.addSubview(startPasswordRecoveryView)
        startPasswordRecoveryView.alpha = 1
        startPasswordRecoveryView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        passwordResetLinkSentView.alpha = 0
        container.addSubview(passwordResetLinkSentView)
        passwordResetLinkSentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
