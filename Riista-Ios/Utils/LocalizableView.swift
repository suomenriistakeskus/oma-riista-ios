import Foundation
import MaterialComponents.MaterialButtons

protocol LocalizableView: AnyObject, PropertyStoring where T == String {

    func setLocalizedText(text: String)
}

extension LocalizableView {
    var localizationKey: String {
        get {
            getAssociatedObject(&PropertyKeys.localizationKey, defaultValue: "")
        }
        set {
            setAssociatedObject(&PropertyKeys.localizationKey, value: newValue)
        }
    }

    @discardableResult
    func localize() -> Self {
        setLocalizedText(text: localizationKey.localized())
        return self
    }

    @discardableResult
    func localizeFormatted(_ formatBlock: (String) -> String) -> Self {
        let localizedKey = localizationKey.localized()
        setLocalizedText(text: formatBlock(localizedKey))
        return self
    }
}


// MARK: View extension

extension UILabel: LocalizableView {
    func setLocalizedText(text: String) {
        self.text = text
    }
}

extension CardButton: LocalizableView {
    func setLocalizedText(text: String) {
        self.title = text
    }
}


// MARK: internal

fileprivate struct PropertyKeys {
    static var localizationKey = "LocalizationKey"
}
