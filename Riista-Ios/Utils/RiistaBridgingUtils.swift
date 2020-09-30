import Foundation

class RiistaBridgingUtils {
    static func RiistaLocalizedString(forkey: String, value: String? = nil) -> String {
        return RiistaLocalization.sharedInstance().localizedString(forKey: forkey, value: value)
    }

    static func RiistaMappedString(forkey: String, value: String? = nil) -> String {
        return RiistaLocalization.sharedInstance().mappedValueString(forKey: forkey, value: value)
    }
}
