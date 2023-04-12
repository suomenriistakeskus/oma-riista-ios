import Foundation
import Siren

@objc class AppUpdateNotifier: NSObject {

    static let DEFAULT_PROMOTION_DELAY_DAYS: Int = 21

    /**
     * Checks app version and displays an update dialog if needed.
     *
     * This function is meant to be called from landing page i.e. Siren's update dialog is launched in .onDemand mode.
     */
    @objc class func checkVersionAndLaunchUpdateDialogFromLandingPage() {
        let siren = Siren.shared

        let updateDelayDays = RemoteConfigurationManager.sharedInstance.appUpdatePromotionDelayDays() ??
            DEFAULT_PROMOTION_DELAY_DAYS

        siren.rulesManager = RulesManager(
            majorUpdateRules: .default,
            minorUpdateRules: .relaxed,
            patchUpdateRules: .relaxed,
            revisionUpdateRules: .relaxed,
            showAlertAfterCurrentVersionHasBeenReleasedForDays: updateDelayDays
        )

        siren.presentationManager = PresentationManager(
            alertTitle: "UpdateAvailableTitle".localized(),
            alertMessage: "UpdateAvailableMessage".localized(),
            updateButtonTitle: "UpdateAction".localized()
        )

        // use .onDemand as this function is meant to be called from the landing page and not
        // from app delegate
        siren.wail(performCheck: .onDemand) { _ in
            // nop
        }
    }
}
