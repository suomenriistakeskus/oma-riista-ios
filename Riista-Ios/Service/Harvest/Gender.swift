import Foundation

@objc enum Gender: Int, CustomStringConvertible {
    case male
    case female
    case unknown

    var description: String {
        return GenderHelper.stringFor(gender: self)!
    }
}

@objc class GenderHelper: NSObject {
    static let typeStrings: Dictionary<Gender, String> = [.male: "MALE", .female: "FEMALE", .unknown: "UNKNOWN"]

    @objc public static func stringFor(gender: Gender) -> String? {
        return GenderHelper.typeStrings[gender]
    }

    /**
     Attempts to parse the given string as Gender. Will return given fallback  if parsing fails.
     */
    @objc public static func parse(genderString: String?, fallback: Gender) -> Gender {
        guard let genderString = genderString else {
            print("Gender parsing failed: <nil>, returning \(fallback)")
            return fallback
        }

        let gender = GenderHelper.typeStrings.first { (key: Gender, value: String) -> Bool in
            return value == genderString
        }?.key

        if let gender = gender {
            return gender
        }

        print("Gender parsing failed: \(genderString), returning \(fallback)")
        return fallback
    }
}
