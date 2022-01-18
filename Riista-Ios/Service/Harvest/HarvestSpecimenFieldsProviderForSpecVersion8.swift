import Foundation


@objc class HarvestSpecimenFieldsProviderForSpecVersion8: NSObject {
    @objc class func getFieldsFor(harvestContext: HarvestContext) -> HarvestSpecimenFields {
        switch harvestContext.speciesId {
        case AppConstants.SpeciesCode.Moose:
            return getFieldsForMoose(harvestContext)

        case AppConstants.SpeciesCode.FallowDeer:
            return getFieldsForFallowDeer(harvestContext)

        case AppConstants.SpeciesCode.WhiteTailedDeer:
            return getFieldsForWhiteTailedDeer(harvestContext)

        case AppConstants.SpeciesCode.RoeDeer:
            return getFieldsForRoeDeer(harvestContext)

        case AppConstants.SpeciesCode.WildForestDeer:
            return getFieldsForWildForestDeer(harvestContext)

        case AppConstants.SpeciesCode.WildBoar:
                return getFieldsForWildBoar(harvestContext)

        default:
            return HarvestSpecimenFields()
                .addFields([.gender, .age, .weight])
        }
    }

    private class func getFieldsForMoose(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age])
            .when({ harvestContext.isYoung() }) { fields in
                fields.addField(.loneCalf)
            }
            .addFields([.notEdible, .weightEstimated, .weightMeasured, .fitnessClass])
            .when({ harvestContext.isAdultMale() }) { fields in
                fields.addField(.antlersLost)
                    .when({ harvestContext.antlersPresent }) {
                        $0.addFields([.antlersInstructions, .antlersType, .antlersWidth, .antlerPointsLeft,
                                      .antlerPointsRight, .antlersGirth])
                    }
            }
            .addField(.additionalInfo)
    }

    private class func getFieldsForFallowDeer(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age, .notEdible, .weightEstimated, .weightMeasured])
            .when({ harvestContext.isAdultMale() }) { fields in
                fields.addField(.antlersLost)
                    .when({ harvestContext.antlersPresent }) {
                        $0.addFields([.antlerPointsLeft, .antlerPointsRight, .antlersWidth])
                    }
            }
            .addField(.additionalInfo)
    }

    private class func getFieldsForWhiteTailedDeer(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age, .notEdible, .weightEstimated, .weightMeasured])
            .when({ harvestContext.isAdultMale() }) { fields in
                fields.addField(.antlersLost)
                    .when({ harvestContext.antlersPresent }) {
                        $0.addFields([.antlersInstructions, .antlerPointsLeft, .antlerPointsRight, .antlersGirth,
                                      .antlersLength, .antlersInnerWidth])
                    }
            }
            .addField(.additionalInfo)
    }

    private class func getFieldsForRoeDeer(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age, .weightEstimated, .weightMeasured])
            .when({ harvestContext.isAdultMale() }) { fields in
                fields.addField(.antlersLost)
                    .when({ harvestContext.antlersPresent }) {
                        $0.addFields([.antlersInstructions, .antlerPointsLeft, .antlerPointsRight, .antlersLength, .antlersShaftWidth])
                    }
            }
    }

    private class func getFieldsForWildForestDeer(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age, .notEdible, .weightEstimated, .weightMeasured])
            .when({ harvestContext.isAdultMale() }) { fields in
                fields.addField(.antlersLost)
                    .when({ harvestContext.antlersPresent }) {
                        $0.addFields([.antlerPointsLeft, .antlerPointsRight, .antlersWidth])
                    }
            }
            .addField(.additionalInfo)
    }

    private class func getFieldsForWildBoar(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age, .weightEstimated, .weightMeasured])
    }
}
