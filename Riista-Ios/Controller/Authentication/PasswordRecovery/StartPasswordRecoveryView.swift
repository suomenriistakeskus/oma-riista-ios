import Foundation
import MaterialComponents

class StartPasswordRecoveryView: AuthenticationSendLinkToEmailView {

    lazy var cancelButton: MaterialButton = {
        let btn = MaterialButton()
        btn.setTitleFont(AppTheme.shared.fontForSize(size: AppConstants.Font.ButtonMedium), for: .normal)
        btn.setBorderColor(.white, for: .normal)
        btn.setBorderWidth(1.5, for: .normal)
        btn.setBackgroundColor(.clear)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return btn
    }()

    override init() {
        super.init()
        setupLocalizations()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupLocalizations()
    }

    private func setupLocalizations() {
        titleLocalizationKey = "SendPasswordResetTitle"
        messageLocalizationKey = "SendPasswordResetMessage"
        actionLocalizationKey = "SendPasswordResetAction"
    }

    override func setup() {
        super.setup()
        addView(cancelButton, spaceBefore: 8)
    }
}
