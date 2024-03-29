import Foundation
import RiistaCommon

import MaterialComponents.MaterialDialogs

typealias OnLoginCompleted = (NetworkResponse<UserInfoDTO>?, Error?) -> Void


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
                  serverBaseAddress: Environment.serverBaseAddress,
                  crashlyticsLogger: CommonCrashlyticsLogger()
            )
            // only allow redirects to absolute urls for debug/beta builds. NOT FOR PRODUCTION!
            .setAllowRedirectsToAbsoluteHosts(allowed: env == .dev || env == .staging)
            .initializeRiistaSDK()

        CrashlyticsHelper.log(msg: "RiistaSDK initialization completed")

        MigrateUserInformationToRiistaCommon.scheduleMigration()

        riistaSdkInitialized = true
    }

    @objc class func login(
        username: String,
        password: String,
        timeoutSeconds: Int,
        onCompleted: @escaping OnLoginCompleted
    ) {
        Thread.onMainThread {
            RiistaSDK.shared.login(
                username: username,
                password: password,
                timeoutSeconds: Int32(timeoutSeconds),
                completionHandler: handleOnMainThread { response, error in
                    onCompleted(response, error)
                }
            )
        }
    }

    @objc class func logout(_ onCompleted: @escaping OnCompleted) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to logout before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Logging out RiistaSDK..")

        RiistaSDK.shared.logout(
            completionHandler: handleOnMainThread { _ in
                CrashlyticsHelper.log(msg: "RiistaSDK logged out")
                onCompleted()
            }
        )
    }

    @objc class func prepareAppStartupMessage(_ messageJson: String?) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to prepare app startup message before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Preparing application startup message")

        RiistaSDK.shared.appStartupMessageHandler.parseAppStartupMessageFromJson(messageJson: messageJson)

        CrashlyticsHelper.log(msg: "Application startup message prepared")
    }

    @objc class func setupMapTileVersions(_ mapTileVersionsJson: String?) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to setup map tile versions before RiistaSDK has been initialized")
            return
        }

        CrashlyticsHelper.log(msg: "Setting map tile versions")

        RiistaSDK.shared.mapTileVersions.parseMapTileVersions(versionsJson: mapTileVersionsJson)

        CrashlyticsHelper.log(msg: "Map tile versions applied")
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

    @objc class func synchronize(
        synchronizationLevel: SynchronizationLevel,
        synchronizationConfig: SynchronizationConfig,
        completion: @escaping OnCompleted
    ) {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to synchronize before RiistaSDK has been initialized")
            completion()
            return
        }

        RiistaSDK.shared.synchronize(
            synchronizedContent: SynchronizedContent.SelectedLevel(synchronizationLevel: synchronizationLevel),
            config: synchronizationConfig
        ) { _ in
            Thread.onMainThread(completion)
        }
    }

    // Returns true if startup message was displayed, otherwise returns false
    @objc class func displayAppStartupMessage(parentViewController: UIViewController) -> Bool {
        if (!riistaSdkInitialized) {
            CrashlyticsHelper.log(msg: "Refusing to display app startup message before RiistaSDK has been initialized")
            return false
        }

        CrashlyticsHelper.log(msg: "Trying to obtain application startup message")

        let startupMessageHandler = RiistaSDK.shared.appStartupMessageHandler
        guard let startupMessage = startupMessageHandler.getAppStartupMessageToBeDisplayed() else {
            CrashlyticsHelper.log(msg: "No startup message to be displayed")
            return false
        }

        guard let language = RiistaSettings.language() else {
            CrashlyticsHelper.log(msg: "Language must be known before attempting to display startup message")
            return false
        }

        let title = startupMessage.localizedTitle(languageCode: language)
        let message = startupMessage.localizedMessage(languageCode: language)
        let linkName = startupMessage.link?.localizedName(languageCode: language)
        let linkUrl = startupMessage.link?.localizedUrl(languageCode: language)

        // either title or message is required
        if (title == nil && message == nil) {
            CrashlyticsHelper.log(msg: "Not showing startup message with no title or message")
            return false
        }

        CrashlyticsHelper.log(msg: "Displaying application startup message")

        if (startupMessage.preventFurtherAppUsage) {
            // prevent further app usage i.e. prevent sync
            AppSync.shared.disableSyncPrecondition(.furtherAppUsageAllowed)

            WarningViewController(
                navBarTitle: title,
                messageTitle: nil,
                message: message,
                buttonText: linkName,
                buttonOnClicked: {
                    if let linkUrl = linkUrl, let url = URL(string: linkUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            ).showAsNonDismissible(parentViewController: parentViewController)
        } else {
            let messageController = MDCAlertController(title: title, message: message)
            let okAction = MDCAlertAction(title: "Ok".localized()) { _ in
                CrashlyticsHelper.log(msg: "Application startup message dismissed")
            }
            messageController.addAction(okAction)

            if let linkName = linkName, let linkUrl = linkUrl, let targetUrl = URL(string: linkUrl) {
                let linkAction = MDCAlertAction(title: linkName) { _ in
                    UIApplication.shared.open(targetUrl)
                }
                messageController.addAction(linkAction)
            }

            parentViewController.present(messageController, animated: true, completion: nil)
        }

        return true
    }

    /**
     * Copies all network cookies from RiistaSDK to MKNetworkKit and thus allows making authenticated
     * network calls
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
                // apparentally setting cookie is not always enough to overwrite cookie. This worked on some of
                // the test device but also failed when testing on iOS simulator 13.7 (iphone se)
                //
                // The most probable cause for failure is that existing cookie has isHttpOnly == true and
                // we're not setting that value. When testing the cookie was correctly updated when we either
                // set `HTTPCookiePropertyKey("HttpOnly"): true` or delete the matching cookie in storage
                //
                // -> Setting HttpOnly property is undocumented and thus let's delete the existing cookie
                cookieStorage.deleteMatchingCookie(cookieData: cookieData)

                // both MKNetwork and Alamofire use the same cookieStorage
                cookieStorage.setCookie(cookie)
            } else {
                CrashlyticsHelper.log(msg: "Failed to create cookie with properties!")
            }
        }
    }
}


fileprivate extension HTTPCookieStorage {
    func deleteMatchingCookie(cookieData: CookieData) {
        guard let cookie = self.cookies?.first(where: { cookie in
            cookie.name == cookieData.name &&
            cookie.domain == cookieData.domain &&
            cookie.path == cookieData.path
        }) else {
            print("No matching cookie, cannot remove")
            return
        }

        print("Matching cookie found, removing it")
        deleteCookie(cookie)
    }
}
