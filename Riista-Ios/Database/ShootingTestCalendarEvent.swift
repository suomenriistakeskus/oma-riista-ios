import Foundation

struct ShootingTestCalendarEvent : Codable {
    struct ClassConstants{
        static let EVENT_TYPE_SHOOTING_TEST = "AMPUMAKOE";
        static let EVENT_TYPE_BOW_SHOOTING_TEST = "JOUSIAMPUMAKOE";
    }

    let rhyId : Int?
    let calendarEventId : Int?
    let shootingTestEventId : Int?
    let calendarEventType : String?
    let name : String?
    let description : String?
    let date : String?
    let beginTime : String?
    let endTime : String?
    let lockedTime : String?
    let venue : ShootingTestVenue?
    let officials : [ShootingTestOfficial]?
    let numberOfAllParticipants : Int?
    let numberOfParticipantsWithNoAttempts : Int?
    let numberOfCompletedParticipants : Int?
    let totalPaidAmount : Decimal?

    enum CodingKeys: String, CodingKey {
        case rhyId = "rhyId"
        case calendarEventId = "calendarEventId"
        case shootingTestEventId = "shootingTestEventId"
        case calendarEventType = "calendarEventType"
        case name = "name"
        case description = "description"
        case date = "date"
        case beginTime = "beginTime"
        case endTime = "endTime"
        case lockedTime = "lockedTime"
        case venue = "venue"
        case officials = "officials"
        case numberOfAllParticipants = "numberOfAllParticipants"
        case numberOfParticipantsWithNoAttempts = "numberOfParticipantsWithNoAttempts"
        case numberOfCompletedParticipants = "numberOfCompletedParticipants"
        case totalPaidAmount = "totalPaidAmount"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rhyId = try values.decodeIfPresent(Int.self, forKey: .rhyId)
        calendarEventId = try values.decodeIfPresent(Int.self, forKey: .calendarEventId)
        shootingTestEventId = try values.decodeIfPresent(Int.self, forKey: .shootingTestEventId)
        calendarEventType = try values.decodeIfPresent(String.self, forKey: .calendarEventType)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        date = try values.decodeIfPresent(String.self, forKey: .date)
        beginTime = try values.decodeIfPresent(String.self, forKey: .beginTime)
        endTime = try values.decodeIfPresent(String.self, forKey: .endTime)
        lockedTime = try values.decodeIfPresent(String.self, forKey: .lockedTime)
        venue = try values.decodeIfPresent(ShootingTestVenue.self, forKey: .venue)
        officials = try values.decodeIfPresent([ShootingTestOfficial].self, forKey: .officials)
        numberOfAllParticipants = try values.decodeIfPresent(Int.self, forKey: .numberOfAllParticipants)
        numberOfParticipantsWithNoAttempts = try values.decodeIfPresent(Int.self, forKey: .numberOfParticipantsWithNoAttempts)
        numberOfCompletedParticipants = try values.decodeIfPresent(Int.self, forKey: .numberOfCompletedParticipants)
        totalPaidAmount = try values.decodeIfPresent(Decimal.self, forKey: .totalPaidAmount)
    }

    func isWaitingToStart() -> Bool {
        return self.shootingTestEventId == nil;
    }

    func isOngoing() -> Bool {
        return self.shootingTestEventId != nil && !isClosed();
    }

    func isClosed() -> Bool
    {
        return self.shootingTestEventId != nil && self.lockedTime != nil && !(self.lockedTime?.isEmpty)!;
    }

    func isReadyToClose() -> Bool {
        return isOngoing() && numberOfAllParticipants == numberOfCompletedParticipants;
    }

    static func localizedTypeText(type: String) -> String {
        switch type {
        case ClassConstants.EVENT_TYPE_SHOOTING_TEST:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestCalendarEventTypeNormal")
        case ClassConstants.EVENT_TYPE_BOW_SHOOTING_TEST:
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestCalendarEventTypeBow")
        default:
            return type
        }
    }
}
