import Foundation

struct ShootingTestVenue : Codable {
    let id : Int?
    let rev : Int?
    let name : String?
    let address : ShootingTestVenueAddress?
    let info : String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case rev = "rev"
        case name = "name"
        case address = "address"
        case info = "info"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        rev = try values.decodeIfPresent(Int.self, forKey: .rev)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        address = try values.decodeIfPresent(ShootingTestVenueAddress.self, forKey: .address)
        info = try values.decodeIfPresent(String.self, forKey: .info)
    }
}
