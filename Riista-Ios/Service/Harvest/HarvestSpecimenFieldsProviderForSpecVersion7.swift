import Foundation


@objc class HarvestSpecimenFieldsProviderForSpecVersion7: NSObject {
    @objc class func getFieldsFor(harvestContext: HarvestContext) -> HarvestSpecimenFields {
        if (harvestContext.isMoose()) {
            return getFieldsForMoose(harvestContext)
        } else if (harvestContext.isDeer()) {
            return getFieldsForDeer(harvestContext)
        } else {
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
                fields.addFields([.antlersType, .antlersWidth, .antlerPointsLeft, .antlerPointsRight])
            }
            .addField(.additionalInfo)
    }

    private class func getFieldsForDeer(_ harvestContext: HarvestContext) -> HarvestSpecimenFields {
        return HarvestSpecimenFields()
            .addFields([.gender, .age])
            .addFields([.notEdible, .weightEstimated, .weightMeasured])
            .when({ harvestContext.isAdultMale() }) { fields in
                fields.addFields([.antlersWidth, .antlerPointsLeft, .antlerPointsRight])
            }
            .addField(.additionalInfo)
    }
}
