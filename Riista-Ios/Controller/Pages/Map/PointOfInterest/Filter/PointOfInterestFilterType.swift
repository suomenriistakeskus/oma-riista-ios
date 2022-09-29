import Foundation
import RiistaCommon

enum PointOfInterestFilterType: CaseIterable {
    case all, sightingPlace, mineralLick, feedingPlace, other
}

extension PoiFilter.PoiFilterType {
    func toFilterType() -> PointOfInterestFilterType {
        switch self {
        case .all:              return .all
        case .sightingPlace:    return .sightingPlace
        case .mineralLick:      return .mineralLick
        case .feedingPlace:     return .feedingPlace
        case .other:            return .other
        default:
            fatalError("Unknown filter type observed (\(self)")
        }
    }
}

extension PointOfInterestFilterType {
    func localizationKey() -> String {
        switch self {
        case .all:              return "PointOfInterestFilterTypeAll"
        case .sightingPlace:    return "PointOfInterestFilterTypeSightingPlace"
        case .mineralLick:      return "PointOfInterestFilterTypeMineralLick"
        case .feedingPlace:     return "PointOfInterestFilterTypeFeedingPlace"
        case .other:            return "PointOfInterestFilterTypeOther"
        }
    }

    func localized() -> String {
        return localizationKey().localized()
    }

    func toCommonFilterType() -> PoiFilter.PoiFilterType {
        switch self {
        case .all:              return .all
        case .sightingPlace:    return .sightingPlace
        case .mineralLick:      return .mineralLick
        case .feedingPlace:     return .feedingPlace
        case .other:            return .other
        }
    }
}
