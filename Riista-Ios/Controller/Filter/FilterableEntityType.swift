import Foundation

enum FilterableEntityType {
    case harvest, observation, srva, pointOfInterest

    func toRiistaEntryType() -> RiistaEntryType? {
        switch self {
        case .harvest:          return RiistaEntryTypeHarvest
        case .observation:      return RiistaEntryTypeObservation
        case .srva:             return RiistaEntryTypeSrva
        case .pointOfInterest:  return nil
        }
    }
}
