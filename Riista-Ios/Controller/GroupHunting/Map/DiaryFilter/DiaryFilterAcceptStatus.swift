import Foundation
import RiistaCommon

enum DiaryFilterAcceptStatus: CaseIterable {
    case all
    case proposed
    case accepted
    case rejected
}

extension DiaryFilter.AcceptStatus {
    func toAcceptStatus() -> DiaryFilterAcceptStatus {
        switch self {
        case .all:          return .all
        case .proposed:     return .proposed
        case .accepted:     return .accepted
        case .rejected:     return .rejected
        default:
            fatalError("Unknown event type observed (\(self)")
        }
    }
}

extension DiaryFilterAcceptStatus {
    func localizationKey() -> String {
        switch self {
        case .all:      return "GroupHuntingDiaryFilterAcceptTypeAll"
        case .proposed: return "GroupHuntingDiaryFilterAcceptTypeProposed"
        case .accepted: return "GroupHuntingDiaryFilterAcceptTypeAccepted"
        case .rejected: return "GroupHuntingDiaryFilterAcceptTypeRejected"
        }
    }

    func localized() -> String {
        return localizationKey().localized()
    }

    func toCommonAcceptStatus() -> DiaryFilter.AcceptStatus {
        switch self {
        case .all:      return .all
        case .proposed: return .proposed
        case .accepted: return .accepted
        case .rejected: return .rejected
        }
    }
}
