import Foundation

class ShootingTestManager: NSObject {
    struct ClassConstants{
        static let BASE_API_PATH = "api/mobile/v2/"

        static let listShootingTestCalendarEventsPAth = BASE_API_PATH + "shootingtest/calendarevents"
        static let getCalendarEventPath = BASE_API_PATH + "shootingtest/calendarevent/%ld"

        static let startEventPath = BASE_API_PATH + "shootingtest/calendarevent/%ld/open"
        static let closeEventPath = BASE_API_PATH + "shootingtest/event/%ld/close"
        static let reopenEventPath = BASE_API_PATH + "shootingtest/event/%ld/reopen"
        static let updateEventOfficialsPath = BASE_API_PATH + "shootingtest/event/%ld/officials"

        static let listAvailableOfficialsForEventPath = BASE_API_PATH + "shootingtest/event/%ld/qualifyingofficials/"
        static let listAvailableOfficialsForRhyPath = BASE_API_PATH + "shootingtest/rhy/%ld/officials/"
        static let listSelectedOfficialsForEventPath = BASE_API_PATH + "shootingtest/event/%ld/assignedofficials/"

        static let getParticipantDetailedPath = BASE_API_PATH + "shootingtest/participant/%ld/attempts"

        static let searchWithHunterNumberPath = BASE_API_PATH + "shootingtest/event/%ld/findhunter/hunternumber"
        static let searchWithSsnPath = BASE_API_PATH + "shootingtest/event/%ld/findperson/ssn"
        static let addParticipantPath = BASE_API_PATH + "shootingtest/event/%ld/participant"

        static let listParticipantsPath = BASE_API_PATH + "shootingtest/event/%ld/participants"

        static let getAttemptPath = BASE_API_PATH + "shootingtest/attempt/%ld"
        static let addAttemptPath = BASE_API_PATH + "shootingtest/participant/%ld/attempt"
        static let deleteAttemptPath = BASE_API_PATH + "shootingtest/attempt/%ld"
        static let updateAttemptPath = BASE_API_PATH + "shootingtest/attempt/%ld"

        static let getParticipantSummaryPath = BASE_API_PATH + "shootingtest/participant/%ld"
        static let completeAllPaymentsPath = BASE_API_PATH + "shootingtest/participant/%ld/payment"
        static let updatePaymentPath = BASE_API_PATH + "shootingtest/participant/%ld/payment"
    }

//    typealias RiistaJsonCompletion = (NSDictionary, NSError?) -> Void
//    typealias RiistaShootingTestEventsCompletion = (Array<Any>?, NSError?) -> Void

    class func fetchShootingTestEvents(completion:@escaping RiistaJsonArrayCompletion) {
        let network = RiistaNetworkManager.sharedInstance()
        network?.listShootingTestCalendarEvents(completion)
    }

    class func getShootingTestCalendarEvent(eventId: Int, completion: @escaping RiistaJsonCompletion) {
        let network = RiistaNetworkManager.sharedInstance()
        network?.getShootingTestCalendarEvent(Int(eventId), completion: completion)
    }

    // MARK: Event state handling

    class func startShootingTestEvent(calendarEventId: Int,
                                      shootingTestEventId: Int?,
                                      occupationIds: Array<Int>,
                                      completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.startEventPath, calendarEventId)
        var body = [String : Any?]()
        body["calendarEventId"] = String(calendarEventId)
        body["shootingTestEventId"] = shootingTestEventId
        body["occupationIds"] = occupationIds

        let network = RiistaNetworkManager.sharedInstance()
        network?.startEvent(url, body: body as [String : Any], completion: completion)
    }

    class func closeShootingTestEvent(eventId: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.closeEventPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.closeEvent(url, completion: completion)
    }

    class func reopenShootingTestEvent(eventId: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.reopenEventPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.reopenEvent(url, completion: completion)
    }

    class func updateShootingTestOfficials(calendarEventId: Int,
                                           shootingTestEventId: Int,
                                           occupationIds: Array<Int>,
                                           completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.updateEventOfficialsPath, shootingTestEventId)
        var body = [String : Any]()
        body["calendarEventId"] = String(calendarEventId)
        body["shootingTestEventId"] = String(shootingTestEventId)
        body["occupationIds"] = occupationIds

        let network = RiistaNetworkManager.sharedInstance()
        network?.updateOfficials(url, body: body, completion: completion)
    }

    class func listAvailableOfficialsForEvent(eventId: Int, completion: @escaping RiistaJsonArrayCompletion) {
        let url = String(format: ClassConstants.listAvailableOfficialsForEventPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.listAvailableOfficials(forEvent: url, completion: completion)
    }

    class func listAvailableOfficialsForRhy(rhyID: Int, completion: @escaping RiistaJsonArrayCompletion) {
        let url = String(format: ClassConstants.listAvailableOfficialsForRhyPath, rhyID)

        let network = RiistaNetworkManager.sharedInstance()
        network?.listAvailableOfficials(forRhy: url, completion: completion)
    }

    class func listSelectedOfficialsForEvent(eventId: Int, completion: @escaping RiistaJsonArrayCompletion) {
        let url = String(format: ClassConstants.listSelectedOfficialsForEventPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.listSelectedOfficials(forEvent: url, completion: completion)
    }

    // MARK: Registration

    class func searchWithHuntingNumberForEvent(eventId: Int,
                                               hunterNumber: String,
                                               completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.searchWithHunterNumberPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.searchWithHuntingNumber(forEvent: url, hunterNumber: hunterNumber, completion: completion)
    }

    class func searchWithSsnForEvent(eventId: Int,
                                     ssn: String,
                                     completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.searchWithSsnPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.searchWithSsn(forEvent: url, ssn: ssn, completion: completion)
    }

    class func addParticipantToEvent(eventId: Int,
                                     hunterNumber: String,
                                     bearTestIntended: Bool,
                                     mooseTestIntended: Bool,
                                     roeDeerTestIntended: Bool,
                                     bowTestIntended: Bool,
                                     completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.addParticipantPath, eventId)

        let types = ["mooseTestIntended": mooseTestIntended,
                     "bearTestIntended": bearTestIntended,
                     "roeDeerTestIntended": roeDeerTestIntended,
                     "bowTestIntended": bowTestIntended]

        var body = [String : Any]()
        body["hunterNumber"] = hunterNumber
        body["selectedTypes"] = types

        let network = RiistaNetworkManager.sharedInstance()
        network?.addParticipant(url, body: body, completion: completion)
    }

    // MARK: Attempts

    class func getParticipantDetailed(participantId: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.getParticipantDetailedPath, participantId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.getParticipantDetailed(url, completion: completion)
    }

    class func getAttempt(attemptId: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.getAttemptPath, attemptId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.getAttempt(url, completion: completion)
    }

    class func addAttemptForParticipant(participantId: Int,
                                        particiopantRev: Int,
                                        type: String, // "MOOSE" "BEAR" "ROE_DEER" "BOW"
                                        result: String, // "QUALIFIED" "UNQUALIFIED" "TIMED_OUT" "REBATED"
                                        hits: Int, // [0..4]
                                        note: String?,
                                        completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.addAttemptPath, participantId)
        var body = [String : Any]()
        body["participantId"] = String(participantId)
        body["participantRev"] = String(particiopantRev)
        body["type"] = type
        body["result"] = result
        body["hits"] = String(hits)
        body["note"] = note

        let network = RiistaNetworkManager.sharedInstance()
        network?.addAttempt(url, body: body, completion: completion)
    }

    class func updateAttempt(attemptId: Int,
                             rev: Int,
                             participantId: Int,
                             participantRev: Int,
                             type: String,
                             result: String,
                             hits: Int,
                             note: String?,
                             completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.updateAttemptPath, attemptId)
        var body = [String : Any]()
        body["rev"] = String(rev)
        body["participantId"] = String(participantId)
        body["participantRev"] = String(participantRev)
        body["type"] = type
        body["result"] = result
        body["hits"] = String(hits)
        body["note"] = note

        let network = RiistaNetworkManager.sharedInstance()
        network?.updateAttempt(url, body: body, completion: completion)
    }

    class func deleteAttempt(attemptId: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.deleteAttemptPath, attemptId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.deleteAttempt(url, completion: completion)
    }

    // MARK: Participants

    class func listParticipantsForEvent(eventId: Int, completion: @escaping RiistaJsonArrayCompletion) {
        let url = String(format: ClassConstants.listParticipantsPath, eventId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.listParticipants(url, unfinishedOnly: false, completion: completion)
    }

    // MARK: Payments

    class func getParticipantSummary(participantId: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.getParticipantSummaryPath, participantId)

        let network = RiistaNetworkManager.sharedInstance()
        network?.getParticipantSummary(url, completion: completion)
    }

    class func completeAllPayments(participantId: Int, rev: Int, completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.completeAllPaymentsPath, participantId)
        var body = [String : Any]()
        body["rev"] = String(rev)

        let network = RiistaNetworkManager.sharedInstance()
        network?.completeAllPayments(url, body: body, completion: completion)
    }

    class func updatePaymentStateForParticipant(participantId: Int,
                                                rev: Int,
                                                paidAttempts: Int,
                                                completed: Bool,
                                                completion: @escaping RiistaJsonCompletion) {
        let url = String(format: ClassConstants.updatePaymentPath, participantId)
        var body = [String : Any]()
        body["rev"] = rev
        body["paidAttempts"] = paidAttempts
        body["completed"] = String(completed)

        let network = RiistaNetworkManager.sharedInstance()
        network?.updatePaymentState(url, body: body, completion: completion)
    }
}
