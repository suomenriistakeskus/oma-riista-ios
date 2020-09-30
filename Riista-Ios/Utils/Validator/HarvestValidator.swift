import Foundation

@objc class HarvestValidator: NSObject {
    @objc static func isValid(harvest: DiaryEntry) -> Bool {
        if (harvest.pointOfTime == nil || harvest.pointOfTime == Date.init()) {
            print("HarvestValidator: " + String(format: "Invalid time %@",
                                                harvest.pointOfTime != nil ? DatetimeUtil.dateToFormattedString(date: harvest.pointOfTime) : "nil"))
            return false
        }

        // Consider zero latitude or longtitude as uninialized location
        if (!harvest.hasNonDefaultLocation()) {
            print("HarvestValidator: " + String(format: "Invalid location"))
            return false
        }

        let species = RiistaGameDatabase.sharedInstance()?.species(byId: harvest.gameSpeciesCode.intValue)
        if (harvest.gameSpeciesCode == nil || species == nil) {
            print("HarvestValidator: " + String(format: "Invalid species code %@", harvest.gameSpeciesCode))
            return false
        }

        if (harvest.amount == nil || harvest.amount.intValue < 1 || harvest.amount.intValue > AppConstants.HarvestMaxAmount) {
            print("HarvestValidator: " + String(format: "Invalid amount %@", harvest.amount))
            return false
        } else if (!(species?.multipleSpecimenAllowedOnHarvests)! && harvest.amount != 1) {
            print("HarvestValidator: " + String(format: "Amount must be 1 for species [%@]. Was: %@", (species?.speciesId)!, harvest.amount))
            return false
        }

        if (harvest.specimens == nil) {
            print("HarvestValidator: " + String(format: "Invalid specimens: %@", harvest.specimens))
            return false
        } else if (!(species?.multipleSpecimenAllowedOnHarvests)! && harvest.specimens.count > 1) {
            print("HarvestValidator: " + String(format: "Invalid specimen count: %@", harvest.specimens.count))
            return false
        }

        if (SpeciesUtils.isMoose(speciesCode: harvest.gameSpeciesCode.intValue) || SpeciesUtils.isDeer(speciesCode: harvest.gameSpeciesCode.intValue)) {
            for item in harvest.specimens {
                let specimen = item as! RiistaSpecimen
                if (specimen.weight != nil) {
                    print("HarvestValidator: " + String(format: "Moose weight must be nil"))
                    return false
                }
            }
        }

        return validateSpeciesMandatoryFields(harvest: harvest, species: species!)
    }

    static func validateSpeciesMandatoryFields(harvest: DiaryEntry, species: RiistaSpecies) -> Bool {
        let huntingYear = DatetimeUtil.huntingYearContaining(date: harvest.pointOfTime)
        let insideSeason = HarvestSeasonUtil.isInsideHuntingSeason(day: harvest.pointOfTime,
                                                                   gameSpeciesCode: species.speciesId)
        var reportingType = RequiredHarvestFields.HarvestReportingType.BASIC

        if let permitNumber = harvest.permitNumber, !permitNumber.isEmpty {
            reportingType = RequiredHarvestFields.HarvestReportingType.PERMIT
        } else if (insideSeason) {
            reportingType = RequiredHarvestFields.HarvestReportingType.SEASON
        }

        let deerHuntingTypeEnabled = FeatureAvailabilityChecker.shared.isEnabled(.displayDeerHuntingType)

        let reportFields = RequiredHarvestFields.getFormFields(huntingYear: huntingYear,
                                                               gameSpeciesCode: species.speciesId,
                                                               reportingType: reportingType,
                                                               deerHuntingTypeEnabled: deerHuntingTypeEnabled)

        if (RequiredHarvestFields.HarvestReportingType.PERMIT != reportingType &&
            RequiredHarvestFields.HarvestReportingType.SEASON != reportingType &&
            RequiredHarvestFields.Required.YES == reportFields.getPermitNumber()) {
            print("HarvestValidator: " + String(format: "Permit number required. Species: %d time: %@",
                                                species.speciesId,
                                                DatetimeUtil.dateToFormattedString(date: harvest.pointOfTime)));
            return false;
        }

        let deerHuntingTypeRequired = reportFields.getDeerHuntingType()
        if (deerHuntingTypeRequired == RequiredHarvestFields.Required.YES && harvest.deerHuntingType == nil ||
            deerHuntingTypeRequired == RequiredHarvestFields.Required.NO && harvest.deerHuntingType != nil) {
            print("HarvestValidator: Invalid deer hunting type. Required \(deerHuntingTypeRequired.rawValue), " +
                  "value \(String(describing: harvest.deerHuntingType))")
            return false
        }

        if (deerHuntingTypeRequired == RequiredHarvestFields.Required.NO && harvest.deerHuntingTypeDescription != nil) {
            print("HarvestValidator: Invalid deer hunting type description. Required \(deerHuntingTypeRequired.rawValue), " +
                  "value: \(String(describing: harvest.deerHuntingTypeDescription))")
            return false
        }

        if ((RequiredHarvestFields.Required.YES == reportFields.getHuntingMethod() && (harvest.huntingMethod == nil || harvest.huntingMethod.isEmpty)) ||
            (RequiredHarvestFields.Required.NO == reportFields.getHuntingMethod() && nil != harvest.huntingMethod)) {
            print("HarvestValidator: " + String(format: "Invalid hunting method. Required: %d value: %@",
                                                reportFields.getHuntingMethod().rawValue,
                                                harvest.huntingMethod != nil ? harvest.huntingMethod : "nil"));
            return false
        }

        if ((RequiredHarvestFields.Required.YES == reportFields.getFeedingPlace() && nil == harvest.feedingPlace) ||
            (RequiredHarvestFields.Required.NO == reportFields.getFeedingPlace() && nil != harvest.feedingPlace)) {
            print("HarvestValidator: " + String(format: "Invalid feeding place. Required: %d value: %@",
                                                reportFields.getFeedingPlace().rawValue,
                                                harvest.feedingPlace != nil ? harvest.feedingPlace : "nil"));
            return false
        }

        if ((RequiredHarvestFields.Required.YES == reportFields.getTaigaBeanGoose() && nil == harvest.taigaBeanGoose) ||
            (RequiredHarvestFields.Required.NO == reportFields.getTaigaBeanGoose() && nil != harvest.taigaBeanGoose)) {
            print("HarvestValidator: " + String(format: "Invalid taiga bean goose. Required: %d value: %@",
                                                reportFields.getTaigaBeanGoose().rawValue,
                                                harvest.taigaBeanGoose != nil ? harvest.taigaBeanGoose : "nil"));
            return false
        }

        var huntingMethod: RequiredHarvestFields.HuntingMethod = RequiredHarvestFields.HuntingMethod.UNDEFINED
        if (harvest.huntingMethod != nil) {
            huntingMethod = RequiredHarvestFields.HuntingMethod.fromString(string: harvest.huntingMethod)!
        }

        let specimenFields = RequiredHarvestFields.getSpecimenFields(huntingYear: huntingYear,
                                                                     gameSpeciesCode: species.speciesId,
                                                                     huntingMethod: huntingMethod,
                                                                     reportingType: reportingType)

        if (!species.multipleSpecimenAllowedOnHarvests && harvest.specimens.count > 1) {
            print("HarvestValidator: " + String(format: "Invalid specimen count for %d: %d",
                                                species.speciesId,
                                                harvest.specimens.count));
            return false
        }

        for item in harvest.specimens {
            let specimen = item as! RiistaSpecimen
            if ((RequiredHarvestFields.Required.YES == specimenFields.getGender() && specimen.gender == nil) ||
                (RequiredHarvestFields.Required.NO == specimenFields.getGender() && nil != specimen.gender)) {
                print("HarvestValidator: " + String(format: "Invalid gender. Required: %d value: %@",
                                                    specimenFields.getGender().rawValue,
                                                    specimen.gender ?? "nil"));
                return false
            }


            if ((RequiredHarvestFields.Required.YES == specimenFields.getAge() && specimen.age == nil) ||
                (RequiredHarvestFields.Required.NO == specimenFields.getAge() && nil != specimen.age)) {
                print("HarvestValidator: " + String(format: "Invalid age. Required: %d value: %@",
                                                    specimenFields.getAge().rawValue,
                                                    specimen.age ?? "nil"));
                return false
            }

            if ((RequiredHarvestFields.Required.YES == specimenFields.getWeight() && nil == specimen.weight) ||
                (RequiredHarvestFields.Required.NO == specimenFields.getWeight() && nil != specimen.weight)) {
                print("HarvestValidator: " + String(format: "Invalid weight. Required: %d value: %@",
                                                    specimenFields.getWeight().rawValue,
                                                    specimen.weight != nil ? specimen.weight.stringValue : "nil"));
                return false
            }
        }

        return true
    }
}
