import Foundation

struct ShootingTestVenueAddress : Codable {
    let id : Int?
    let rev : Int?
    let streetAddress : String?
    let postalCode : String?
    let city : String?
    let country : String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case rev = "rev"
        case streetAddress = "streetAddress"
        case postalCode = "postalCode"
        case city = "city"
        case country = "country"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        rev = try values.decodeIfPresent(Int.self, forKey: .rev)
        streetAddress = try values.decodeIfPresent(String.self, forKey: .streetAddress)
        postalCode = try values.decodeIfPresent(String.self, forKey: .postalCode)
        city = try values.decodeIfPresent(String.self, forKey: .city)
        country = try values.decodeIfPresent(String.self, forKey: .country)
    }
}
