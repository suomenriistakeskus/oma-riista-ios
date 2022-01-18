import Foundation
import RiistaCommon

import MaterialComponents.MaterialDialogs

@objc class RiistaSDKHelper: NSObject {
    @objc static private(set) var riistaSdkInitialized: Bool = false

    @objc class func initializeRiistaSDK() {
        CrashlyticsHelper.log(msg: "Initializing RiistaSDK")

        let infoDictionary = Bundle.main.infoDictionary
        let appVersion: String? = infoDictionary?["CFBundleShortVersionString"] as? String
        let buildVersion: String? = infoDictionary?["CFBundleVersion"] as? String

        let unknownVersion = "-"
        RiistaSdkBuilder.Companion()
            .with(applicationVersion: appVersion ?? unknownVersion,
                  buildVersion: buildVersion ?? unknownVersion,
                  serverBaseAddress: Environment.serverBaseAddress)
            // only allow redirects to absolute urls for debug/beta builds. NOT FOR PRODUCTION!
            .setAllowRedirectsToAbsoluteHosts(allowed: env == .dev || env == .staging)
            .initializeRiistaSDK()

        CrashlyticsHelper.log(msg: "RiistaSDK initialization completed")

        riistaSdkInitialized = true
    }

    @objc class func logout() {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to logout before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Logging out RiistaSDK..")
        RiistaSDK.shared.logout()
        CrashlyticsHelper.log(msg: "RiistaSDK logged out")
    }

    @objc class func prepareAppStartupMessage(_ messageJson: String?) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to prepare app startup message before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Preparing application startup message")

        let startupMessageHandler = RiistaSDK.shared.appStartupMessageHandler()
        startupMessageHandler.parseAppStartupMessageFromJson(messageJson: messageJson)

        CrashlyticsHelper.log(msg: "Application startup message prepared")
    }

    @objc class func prepareGroupHuntingIntroMessage(_ messageJson: String?) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to prepare group hunting intro message before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Preparing group hunting intro message")

        let messageHandler = RiistaSDK.shared.groupHuntingIntroMessageHandler()
        messageHandler.parseMessageFromJson(messageJson: messageJson)

        CrashlyticsHelper.log(msg: "Group hunting intro message prepared")
    }

    @objc class func overrideHarvestSeasons(_ overridesJson: String?) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to override harvest seasons before RiistaSDK has been initialized")
            return
        }

        guard let overridesJson = overridesJson else {
            CrashlyticsHelper.log(msg: "Refusing to override harvest seasons with null overrides!")
            return
        }

        CrashlyticsHelper.log(msg: "Overriding harvest seasons")

        RiistaSDK.shared.harvestSeasons.overridesProvider.parseOverridesFromJson(overridesJson: overridesJson)

        CrashlyticsHelper.log(msg: "Harvest seasons overridden")
    }

    @objc class func applyRemoteSettings(_ remoteSettingsJson: String?) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to apply remote settings before RiistaSDK has been initialized")
            return
        }

        guard let remoteSettingsJson = remoteSettingsJson else {
            CrashlyticsHelper.log(msg: "Refusing to apply remote RiistaSDK settings (null settings)!")
            return
        }

        CrashlyticsHelper.log(msg: "Parsing remote RiistaSDK settings..")

        if let remoteSettings = parseAndOverrideRemoteSettings(remoteSettingsJson: remoteSettingsJson)  {
            CrashlyticsHelper.log(msg: "Applying remote RiistaSDK settings")
            RiistaSDK.shared.remoteSettings().updateWithRemoteSettings(remoteSettings: remoteSettings)
            CrashlyticsHelper.log(msg: "Remote RiistaSDK settings applied")
        } else {
            CrashlyticsHelper.log(msg: "Failed to parse remote settings \(remoteSettingsJson)")
        }
    }

    private class func parseAndOverrideRemoteSettings(remoteSettingsJson: String?) -> RemoteSettingsDTO? {
        // no need to parse settings as currently we're overriding all settings!
        return RemoteSettingsDTO(
            groupHunting: GroupHuntingSettingsDTO(
                enabledForAll: true,
                enabledForHunters: []
            )
        )
        /*
        if let remoteSettingsDTO = RiistaSDK.shared.remoteSettings().parseRemoteSettingsJson(remoteSettingsJson: remoteSettingsJson) {
            // override only partially
        } else {
            return nil or default overrides
        }
        */
    }

    @objc class func displayAppStartupMessage(parentViewController: UIViewController) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to display app startup message before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Trying to obtain application startup message")

        let startupMessageHandler = RiistaSDK.shared.appStartupMessageHandler()
        guard let startupMessage = startupMessageHandler.getAppStartupMessageToBeDisplayed() else {
            CrashlyticsHelper.log(msg: "No startup message to be displayed")
            return
        }

        guard let language = RiistaSettings.language() else {
            CrashlyticsHelper.log(msg: "Language must be known before attempting to display startup message")
            return
        }

        let title = startupMessage.localizedTitle(languageCode: language)
        let message = startupMessage.localizedMessage(languageCode: language)
        // either title or message is required
        if (title == nil && message == nil) {
            CrashlyticsHelper.log(msg: "Not showing startup message with no title or message")
            return
        }

        CrashlyticsHelper.log(msg: "Displaying application startup message")

        let messageController = MDCAlertController(title: title, message: message)
        let okAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Ok"),
                                      handler: { (alert: MDCAlertAction!) -> Void in
            CrashlyticsHelper.log(msg: "Application startup message dismissed")
        })
        messageController.addAction(okAction)

        parentViewController.present(messageController, animated: true, completion: nil)
    }

    /**
     * Copies all network cookies from RiistaSDK to MKNetworkKit and thus allows making authenticated
     * network
     */
    @objc class func copyAuthenticationCookiesFromRiistaSDK() {
        let cookies = RiistaSDK.shared.getAllNetworkCookies()

        let cookieStorage = HTTPCookieStorage.shared
        cookies.forEach { (cookieData: CookieData) in
            var cookieProperties: [HTTPCookiePropertyKey : Any] = [
                .name: cookieData.name,
                .value: cookieData.value,
                .secure : cookieData.secure
            ]
            if let domain = cookieData.domain {
                cookieProperties[.domain] = domain
            }
            if let path = cookieData.path {
                cookieProperties[.path] = path
            }
            if let millisecondsFromEpoch = cookieData.expiresTimestamp {
                let secondsFromEpoch = TimeInterval(millisecondsFromEpoch.doubleValue / 1000.0)
                cookieProperties[.expires] = Date(timeIntervalSince1970: secondsFromEpoch)
            }

            if let cookie = HTTPCookie(properties: cookieProperties) {
                cookieStorage.setCookie(cookie)
            } else {
                CrashlyticsHelper.log(msg: "Failed to create cookie with properties!")
            }
        }
    }
}
