import Foundation

enum Env {
    case dev
    case staging
    case production
}

#if DEV
let env = Env.dev
#elseif STAGING
let env = Env.staging
#else
let env = Env.production
#endif

@objcMembers
class Environment: NSObject {

    static var apiHostName: String {
        switch env {
        case .dev:
            return SettingsBundleHelper.getBackendHostname(fallback: "<add your url here>")
        case .staging:
            return SettingsBundleHelper.getBackendHostname(fallback: "<add your url here>")
        case .production:
            return "oma.riista.fi"
        }
    }

    static var serverBaseAddress: String {
        return "https://" + apiHostName
    }
}
