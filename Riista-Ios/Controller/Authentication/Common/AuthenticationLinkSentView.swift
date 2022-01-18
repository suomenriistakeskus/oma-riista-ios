import Foundation
import MaterialComponents

class AuthenticationLinkSentView: UIStackView {

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

    private lazy var titleLabel: UILabel = {
        UILabel().apply { label in
            label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelXLarge)
            label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: messageLocalizationKey)
            label.textColor = .white
            label.numberOfLines = 1
        }
    }()

    private lazy var messageLabel: UILabel = {
        UILabel().apply { label in
            label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelSmall)
            label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: messageLocalizationKey)
            label.textColor = .white
            label.numberOfLines = 0
        }
    }()

    lazy var returnToLoginButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "AuthenticationLinkSentBackToLogin"), for: .normal)
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

    private func setup() {
        axis = .vertical
        alignment = .fill
        spacing = 4
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = AppConstants.UI.DefaultEdgeInsets

        addView(titleLabel)
        addView(messageLabel)

        addSpacer(size: 16, canExpand: true)

        addView(returnToLoginButton)
    }
}
