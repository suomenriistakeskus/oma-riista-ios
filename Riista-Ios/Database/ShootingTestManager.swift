import Foundation
import RiistaCommon

enum ShootingTestManagerError: Error {
    case missingCalendarId
    case missingShootingTestEventId

    case networkOperationFailed(statusCode: Int?)
    case unspecifiedError
}

typealias OnShootingTestEventFetched = (_ shootingTestEvent: CommonShootingTestCalendarEvent?, _ error: Error?) -> Void
typealias OnShootingTestOfficialsFetched = (_ officials: [CommonShootingTestOfficial]?, _ error: Error?) -> Void
typealias OnShootingTestPersonFetched = (_ person: CommonShootingTestPerson?, _ error: Error?) -> Void
typealias OnShootingTestParticipantsFetched = (_ participants: [CommonShootingTestParticipant]?, _ error: Error?) -> Void
typealias OnShootingTestParticipantFetched = (_ participant: CommonShootingTestParticipant?, _ error: Error?) -> Void
typealias OnShootingTestParticipantDetailedFetched = (_ participant: CommonShootingTestParticipantDetailed?, _ error: Error?) -> Void
typealias OnShootingTestAttemptFetched = (_ attempt: CommonShootingTestAttempt?, _ error: Error?) -> Void

class ShootingTestManager {
    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    enum State {
        case uninitialized
        case calendarEvent(calendarEventId: Int64)
        case shootingTestEvent(calendarEventId: Int64, shootingTestEventId: Int64)
    }

    private(set) var state: State = .uninitialized


    func setSelectedEvent(calendarEventId: Int64, shootingTestEventId: Int64?) {
        if let shootingTestEventId = shootingTestEventId {
            state = .shootingTestEvent(calendarEventId: calendarEventId, shootingTestEventId: shootingTestEventId)
        } else {
            state = .calendarEvent(calendarEventId: calendarEventId)
        }
    }

    func setShootingTestEventId(shootingTestEventId: Int64?) {
        guard let calendarEventId = state.calendarEventId else {
            return
        }

        setSelectedEvent(
            calendarEventId: calendarEventId,
            shootingTestEventId: shootingTestEventId
        )
    }

    func clearShootingTestEventId() {
        if let calendarEventId = state.calendarEventId {
            state = .calendarEvent(calendarEventId: calendarEventId)
        } else {
            state = .uninitialized
        }
    }

    func getShootingTestCalendarEvent(_ completion: @escaping OnShootingTestEventFetched) {
        guard let calendarEventId = state.calendarEventId else {
            completion(nil, ShootingTestManagerError.missingCalendarId)
            return
        }

        RiistaSDK.shared.shootingTestContext.fetchShootingTestCalendarEvent(
            calendarEventId: calendarEventId
        ) { result, error in
            self.notifyDataCompletion(
                result: result,
                error: error
            ) { shootingTestEvent, error in
                if (shootingTestEvent == nil) {
                    self.logger.w { "Failed to fetch shooting test event (calendar event = \(calendarEventId)" }
                }
                completion(shootingTestEvent, error)
            }
        }
    }


    // MARK: Event state handling

    func startShootingTestEvent(
        occupationIds: [Int64],
        responsibleOfficialOccupationId: Int64?,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        guard let calendarEventId = state.calendarEventId else {
            completion(false, ShootingTestManagerError.missingCalendarId)
            return
        }

        // optional, not mandatory
        let shootingTestEventId = state.shootingTestEventId?.toKotlinLong()

        RiistaSDK.shared.shootingTestContext.openShootingTestEvent(
            calendarEventId: calendarEventId,
            shootingTestEventId: shootingTestEventId,
            occupationIds: occupationIds.map { $0.toKotlinLong() },
            responsibleOccupationId: responsibleOfficialOccupationId?.toKotlinLong()
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func closeShootingTestEvent(completion: @escaping OnCompletedWithStatusAndError) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(false, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.closeShootingTestEvent(
            shootingTestEventId: shootingTestEventId
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func reopenShootingTestEvent(completion: @escaping OnCompletedWithStatusAndError) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(false, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.reopenShootingTestEvent(
            shootingTestEventId: shootingTestEventId
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func updateShootingTestOfficials(
        selectedOfficials: [CommonShootingTestOfficial],
        responsibleOfficialOccupationId: Int64?,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        guard let calendarEventId = state.calendarEventId else {
            completion(false, ShootingTestManagerError.missingCalendarId)
            return
        }
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(false, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        let occupationIds = selectedOfficials.map { $0.occupationId.toKotlinLong() }

        RiistaSDK.shared.shootingTestContext.updateShootingTestOfficials(
            calendarEventId: calendarEventId,
            shootingTestEventId: shootingTestEventId,
            officialOccupationIds: occupationIds,
            responsibleOccupationId: responsibleOfficialOccupationId?.toKotlinLong()
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func listAvailableOfficialsForEvent(completion: @escaping OnShootingTestOfficialsFetched) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(nil, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.fetchAvailableShootingTestOfficialsForEvent(
            shootingTestEventId: shootingTestEventId
        ) { result, error in
            self.notifyDataCompletion(
                result: result,
                error: error
            ) { officials, error in
                if let officials = officials as? [CommonShootingTestOfficial] {
                    completion(officials, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func listAvailableOfficialsForRhy(rhyID: Int64, completion: @escaping OnShootingTestOfficialsFetched) {
        RiistaSDK.shared.shootingTestContext.fetchAvailableShootingTestOfficialsForRhy(
            rhyId: rhyID
        ) { result, error in
            self.notifyDataCompletion(
                result: result,
                error: error
            ) { officials, error in
                if let officials = officials as? [CommonShootingTestOfficial] {
                    completion(officials, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func listSelectedOfficialsForEvent(completion: @escaping OnShootingTestOfficialsFetched) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(nil, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.fetchSelectedShootingTestOfficialsForEvent(
            shootingTestEventId: shootingTestEventId
        ) { result, error in
            self.notifyDataCompletion(
                result: result,
                error: error
            ) { officials, error in
                if let officials = officials as? [CommonShootingTestOfficial] {
                    completion(officials, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }


    // MARK: Registration

    func searchWithHuntingNumberForEvent(hunterNumber: String, completion: @escaping OnShootingTestPersonFetched) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(nil, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.searchPersonByHunterNumber(
            shootingTestEventId: shootingTestEventId,
            hunterNumber: hunterNumber
        ) { result, error in
            self.notifyDataCompletion(
                result: result,
                error: error
            ) { person, error in
                if let person = person {
                    completion(person, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func searchWithSsnForEvent(ssn: String, completion: @escaping OnShootingTestPersonFetched) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(nil, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.searchPersonBySsn(
            shootingTestEventId: shootingTestEventId,
            ssn: ssn
        ) { result, error in
            self.notifyDataCompletion(
                result: result,
                error: error
            ) { person, error in
                if let person = person {
                    completion(person, nil)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func addParticipantToEvent(
        hunterNumber: String,
        bearTestIntended: Bool,
        mooseTestIntended: Bool,
        roeDeerTestIntended: Bool,
        bowTestIntended: Bool,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(false, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.addShootingTestParticipant(
            shootingTestEventId: shootingTestEventId,
            hunterNumber: hunterNumber,
            mooseTestIntended: mooseTestIntended,
            bearTestIntended: bearTestIntended,
            roeDeerTestIntended: roeDeerTestIntended,
            bowTestIntended: bowTestIntended
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    // MARK: Attempts

    func getParticipantDetailed(participantId: Int64, completion: @escaping OnShootingTestParticipantDetailedFetched) {
        RiistaSDK.shared.shootingTestContext.fetchShootingTestParticipantDetailed(
            participantId: participantId
        ) { result, error in
            self.notifyDataCompletion(result: result, error: error) { participant, error in
                if let participant = participant {
                    completion(participant, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func getAttempt(attemptId: Int64, completion: @escaping OnShootingTestAttemptFetched) {
        RiistaSDK.shared.shootingTestContext.fetchShootingTestAttempt(
            shootingTestAttemptId: attemptId
        ) { result, error in
            self.notifyDataCompletion(result: result, error: error) { attempt, error in
                if let attempt = attempt {
                    completion(attempt, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func addAttemptForParticipant(
        participantId: Int64,
        particiopantRev: Int32,
        shootingTestType: ShootingTestType,
        shootingTestResult: ShootingTestResult,
        hits: Int, // [0..4]
        note: String?,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        RiistaSDK.shared.shootingTestContext.addShootingTestAttempt(
            participantId: participantId,
            participantRev: particiopantRev,
            type: shootingTestType,
            result: shootingTestResult,
            hits: Int32(hits),
            note: note
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func updateAttempt(
        attemptId: Int64,
        attemptRev: Int32,
        participantId: Int64,
        participantRev: Int32,
        shootingTestType: ShootingTestType,
        shootingTestResult: ShootingTestResult,
        hits: Int,
        note: String?,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        RiistaSDK.shared.shootingTestContext.updateShootingTestAttempt(
            id: attemptId,
            rev: attemptRev,
            participantId: participantId,
            participantRev: participantRev,
            type: shootingTestType,
            result: shootingTestResult,
            hits: Int32(hits),
            note: note
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func deleteAttempt(attemptId: Int64, completion: @escaping OnCompletedWithStatusAndError) {
        RiistaSDK.shared.shootingTestContext.removeShootingTestAttempt(
            shootingTestAttemptId: attemptId
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    // MARK: Participants

    func listParticipantsForEvent(completion: @escaping OnShootingTestParticipantsFetched) {
        guard let shootingTestEventId = state.shootingTestEventId else {
            completion(nil, ShootingTestManagerError.missingShootingTestEventId)
            return
        }

        RiistaSDK.shared.shootingTestContext.fetchShootingTestParticipants(
            shootingTestEventId: shootingTestEventId
        ) { result, error in
            self.notifyDataCompletion(result: result, error: error) { participants, error in
                if let participants = participants as? [CommonShootingTestParticipant] {
                    completion(participants, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    // MARK: Payments

    func getParticipantSummary(participantId: Int64, completion: @escaping OnShootingTestParticipantFetched) {
        RiistaSDK.shared.shootingTestContext.fetchShootingTestParticipant(
            participantId: participantId
        ) { result, error in
            self.notifyDataCompletion(result: result, error: error) { participant, error in
                if let participant = participant {
                    completion(participant, error)
                } else {
                    completion(nil, error ?? ShootingTestManagerError.unspecifiedError)
                }
            }
        }
    }

    func completeAllPayments(
        participantId: Int64,
        participantRev: Int32,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        RiistaSDK.shared.shootingTestContext.completeAllPaymentsForParticipant(
            participantId: participantId,
            participantRev: participantRev
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }

    func updatePaymentStateForParticipant(
        participantId: Int64,
        participantRev: Int32,
        paidAttempts: Int,
        completed: Bool,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        RiistaSDK.shared.shootingTestContext.updatePaymentStateForParticipant(
            participantId: participantId,
            participantRev: participantRev,
            paidAttempts: Int32(paidAttempts),
            completed: completed
        ) { result, error in
            self.notifyCompletion(result: result, error: error, completion: completion)
        }
    }


    // MARK: Helpers

    /**
     * Notifies completion. Safe to be called from any result as the given completion is guaranteed to be called only from main thread.
     */
    private func notifyDataCompletion<DataType>(
        result: OperationResultWithData<DataType>?,
        error: Error?,
        _ completion: @escaping (_ data: DataType?, _ error: Error?) -> Void
    ) {
        Thread.onMainThread {
            if (error != nil) {
                completion(nil, error)
            }

            if let result = result {
                result.handle(
                    onSuccess: { dataType in
                        completion(dataType, nil)
                    },
                    onFailure: { statusCode in
                        completion(nil, ShootingTestManagerError.networkOperationFailed(statusCode: statusCode?.intValue))
                    }
                )
            } else {
                completion(nil, ShootingTestManagerError.unspecifiedError)
            }
        }
    }

    /**
     * Notifies completion. Safe to be called from any result as the given completion is guaranteed to be called only from main thread.
     */
    private func notifyCompletion(
        result: OperationResult?,
        error: Error?,
        completion: @escaping OnCompletedWithStatusAndError
    ) {
        Thread.onMainThread {
            if (error != nil) {
                completion(false, error)
            }

            if result is OperationResult.Success {
                completion(true, nil)
            } else if let failureResult = result as? OperationResult.Failure {
                let statusCode = failureResult.statusCode?.intValue
                completion(false, ShootingTestManagerError.networkOperationFailed(statusCode: statusCode))
            } else {
                completion(false, ShootingTestManagerError.unspecifiedError)
            }
        }
    }
}


extension ShootingTestManager.State {
    var calendarEventId: Int64? {
        switch self {
        case .uninitialized:                                return nil
        case .calendarEvent(let calendarEventId):           return calendarEventId
        case .shootingTestEvent(let calendarEventId, _):    return calendarEventId
        }
    }

    var shootingTestEventId: Int64? {
        switch self {
        case .uninitialized:                                    return nil
        case .calendarEvent(_):                                 return nil
        case .shootingTestEvent(_, let shootingTestEventId):    return shootingTestEventId
        }
    }
}
