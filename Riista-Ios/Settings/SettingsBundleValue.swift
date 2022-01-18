import Foundation

/**
 * According to https://stackoverflow.com/a/64712479 and
 * https://www.swiftbysundell.com/articles/property-wrappers-in-swift/
 */
@propertyWrapper struct SettingsBundleValue<T> {
    let key: String

    var wrappedValue: T? {
        get {
            UserDefaults.standard.value(forKey: key) as? T
        }
    }
}
