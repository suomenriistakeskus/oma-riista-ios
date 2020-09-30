import Foundation

@objc class ShootingTestUtil: NSObject {
    private static var serverDateFormatter: DateFormatter? = nil
    private static var displayDateFormatter: DateFormatter? = nil

    @objc static func serverDateStringToDisplayDate(serverDate: String) -> String {
        if (serverDateFormatter == nil) {
            serverDateFormatter = DateFormatter()
            self.serverDateFormatter?.locale = RiistaUtils.appLocale()
            self.serverDateFormatter?.dateFormat = "yyyy-MM-dd"
        }
        if (displayDateFormatter == nil) {
            displayDateFormatter = DateFormatter()
            self.displayDateFormatter?.locale = RiistaUtils.appLocale()
            self.displayDateFormatter?.dateFormat = "dd.MM.yyyy"
        }

        return self.displayDateFormatter!.string(from: self.serverDateFormatter!.date(from: serverDate)!)
    }

    @objc static func localizedTypeText(value: String) -> String {
        switch value {
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBear")
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeMoose")
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeRoeDeer")
        case ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBow")
        default:
            return value
        }
    }

    static func currencyFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: "fi-FI")
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2

        return numberFormatter
    }
}

extension UIImage {
    func createSelectionIndicator(color: UIColor, size: CGSize, lineWidth: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint(x: 0,y :size.height - lineWidth), size: CGSize(width: size.width, height: lineWidth)))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIViewController {
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
