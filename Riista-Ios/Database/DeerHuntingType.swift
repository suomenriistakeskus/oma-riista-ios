import Foundation

@objc enum DeerHuntingType: Int, CustomStringConvertible {
    // in Finnish: "Kyttääminen / vahtiminen"
    case standHunting
    // in Finnish: "Seuruemetsästys koiran kanssa"
    case dogHunting
    case other

    // for cases when no deer hunting type has been selected.
    // - this value can NEVER be directly obtained from backend. Instead nil returned by backend can be interpret as .none
    case none

    var description: String {
        // don't use DeerHuntingTypeHelper string conversion as it lacks value for .none
        switch self {
        case .standHunting:
            return ".standHunting"
        case .dogHunting:
            return ".dogHunting"
        case .other:
            return ".other"
        case .none:
            return ".none"
        default:
            return "<unknown>"
        }
    }
}

@objc class DeerHuntingTypeHelper: NSObject {
    // leave .none out of the strings intentionally. This way conversion to string will produce nil
    // and we don't accidentally send .none type to backend
    static let typeStrings: Dictionary<DeerHuntingType, String> = [.standHunting: "STAND_HUNTING", .dogHunting: "DOG_HUNTING", .other: "OTHER"]

    @objc public static func stringFor(deerHuntingType: DeerHuntingType) -> String? {
        if let typeString = DeerHuntingTypeHelper.typeStrings[deerHuntingType] {
            return typeString
        } else if (deerHuntingType != .none) {
            print("Failed to obtain a string for \(deerHuntingType)")
        }
        return nil
    }

    /**
     Attempts to parse the given string as DeerHuntingType. Will return .other  if parsing fails.
     */
    @objc public static func parse(huntingTypeString: String, fallback: DeerHuntingType) -> DeerHuntingType {
        let deerHuntingType = DeerHuntingTypeHelper.typeStrings.first { (key: DeerHuntingType, value: String) -> Bool in
            return value == huntingTypeString
        }?.key

        if (deerHuntingType != nil) {
            return deerHuntingType!
        } else {
            print("DeerHuntingType parsing failed: \(huntingTypeString), returning \(fallback)")
            return fallback
        }
    }
}
