import Foundation

struct ShootingTestParticipantDetailed : Codable {
    let id : Int?
    let rev : Int?
    let firstName : String?
    let lastName : String?
    let hunterNumber : String?
    let dateOfBirth : String?
    let mooseTestIntended : Bool?
    let bearTestIntended : Bool?
    let deerTestIntended : Bool?
    let bowTestIntended : Bool?
    let registrationTime : String?
    let completed : Bool?
    let attempts : [ShootingTestAttemptDetailed]?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case rev = "rev"
        case firstName = "firstName"
        case lastName = "lastName"
        case hunterNumber = "hunterNumber"
        case dateOfBirth = "dateOfBirth"
        case mooseTestIntended = "mooseTestIntended"
        case bearTestIntended = "bearTestIntended"
        case deerTestIntended = "deerTestIntended"
        case bowTestIntended = "bowTestIntended"
        case registrationTime = "registrationTime"
        case completed = "completed"
        case attempts = "attempts"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        rev = try values.decodeIfPresent(Int.self, forKey: .rev)
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
        hunterNumber = try values.decodeIfPresent(String.self, forKey: .hunterNumber)
        dateOfBirth = try values.decodeIfPresent(String.self, forKey: .dateOfBirth)
        mooseTestIntended = try values.decodeIfPresent(Bool.self, forKey: .mooseTestIntended)
        bearTestIntended = try values.decodeIfPresent(Bool.self, forKey: .bearTestIntended)
        deerTestIntended = try values.decodeIfPresent(Bool.self, forKey: .deerTestIntended)
        bowTestIntended = try values.decodeIfPresent(Bool.self, forKey: .bowTestIntended)
        registrationTime = try values.decodeIfPresent(String.self, forKey: .registrationTime)
        completed = try values.decodeIfPresent(Bool.self, forKey: .completed)
        attempts = try values.decodeIfPresent([ShootingTestAttemptDetailed].self, forKey: .attempts)
    }
}
