import Foundation

@objc class HarvestSanitizer: NSObject {

    /**
     * Sanitizes the given harvest data so that it should be possible to send harvest data to backend. Does not
     * save modified harvest to core data.
     */
    @objc class func sanitize(harvest: DiaryEntry?) {
        guard let harvest = harvest else {
            print("got <nil> harvest, nothing to do.")
            return
        }

        clearSpecimenFieldsIfNeeded(harvest)
    }

    /**
     * iOS version 2.4.1.1 had an issue where the harvest specimen antler fields (antlersGirth, antlersLength, antlersInnerWidth, antlersShaftWidth)
     * were initialized with value of 0 (instead of nil) in core data. This was luckily partly mitigated by the RiistaLogGameController which cleared these
     * fields for the _first_ specimen. For other specimens these were left with initial values and thus caused errors in backend logs.
     */
    private class func clearSpecimenFieldsIfNeeded(_ harvest: DiaryEntry) {
        guard let speciesCode = harvest.gameSpeciesCode?.intValue else {
            return
        }
        let harvestPointOfTime = harvest.pointOfTime

        for specimen in harvest.specimens {
            clearSpecimenFieldsIfNeeded(
                speciesCode: speciesCode,
                harvestPointOfTime: harvestPointOfTime,
                specimen: specimen as? RiistaSpecimen
            )
        }
    }

    private class func clearSpecimenFieldsIfNeeded(speciesCode: Int, harvestPointOfTime: Date?, specimen: RiistaSpecimen?) {
        guard let specimen = specimen else {
            print("Cannot clear specimen fields, no specimen")
            return
        }

        let harvestContext = HarvestContext.create(
            speciesId: speciesCode,
            harvestPointOfTime: harvestPointOfTime,
            specimen: specimen
        )

        let specimenFields = HarvestSpecimenFieldsProvider.getFieldsFor(harvestContext: harvestContext)

        specimenFields.clearIfNotPresent(.weight) { specimen.weight = nil }
        specimenFields.clearIfNotPresent(.weightEstimated) { specimen.weightEstimated = nil }
        specimenFields.clearIfNotPresent(.weightMeasured) { specimen.weightMeasured = nil }
        specimenFields.clearIfNotPresent(.fitnessClass) { specimen.fitnessClass = nil }
        specimenFields.clearIfNotPresent(.notEdible) { specimen.notEdible = nil }
        specimenFields.clearIfNotPresent(.additionalInfo) { specimen.additionalInfo = nil }

        specimenFields.clearIfNotPresent(.antlersType) { specimen.antlersType = nil }
        specimenFields.clearIfNotPresent(.antlersWidth) { specimen.antlersWidth = nil }
        specimenFields.clearIfNotPresent(.antlerPointsLeft) { specimen.antlerPointsLeft = nil }
        specimenFields.clearIfNotPresent(.antlerPointsRight) { specimen.antlerPointsRight = nil }

        specimenFields.clearIfNotPresent(.antlersLost) { specimen.antlersLost = nil }
        specimenFields.clearIfNotPresent(.antlersGirth) { specimen.antlersGirth = nil }
        specimenFields.clearIfNotPresent(.antlersLength) { specimen.antlersLength = nil }
        specimenFields.clearIfNotPresent(.antlersInnerWidth) { specimen.antlersInnerWidth = nil }
        specimenFields.clearIfNotPresent(.antlersShaftWidth) { specimen.antlersShaftWidth = nil }

        specimenFields.clearIfNotPresent(.loneCalf) { specimen.alone = nil }
    }
}

fileprivate extension HarvestSpecimenFields {
    func clearIfNotPresent(_ field: HarvestSpecimenFieldType, _ clearBlock: () -> Void) {
        if (!contains(field)) {
            clearBlock()
        }
    }
}
