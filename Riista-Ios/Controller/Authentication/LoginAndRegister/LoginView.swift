import Foundation
import MaterialComponents

class LoginView: UIStackView, UITextFieldDelegate {

    lazy var usernameField: TextField = {
        createTextField().apply { field in
            if #available(iOS 11.0, *) {
                field.textContentType = .username
            } else {
                field.textContentType = .emailAddress
            }
            field.keyboardType = .emailAddress
            field.returnKeyType = .next
            field.delegate = self
        }
    }()

    lazy var passwordField: TextField = {
        createTextField().apply { field in
            field.isSecureTextEntry = true

            if #available(iOS 11.0, *) {
                field.textContentType = .password
            }
            field.keyboardType = .default
            field.returnKeyType = .done
            field.delegate = self
        }
    }()

    /**
     * Called when the login should be attempted.
     */
    var onLogin: ((_ username: String?, _ password: String?) -> Void)?

    lazy var loginButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Login"), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        btn.onClicked = { [weak self] in
            guard let self = self else {
                return
            }

            self.tryLogin()
        }
        return btn
    }()

    lazy var changeUsernameButton: MaterialButton = {
        let btn = MaterialButton()
        btn.setTitleFont(UIFont.appFont(for: .button), for: .normal)
        btn.setBorderColor(.white, for: .normal)
        btn.setBorderWidth(1.5, for: .normal)
        btn.setBackgroundColor(.clear)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "LoginUsernameChanged"), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return btn
    }()

    lazy var passwordForgottenButton: MaterialButton = {
        let btn = MaterialButton()
        btn.setTitleFont(UIFont.appFont(for: .button), for: .normal)
        btn.setBorderColor(.white, for: .normal)
        btn.setBorderWidth(1.5, for: .normal)
        btn.setBackgroundColor(.clear)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "PasswordForgotten"), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return btn
    }()

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            passwordField.becomeFirstResponder()
            break
        case passwordField:
            // keyboard is hidden when logged in successfully
            // -> just trying login is enough as in case of an error the keyboard
            //    is hidden while error message is displayed. The keyboard is
            //    displayed again once user dismisses the dialog
            tryLogin()
            return true
        default:
            break
        }

        return false
    }

    private func tryLogin() {
        onLogin?(usernameField.text, passwordField.text)
    }

    private func setup() {
        axis = .vertical
        alignment = .fill
        spacing = 4
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = AppConstants.UI.DefaultEdgeInsets

        addView(UILabel().apply { label in
            label.font = UIFont.appFont(fontSize: .small)
            label.text = "Username".localized()
            label.textColor = .white
            label.numberOfLines = 1
        })
        addView(usernameField, spaceAfter: 8)

        addView(UILabel().apply { label in
            label.font = UIFont.appFont(fontSize: .small)
            label.text = "Password".localized()
            label.textColor = .white
            label.numberOfLines = 1
        })
        addView(passwordField)

        addSpacer(size: 16, canExpand: true)

        addView(loginButton, spaceAfter: 8)
        addView(changeUsernameButton, spaceAfter: 8)
        addView(passwordForgottenButton)
    }

    private func createTextField() -> TextField {
        let field = TextField()
        field.backgroundColor = .white
        field.layer.cornerRadius = 3
        field.clipsToBounds = true
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.clearButtonMode = .whileEditing

        field.usePadding(8, rightMode: .unlessEditing)

        field.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        return field
    }
}
