import Foundation

@objc public enum ObservationWithinHuntingCapability: Int, RawRepresentable {
    case yes
    case no
    case deerPilot

    // prepare for future: unknown if we cannot parse string to enum value. This should
    // probably be treated as .no elsewhere
    case unknown
}

@objc public class ObservationWithinHuntingCapabilityParser: NSObject {
    static let capabilityStrings: Dictionary<String, ObservationWithinHuntingCapability> = ["YES": .yes, "NO": .no, "DEER_PILOT": .deerPilot]

    @objc public static func parse(capabilityStr: String?, fallback: ObservationWithinHuntingCapability) -> ObservationWithinHuntingCapability {
        if (capabilityStr == nil) {
            return .unknown
        }

        return ObservationWithinHuntingCapabilityParser.capabilityStrings[capabilityStr!] ?? fallback
    }
}
