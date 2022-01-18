import Foundation

@objc public class FeatureAvailabilityChecker: NSObject
{
    @objc public enum Feature: Int {
        case displayDeerHuntingType
        case antlers2020Fields

        // a global flag for experimental mode: Allows hiding features behind this flag
        // and user needs to specifically enable this mode to see the feature
        case experimentalMode
    }

    @objc static public let shared: FeatureAvailabilityChecker = {
        return FeatureAvailabilityChecker()
    }()

    private override init() {
        // nop
    }

    @objc public func isEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .displayDeerHuntingType:
            return RiistaSettings.userInfo()?.deerPilotUser ?? false
        case .antlers2020Fields:
            return RiistaSettings.userInfo()?.deerPilotUser ?? false
        case .experimentalMode:
            return RiistaSettings.useExperimentalMode() &&
                RemoteConfigurationManager.sharedInstance.experimentalModeAllowed()
        default:
            break
        }

        return false
    }

    @objc public func toggleExperimentalMode() {
        let experimentalModeEnabled = RiistaSettings.useExperimentalMode()
        RiistaSettings.setUseExperimentalMode(!experimentalModeEnabled)
    }
}
