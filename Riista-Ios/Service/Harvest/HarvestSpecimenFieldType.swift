import Foundation

@objc
enum HarvestSpecimenFieldType: Int {
    // common for most specimens
    case age
    case gender
    case weight

    // common for moose or mooselike specimen
    case weightEstimated
    case weightMeasured
    case fitnessClass
    case notEdible
    case additionalInfo

    // mooselike adult male
    case antlersInstructions
    case antlersType
    case antlersWidth
    case antlerPointsLeft
    case antlerPointsRight

    // 2020 new fields for mooselike species
    case antlersLost
    case antlersGirth
    case antlersLength
    case antlersInnerWidth
    case antlersShaftWidth

    // moose young
    case loneCalf
}


@objc
class HarvestSpecimenFieldTypeTagConverter: NSObject {
    private let tagBase: Int

    init(tagBase: Int) {
        self.tagBase = tagBase
    }

    func toTag(_ fieldType: HarvestSpecimenFieldType) -> Int {
        return fieldType.rawValue + tagBase
    }

    func fromTag(tagValue: Int) -> HarvestSpecimenFieldType? {
        return HarvestSpecimenFieldType(rawValue: tagValue - self.tagBase)
    }
}

