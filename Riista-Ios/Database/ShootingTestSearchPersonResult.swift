import Foundation

struct ShootingTestSearchPersonResult : Codable {
    struct ClassConstants{
        static let REGISTRATION_STATUS_COMPLETED = "COMPLETED"
        static let REGISTRATION_STATUS_OFFICIAL = "DISQUALIFIED_AS_OFFICIAL"
        static let REGISTRATION_STATUS_IN_PROGRESS = "IN_PROGRESS"
        static let REGISTRATION_STATUS_HUNTING_PAYMENT_DONE = "HUNTING_PAYMENT_DONE"
        static let REGISTRATION_STATUS_HUNTING_PAYMENT_NOT_DONE = "HUNTING_PAYMENT_NOT_DONE"
        static let REGISTRATION_STATUS_HUNTING_BAN = "HUNTING_BAN"
        static let REGISTRATION_STATUS_NOT_HUNTER = "NO_HUNTER_NUMBER"
        static let REGISTRATION_STATUS_FOREIGN_HUNTER = "FOREIGN_HUNTER"
    }

    let id : Int?
    let firstName : String?
    let lastName : String?
    let hunterNumber : String?
    let dateOfBirth : String?
    let registrationStatus : String?
    let selectedShootingTestTypes : SelectedShootingTestTypes?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case firstName = "firstName"
        case lastName = "lastName"
        case hunterNumber = "hunterNumber"
        case dateOfBirth = "dateOfBirth"
        case registrationStatus = "registrationStatus"
        case selectedShootingTestTypes = "selectedShootingTestTypes"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
        hunterNumber = try values.decodeIfPresent(String.self, forKey: .hunterNumber)
        dateOfBirth = try values.decodeIfPresent(String.self, forKey: .dateOfBirth)
        registrationStatus = try values.decodeIfPresent(String.self, forKey: .registrationStatus)
        selectedShootingTestTypes = try values.decodeIfPresent(SelectedShootingTestTypes.self, forKey: .selectedShootingTestTypes)
    }
}
