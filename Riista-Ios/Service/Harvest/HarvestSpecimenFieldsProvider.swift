import Foundation


@objc class HarvestSpecimenFieldsProvider: NSObject {
    @objc class func getFieldsFor(harvestContext: HarvestContext) -> HarvestSpecimenFields {
        if (showFieldsAccordingToHarvestSpecVersion8(harvestPointOfTime: harvestContext.harvestPointOfTime)) {
            return HarvestSpecimenFieldsProviderForSpecVersion8.getFieldsFor(harvestContext: harvestContext)
        } else {
            return HarvestSpecimenFieldsProviderForSpecVersion7.getFieldsFor(harvestContext: harvestContext)
        }
    }

    @objc private class func showFieldsAccordingToHarvestSpecVersion8(harvestPointOfTime: Date?) -> Bool {
        guard let harvestPointOfTime = harvestPointOfTime else {
            // hunting year is required for determining whether fields are visible or not
            // --> fallbacking to false is safer
            return false
        }

        let huntingYear = DatetimeUtil.huntingYearContaining(date: harvestPointOfTime)
        return FeatureAvailabilityChecker.shared.isEnabled(.antlers2020Fields) && huntingYear >= 2020
    }
}

extension HarvestSpecimenFields: WithConditionals { }
