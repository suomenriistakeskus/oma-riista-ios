import Foundation
import MaterialComponents

class SendRegistrationLinkView: AuthenticationSendLinkToEmailView {

    override init() {
        super.init()
        setupLocalizations()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupLocalizations()
    }

    private func setupLocalizations() {
        titleLocalizationKey = "SendRegistrationLinkTitle"
        messageLocalizationKey = "SendRegistrationLinkMessage"
        actionLocalizationKey = "SendRegistrationLinkAction"
    }
}
