import Foundation
import RiistaCommon

enum DiaryFilterEventType: CaseIterable {
    case harvestsAndObservations
    case harvests
    case observations
}

extension DiaryFilter.EventType {
    func toEventType() -> DiaryFilterEventType {
        switch self {
        case .all:          return .harvestsAndObservations
        case .harvests:     return .harvests
        case .observations: return .observations
        default:
            fatalError("Unknown event type observed (\(self)")
        }
    }
}

extension DiaryFilterEventType {
    func localizationKey() -> String {
        switch self {
        case .harvestsAndObservations:  return "GroupHuntingDiaryFilterEventTypeHarvestsAndObservations"
        case .harvests:                 return "GroupHuntingDiaryFilterEventTypeHarvests"
        case .observations:             return "GroupHuntingDiaryFilterEventTypeObservations"
        }
    }

    func localized() -> String {
        return localizationKey().localized()
    }

    func toCommonEventType() -> DiaryFilter.EventType {
        switch self {
        case .harvestsAndObservations:  return .all
        case .harvests:                 return .harvests
        case .observations:             return .observations
        }
    }
}
