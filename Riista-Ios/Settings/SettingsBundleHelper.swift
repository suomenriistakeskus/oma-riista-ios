import Foundation

class SettingsBundleHelper {
    @SettingsBundleValue<Bool>(key: "use_custom_backend")
    static var useCustomBackend: Bool?

    @SettingsBundleValue<String>(key: "custom_backend_hostname")
    static var customBackendHostname: String?

    class func getBackendHostname(fallback: String) -> String {
        if let useCustomBackend = useCustomBackend, useCustomBackend == true {
            return customBackendHostname ?? fallback
        } else {
            return fallback
        }
    }
}
