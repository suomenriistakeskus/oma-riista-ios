import Foundation
import FirebaseRemoteConfig
import Async

@objc enum RemoteConfigurable: Int, CaseIterable {
    // the application startup message to be displayed if any. In JSON format
    // and to be given to RiistaSDK for parsing.
    case appStartupMessageJson

    // the group hunting startup message to be displayed if any. In JSON format
    // and to be given to RiistaSDK for parsing.
    case groupHuntingIntroMessageJson

    // the settings for the Riista SDK
    case riistaSDKSettings

    // is the "experimental mode" allowed?
    case experimentalModeAllowed

    // how long should we wait before promoting new app update?
    case appUpdatePromotionDelayDays

    // Pattern for parsing Finnish SSN
    case ssnPattern

    // Map tile versions (allows invalidating certain map layers afterwards)
    case mapTileVersions
}


typealias RemoteConfigurationOperationCompletion = () -> Void

@objc class RemoteConfigurationManager: NSObject {
    @objc static let sharedInstance = RemoteConfigurationManager()
    @objc static let remoteConfigurationActivatedKey = "RemoteConfigurationActivationCompletedKey"

    // RemoteConfig throttles requests internally. In addition add internal
    // throttling to fetch attempts (don't even allow attempt fetching too often)
    private let fetchAttemptGate = CooldownGate(seconds: 10)

    override init() {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        if (env == Env.dev) {
            settings.minimumFetchInterval = 0
        }
        remoteConfig.configSettings = settings

        var defaults = [String : NSObject]()
        for configurable in RemoteConfigurable.allCases {
            let defaultValue: NSObject
            switch configurable {
            case .appStartupMessageJson, .groupHuntingIntroMessageJson:
                // no default for startup messages i.e. let them be null
                continue
            case .riistaSDKSettings:
                // no default overrides i.e. let it be null
                continue
            case .appUpdatePromotionDelayDays:
                defaultValue = NSNumber(integerLiteral: AppUpdateNotifier.DEFAULT_PROMOTION_DELAY_DAYS)
                break
            case .experimentalModeAllowed:
                defaultValue = NSNumber(booleanLiteral: false)
                break
            case .ssnPattern:
                defaultValue = "^\\d{6}[A+-]\\d{3}[0-9A-FHJ-NPR-Y]$" as NSString
                break
            case .mapTileVersions:
                // no default overrides i.e. let it be null
                continue
            }

            defaults[configurable.key()] = defaultValue
        }
        remoteConfig.setDefaults(defaults)
    }

    @objc func fetchRemoteConfigurationIfNotRecent(completionHandler: RemoteConfigurationOperationCompletion? = nil) {
        let shouldFetch: Bool
        if let lastFetchTime = RemoteConfig.remoteConfig().lastFetchTime {
            let hoursSinceLastFetch = DatetimeUtil.hoursSince(from: lastFetchTime, to: Date()) ?? 0
            shouldFetch = hoursSinceLastFetch > 12 // hmm, should this come from remote config..
        } else {
            shouldFetch = true
        }

        if (shouldFetch) {
            fetchRemoteConfiguration(timeoutSeconds: -1, completionHandler: completionHandler)
        }
    }

    /**
     * Starts fetching the remote configuration.
     * @param timeoutSeconds        The maximum time before completionHandler is called. Configuration fetch will not be cancelled if timeout is reached. Not taken into account if negative.
     * @param completionHandler     Will be called when either timeout is reached or remote configuration has been fetched. Will only be called once.
     */
    @objc func fetchRemoteConfiguration(timeoutSeconds: Double, completionHandler: RemoteConfigurationOperationCompletion? = nil) {
        var completionFired = false
        let fireCompletion: (String) -> Void = { debugMessage in
            if (completionFired) {
                return
            }
            CrashlyticsHelper.log(msg: debugMessage)
            completionFired = true
            completionHandler?()
        }

        if (fetchAttemptGate.tryPass() == .coolingDown) {
            fireCompletion("Cooling down from previous remote configuration fetch.")
            return
        }

        if (timeoutSeconds > 0) {
            Async.main(after: timeoutSeconds) {
                fireCompletion("Reached remote configuration fetch timeout after \(timeoutSeconds) seconds")
            }
        }

        CrashlyticsHelper.log(msg: "Fetching remote config..")

        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.fetch { (status: RemoteConfigFetchStatus, error: Error?) in
            Async.main {
                fireCompletion("Remote configuration fetch completed with status = \(status.rawValue), error = \(error.nilStringOrLocalizedDescription)")
            }
        }
    }

    @objc func activateRemoteConfiguration(completionHandler: RemoteConfigurationOperationCompletion? = nil) {
        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.activate { (changed: Bool, error: Error?) in
            Async.main {
                CrashlyticsHelper.log(msg: "Remote configuration activated. Was changed = \(changed), " +
                                        "error = \(error.nilStringOrLocalizedDescription)")
                completionHandler?()

                NotificationCenter.default.post(
                    name: Notification.Name(RemoteConfigurationManager.remoteConfigurationActivatedKey),
                    object: nil)
            }
        }
    }

    @objc func fetchAndActivateRemoteConfiguraton(completionHandler: RemoteConfigurationOperationCompletion? = nil) {
        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.fetchAndActivate { (status: RemoteConfigFetchAndActivateStatus, error: Error?) in
            Async.main {
                CrashlyticsHelper.log(msg: "Remote configuration fetchAndActivate completed with status = \(status.rawValue), " +
                                        "error = \(error.nilStringOrLocalizedDescription)")
                completionHandler?()

                NotificationCenter.default.post(
                    name: Notification.Name(RemoteConfigurationManager.remoteConfigurationActivatedKey),
                    object: nil)
            }
        }
    }

    @objc func appStartupMessageJson() -> String? {
        return getValueFor(configurable: .appStartupMessageJson).stringValue
    }

    @objc func groupHuntingIntroMessageJson() -> String? {
        return getValueFor(configurable: .groupHuntingIntroMessageJson).stringValue
    }

    @objc func riistaSDKSettings() -> String? {
        return getValueFor(configurable: .riistaSDKSettings).stringValue
    }

    @objc func experimentalModeAllowed() -> Bool {
        return getValueFor(configurable: .experimentalModeAllowed).boolValue
    }

    func appUpdatePromotionDelayDays() -> Int? {
        return getValueFor(configurable: .appUpdatePromotionDelayDays).numberValue.intValue
    }

    func ssnPattern() -> String {
        return getValueFor(configurable: .ssnPattern).stringValue!
    }

    @objc func mapTileVersions() -> String? {
        return getValueFor(configurable: .mapTileVersions).stringValue
    }

    private func getValueFor(configurable: RemoteConfigurable) -> RemoteConfigValue {
        return RemoteConfig.remoteConfig().configValue(forKey: configurable.key())
    }
}

fileprivate extension RemoteConfigurable {
    func key() -> String {
        switch self {
        case .appStartupMessageJson:
            return "app_startup_message"
        case .groupHuntingIntroMessageJson:
            return "group_hunting_intro_message"
        case .riistaSDKSettings:
            return "riista_sdk_remote_settings"
        case .experimentalModeAllowed:
            return "experimental_mode_allowed"
        case .appUpdatePromotionDelayDays:
            return "app_update_promotion_delay_days"
        case .ssnPattern:
            return "ssn_pattern"
        case .mapTileVersions:
            return "map_tile_versions"
        }
    }
}

fileprivate extension Optional where Wrapped == Error {
    var nilStringOrLocalizedDescription: String {
        get {
            return self == nil ? "<nil>" : self!.localizedDescription
        }
    }
}
