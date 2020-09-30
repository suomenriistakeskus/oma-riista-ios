import Foundation

struct ShootingTestAttemptDetailed : Codable {
    struct ClassConstants{
        static let TYPE_BEAR = "BEAR";
        static let TYPE_MOOSE = "MOOSE";
        static let TYPE_ROE_DEER = "ROE_DEER";
        static let TYPE_BOW = "BOW";

        static let RESULT_QUALIFIED = "QUALIFIED";
        static let RESULT_UNQUALIFIED = "UNQUALIFIED";
        static let RESULT_TIMED_OUT = "TIMED_OUT";
        static let RESULT_REBATED = "REBATED";
    }

    let id : Int?
    let rev : Int?
    let type : String?
    let result : String?
    let hits : Int?
    let note : String?
    let author : String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case rev = "rev"
        case type = "type"
        case result = "result"
        case hits = "hits"
        case note = "note"
        case author = "author"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        rev = try values.decodeIfPresent(Int.self, forKey: .rev)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        result = try values.decodeIfPresent(String.self, forKey: .result)
        hits = try values.decodeIfPresent(Int.self, forKey: .hits)
        note = try values.decodeIfPresent(String.self, forKey: .note)
        author = try values.decodeIfPresent(String.self, forKey: .author)
    }

    init(type: String?, hits: Int?, result: String?, note: String?) {
        self.id = nil
        self.rev = nil
        self.type = type
        self.result = result
        self.hits = hits
        self.note = note
        self.author = nil
    }

    static func localizedTypeText(value: String) -> String {
        switch value {
        case ClassConstants.TYPE_BEAR:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBear")
        case ClassConstants.TYPE_MOOSE:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeMoose")
        case ClassConstants.TYPE_ROE_DEER:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeRoeDeer")
        case ClassConstants.TYPE_BOW:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBow")
        default:
            return value
        }
    }

    static func localizedResultText(value: String) -> String {
        switch value {
        case ClassConstants.RESULT_QUALIFIED:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultQualified")
        case ClassConstants.RESULT_UNQUALIFIED:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultUnqualified")
        case ClassConstants.RESULT_TIMED_OUT:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultTimedOut")
        case ClassConstants.RESULT_REBATED:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultRebated")
        default:
            return value
        }
    }

    static func textToResultValue(text: String?) -> String? {
        switch text {
        case RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultQualified")?:
            return ClassConstants.RESULT_QUALIFIED
        case RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultUnqualified")?:
            return ClassConstants.RESULT_UNQUALIFIED
        case RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultTimedOut")?:
            return ClassConstants.RESULT_TIMED_OUT
        case RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestResultRebated")?:
            return ClassConstants.RESULT_REBATED
        default:
            return nil
        }
    }

    func validateData() -> Bool {
        let validTypes = [ClassConstants.TYPE_BEAR, ClassConstants.TYPE_MOOSE, ClassConstants.TYPE_ROE_DEER, ClassConstants.TYPE_BOW]
        if (self.type == nil || !validTypes.contains(self.type!)) {
            print(String(format: "ShootingTestAttemptDetailed: Not valid type: %@", self.type ?? "nil"))
            return false
        }

        if (self.hits == nil || self.hits! < 0 || self.hits! > 4) {
            print(String(format: "ShootingTestAttemptDetailed: Not valid hits: %d", self.hits ?? "nil"))
            return false
        }

        if (ClassConstants.TYPE_BOW == self.type && self.hits == 4) {
            print("ShootingTestAttemptDetailed: Bow test with 4 hits")
            return false
        }

        let validResults = [ClassConstants.RESULT_QUALIFIED, ClassConstants.RESULT_UNQUALIFIED, ClassConstants.RESULT_TIMED_OUT, ClassConstants.RESULT_REBATED]
        if (self.result == nil || !validResults.contains(self.result!)) {
            print("ShootingTestAttemptDetailed: Not valid result: %@", self.result ?? "nil")
            return false
        }

        return true
    }
}
