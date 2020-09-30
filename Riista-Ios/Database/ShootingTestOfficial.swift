import Foundation

struct ShootingTestOfficial : Codable {
    let id : Int?
    let shootingTestEventId : Int?
    let occupationId : Int?
    let personId : Int?
    let firstName : String?
    let lastName : String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case shootingTestEventId = "shootingTestEventId"
        case occupationId = "occupationId"
        case personId = "personId"
        case firstName = "firstName"
        case lastName = "lastName"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        shootingTestEventId = try values.decodeIfPresent(Int.self, forKey: .shootingTestEventId)
        occupationId = try values.decodeIfPresent(Int.self, forKey: .occupationId)
        personId = try values.decodeIfPresent(Int.self, forKey: .personId)
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
    }
}
