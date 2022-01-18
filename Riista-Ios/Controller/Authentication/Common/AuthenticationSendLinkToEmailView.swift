import Foundation
import MaterialComponents

class AuthenticationSendLinkToEmailView: UIStackView, UITextFieldDelegate {

    var titleLocalizationKey: String = "" {
        didSet {
            titleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: titleLocalizationKey)
        }
    }

    var messageLocalizationKey: String = "" {
        didSet {
            messageLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: messageLocalizationKey)
        }
    }

    var actionLocalizationKey: String = "" {
        didSet {
            sendLinkButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: actionLocalizationKey), for: .normal)
        }
    }

    private lazy var titleLabel: UILabel = {
        UILabel().apply { label in
            label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelXLarge)
            label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: titleLocalizationKey)
            label.textColor = .white
            label.numberOfLines = 1
        }
    }()

    private lazy var messageLabel: UILabel = {
        createLabel(textLocalizationKey: messageLocalizationKey, numberOfLines: 0)
    }()

    private lazy var usernameLabel: UILabel = {
        createLabel(textLocalizationKey: "Username", numberOfLines: 1)
    }()

    lazy var usernameField: TextField = {
        TextField().apply { field in
            field.delegate = self

            field.backgroundColor = .white
            field.layer.cornerRadius = 3
            field.clipsToBounds = true
            field.usePadding(8)

            field.keyboardType = .emailAddress
            if #available(iOS 11.0, *) {
                field.textContentType = .username
            } else {
                field.textContentType = .emailAddress
            }
            field.autocorrectionType = .no
            field.autocapitalizationType = .none
            field.clearButtonMode = .whileEditing

            field.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(40)
            }
        }
    }()

    var onSendLink: ((_ username: String?) -> Void)?

    lazy var sendLinkButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: actionLocalizationKey), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        btn.onClicked = {
            self.onSendLink?(self.usernameField.text)
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
        if (textField == usernameField) {
            // keyboard should be hidden when link is sent successfully
            onSendLink?(self.usernameField.text)
            return true
        }

        return false
    }

    func setup() {
        axis = .vertical
        alignment = .fill
        spacing = 4
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = AppConstants.UI.DefaultEdgeInsets

        addView(titleLabel)
        addView(messageLabel, spaceAfter: 8)

        addView(usernameLabel)
        addView(usernameField)

        addSpacer(size: 16, canExpand: true)

        addView(sendLinkButton)
    }

    private func createLabel(textLocalizationKey: String, numberOfLines: Int) -> UILabel {
        UILabel().apply { label in
            label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelSmall)
            label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: textLocalizationKey)
            label.textColor = .white
            label.numberOfLines = numberOfLines
        }
    }
}
