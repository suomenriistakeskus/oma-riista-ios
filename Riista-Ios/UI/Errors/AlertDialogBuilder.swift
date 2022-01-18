import Foundation
import MaterialComponents

class AlertDialogBuilder {
    class func createError(message: String?) -> MDCAlertController {
        return create(title: "Error".localized(), message: message)
    }

    class func create(title: String, message: String?) -> MDCAlertController {
        let alertController = MDCAlertController(title: title, message: message)
        alertController.addAction(MDCAlertAction(title: "OK".localized(), handler: nil))
        return alertController
    }
}
