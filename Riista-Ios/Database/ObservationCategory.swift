import Foundation

@objc public enum ObservationCategory: Int {
    case normal
    case mooseHunting
    case deerHunting

    // future proofing: there may be categories not yet known. This should probably be
    // treated as .normal elsewhere in the code
    case unknown
}

@objc class ObservationCategoryHelper: NSObject {
    static let categoryStrings: Dictionary<ObservationCategory, String> = [.normal: "NORMAL", .mooseHunting: "MOOSE_HUNTING", .deerHunting: "DEER_HUNTING"]

    @objc public static func categoryStringFor(category: ObservationCategory) -> String? {
        return ObservationCategoryHelper.categoryStrings[category]
    }

    /**
     Attempts to parse the given string as ObservationCategory. Will return given fallback if parsing fails.
     */
    @objc public static func parse(categoryString: String, fallback: ObservationCategory) -> ObservationCategory {
        let category = ObservationCategoryHelper.categoryStrings.first { (key: ObservationCategory, value: String) -> Bool in
            return value == categoryString
        }?.key

        if (category != nil) {
            return category!
        } else {
            print("ObservationCategory parsing failed: \(categoryString), returning \(fallback)")
            return fallback
        }
    }
}

@objc protocol ObservationCategoryChangedDelegate: AnyObject {
    func onObservationCategoryChanged(_ newObservationCategory: ObservationCategory)
}
