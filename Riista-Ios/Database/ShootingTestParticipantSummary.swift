import Foundation

extension ShootingTestParticipantSummary: Equatable {
    static func ==(lhs: ShootingTestParticipantSummary, rhs: ShootingTestParticipantSummary) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: ShootingTestParticipantSummary, rhs: ShootingTestParticipantSummary) -> Bool {
        return ((lhs.attempts?.isEmpty)! && !(rhs.attempts?.isEmpty)!) || (!(lhs.completed!) && rhs.completed!) || lhs.registrationTime! < rhs.registrationTime!
    }
}

struct ShootingTestParticipantSummary : Codable {
    let id : Int?
    let rev : Int?
    let firstName : String?
    let lastName : String?
    let hunterNumber : String?
    let mooseTestIntended : Bool?
    let bearTestIntended : Bool?
    let deerTestIntended : Bool?
    let bowTestIntended : Bool?
    let attempts : [ShootingTestAttemptSummary]?
    let totalDueAmount : Int?
    let paidAmount : Int?
    let remainingAmount : Int?
    let registrationTime : String?
    let completed : Bool?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case rev = "rev"
        case firstName = "firstName"
        case lastName = "lastName"
        case hunterNumber = "hunterNumber"
        case mooseTestIntended = "mooseTestIntended"
        case bearTestIntended = "bearTestIntended"
        case deerTestIntended = "deerTestIntended"
        case bowTestIntended = "bowTestIntended"
        case attempts = "attempts"
        case totalDueAmount = "totalDueAmount"
        case paidAmount = "paidAmount"
        case remainingAmount = "remainingAmount"
        case registrationTime = "registrationTime"
        case completed = "completed"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(Int.self, forKey: .id)
        rev = try values.decodeIfPresent(Int.self, forKey: .rev)
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
        hunterNumber = try values.decodeIfPresent(String.self, forKey: .hunterNumber)
        mooseTestIntended = try values.decodeIfPresent(Bool.self, forKey: .mooseTestIntended)
        bearTestIntended = try values.decodeIfPresent(Bool.self, forKey: .bearTestIntended)
        deerTestIntended = try values.decodeIfPresent(Bool.self, forKey: .deerTestIntended)
        bowTestIntended = try values.decodeIfPresent(Bool.self, forKey: .bowTestIntended)
        attempts = try values.decodeIfPresent([ShootingTestAttemptSummary].self, forKey: .attempts)
        totalDueAmount = try values.decodeIfPresent(Int.self, forKey: .totalDueAmount)
        paidAmount = try values.decodeIfPresent(Int.self, forKey: .paidAmount)
        remainingAmount = try values.decodeIfPresent(Int.self, forKey: .remainingAmount)
        registrationTime = try values.decodeIfPresent(String.self, forKey: .registrationTime)
        completed = try values.decodeIfPresent(Bool.self, forKey: .completed)
    }

    func attemptSummaryFor(type: String) -> ShootingTestAttemptSummary? {
        for summary in self.attempts! {
            if (type == summary.type) {
                return summary
            }
        }

        return nil
    }
}
