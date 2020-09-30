import Foundation

@objc public class FeatureAvailabilityChecker: NSObject
{
    @objc public enum Feature: Int {
        case displayDeerHuntingType
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
        default:
            break
        }

        return false
    }
}
