import Foundation
import MaterialComponents

class PasswordResetLinkSentView: AuthenticationLinkSentView {

    override init() {
        super.init()
        setupLocalizations()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupLocalizations()
    }

    private func setupLocalizations() {
        titleLocalizationKey = "AuthenticationLinkSentTitle"
        messageLocalizationKey = "PasswordResetSentMessage"
    }
}
