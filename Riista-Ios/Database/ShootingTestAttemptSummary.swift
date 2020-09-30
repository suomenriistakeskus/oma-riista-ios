import Foundation

struct ShootingTestAttemptSummary : Codable {
    let type : String?
    let attemptCount : Int?
    let qualified : Bool?

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case attemptCount = "attemptCount"
        case qualified = "qualified"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        attemptCount = try values.decodeIfPresent(Int.self, forKey: .attemptCount)
        qualified = try values.decodeIfPresent(Bool.self, forKey: .qualified)
    }
}
