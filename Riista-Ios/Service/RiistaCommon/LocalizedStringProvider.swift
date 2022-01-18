import Foundation
import RiistaCommon

class LocalizedStringProvider: RiistaCommon.StringProvider {

    func getString(stringId: RR.string) -> String {
        if let localizationKey = getLocalizationKey(stringId: stringId) {
            return RiistaBridgingUtils.RiistaLocalizedString(forkey: localizationKey)
        } else {
            return "<\(stringId)>"
        }
    }

    func getFormattedString(stringFormatId: RR.stringFormat, arg: String) -> String {
        if let localizationKey = getStringFormatLocalizationKey(stringFormatId: stringFormatId) {
            return String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: localizationKey), arg)
        }

        return "<\(stringFormatId.name)>"
    }

    func getFormattedString(stringFormatId: RR.stringFormat, arg1: String, arg2: String) -> String {
        if let localizationKey = getStringFormatLocalizationKey(stringFormatId: stringFormatId) {
            return String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: localizationKey), arg1, arg2)
        }

        return "<\(stringFormatId.name)>"
    }

    func getQuantityString(pluralsId: RR.plurals, quantity: Int32, arg: Int32) -> String {
        if let localizationKey = getPluralsStringLocalizationKey(pluralsId: pluralsId) {
            return String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: localizationKey), arg)
        }
        return "<\(pluralsId.name): \(arg)>"
    }

    func getLocalizationKey(stringId: RR.string) -> String? {
        switch stringId {
        case .genericNo:
            return "No"
        case .genericYes:
            return "Yes"
        case .groupHuntingLabelClub:
            return "GroupHuntingLabelClub"
        case .groupHuntingLabelSeason:
            return "GroupHuntingLabelSeason"
        case .groupHuntingLabelSpecies:
            return "GroupHuntingLabelSpecies"
        case .groupHuntingLabelHuntingGroup:
            return "GroupHuntingLabelHuntingGroup"
        case .groupHuntingErrorHuntingHasFinished:
            return "GroupHuntingErrorHuntingHasFinished"

        case .groupHuntingHarvestFieldActor:
            return "GroupHuntingHarvestFieldActor"
        case .groupHuntingHarvestFieldAuthor:
            return "GroupHuntingHarvestFieldAuthor"
        case .groupHuntingHarvestFieldDeerHuntingType:
            return "DeerHuntingType"
        case .groupHuntingHarvestFieldDeerHuntingOtherTypeDescription:
            return "DeerHuntingTypeDescription"
        case .groupHuntingHarvestFieldNotEdible:
            return "MooseNotEdible"
        case .groupHuntingHarvestFieldWeightEstimated:
            return "MooseWeightEstimated"
        case .groupHuntingHarvestFieldWeightMeasured:
            return "MooseWeightWeighted"
        case .groupHuntingHarvestFieldFitnessClass:
            return "MooseFitnessClass"
        case .groupHuntingHarvestFieldAntlersType:
            return "MooseAntlersType"
        case .groupHuntingHarvestFieldAntlersWidth:
            return "MooseAntlersWidth"
        case .groupHuntingHarvestFieldAntlerPointsLeft:
            return "MooseAntlersPointsLeft"
        case .groupHuntingHarvestFieldAntlerPointsRight:
            return "MooseAntlersPointsRight"
        case .groupHuntingHarvestFieldAntlersLost:
            return "AntlersLost"
        case .groupHuntingHarvestFieldAntlersGirth:
            return "AntlersGirth"
        case .groupHuntingHarvestFieldAntlerShaftWidth:
            return "AntlerShaftDiameter"
        case .groupHuntingHarvestFieldAntlersLength:
            return "AntlersLength"
        case .groupHuntingHarvestFieldAntlersInnerWidth:
            return "AntlersInnerWidth"
        case .groupHuntingHarvestFieldAlone:
            return "HarvestFieldLoneCalf"
        case .groupHuntingHarvestFieldAdditionalInformation:
            return "MooseAdditionalInfo"

        case .groupHuntingHunterId:
            return "GroupHuntingHunterId"
        case .groupHuntingEnterHunterId:
            return "GroupHuntingEnterHunterId"
        case .groupHuntingInvalidHunterId:
            return "GroupHuntingInvalidHunterId"
        case .groupHuntingSearchingHunterById:
            return "GroupHuntingSearchingHunterById"
        case .groupHuntingSearchingObserverById:
            return "GroupHuntingSearchingObserverById"
        case .groupHuntingHunterSearchFailed:
            return "GroupHuntingHunterSearchFailed"
        case .groupHuntingObserverSearchFailed:
            return "GroupHuntingObserverSearchFailed"
        case .groupHuntingOtherHunter:
            return "GroupHuntingOtherHunter"
        case .groupHuntingOtherObserver:
            return "GroupHuntingOtherObserver"
        case .groupHuntingProposedGroupHarvestSpecimen:
            return "GroupHuntingSpecimenDetails"
        case .groupHuntingHarvestFieldAdditionalInformationInstructions:
            return "HarvestAdditionalInformationInstructions"
        case .groupHuntingHarvestFieldAdditionalInformationInstructionsWhiteTailedDeer:
            return "HarvestAdditionalInformationInstructionsWhiteTailedDeer"
        case .groupHuntingHarvestFieldHuntingDayAndTime:
            return "GroupHuntingHuntingDayAndTime"
        case .groupHuntingProposedGroupHarvestShooter:
            return "GroupHuntingHarvestShooterInformation"
        case .groupHuntingProposedGroupHarvestActor:
            return "GroupHuntingHarvestFieldActorOrMember"

        case .groupHuntingDayErrorDatesNotWithinPermit:
            return "GroupHuntingDayErrorDatesNotWithinPermit"
        case .groupHuntingErrorTimeNotWithinHuntingDay:
            return "GroupHuntingErrorTimeNotWithinHuntingDay"
        case .errorDateNotAllowed:
            return "ErrorDateNotAllowed"
        case .groupHuntingDayLabelStartDateAndTime:
            return "FilterStartDate"
        case .groupHuntingDayLabelEndDateAndTime:
            return "FilterEndDate"
        case .groupHuntingDayLabelNumberOfHunters:
            return "GroupHuntingDayLabelNumberOfHunters"
        case .groupHuntingDayLabelHuntingMethod:
            return "GroupHuntingDayLabelHuntingMethod"
        case .groupHuntingDayLabelNumberOfHounds:
            return "GroupHuntingDayLabelNumberOfHounds"
        case .groupHuntingDayLabelSnowDepthCentimeters:
            return "GroupHuntingDayLabelSnowDepthCentimeters"
        case .groupHuntingDayLabelBreakDurationMinutes:
            return "GroupHuntingDayLabelBreakDurationMinutes"
        case .groupHuntingDayNoBreaks:
            return "GroupHuntingDayNoBreaks"

        // Observation fields
        case .groupHuntingObservationFieldHuntingDayAndTime:
            return "GroupHuntingObservationFieldHuntingDayAndTime"
        case .groupHuntingObservationFieldActor:
            return "GroupHuntingObservationFieldActor"
        case .groupHuntingObservationFieldAuthor:
            return "GroupHuntingObservationFieldAuthor"
        case .groupHuntingObservationFieldHeadlineSpecimenDetails:
            return "SpecimenDetailsTitle"
        case .groupHuntingObservationFieldMooselikeCalfAmount:
            return "ObservationDetailsMooseCalf"
        case .groupHuntingObservationFieldMooselikeCalfAmountWithinDeerHunting:
            return "ObservationDetailsMooseCalfWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeFemale1calfAmount:
            return "ObservationDetailsMooseFemale1Calf"
        case .groupHuntingObservationFieldMooselikeFemale1calfAmountWithinDeerHunting:
            return "ObservationDetailsMooseFemale1CalfWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeFemale2calfAmount:
            return "ObservationDetailsMooseFemale2Calf"
        case .groupHuntingObservationFieldMooselikeFemale2calfAmountWithinDeerHunting:
            return "ObservationDetailsMooseFemale2CalfWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeFemale3calfAmount:
            return "ObservationDetailsMooseFemale3Calf"
        case .groupHuntingObservationFieldMooselikeFemale3calfAmountWithinDeerHunting:
            return "ObservationDetailsMooseFemale3CalfWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeFemale4calfAmount:
            return "ObservationDetailsMooseFemale4Calf"
        case .groupHuntingObservationFieldMooselikeFemale4calfAmountWithinDeerHunting:
            return "ObservationDetailsMooseFemale4CalfWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeFemaleAmount:
            return "ObservationDetailsMooseFemale"
        case .groupHuntingObservationFieldMooselikeFemaleAmountWithinDeerHunting:
            return "ObservationDetailsMooseFemaleWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeMaleAmount:
            return "ObservationDetailsMooseMale"
        case .groupHuntingObservationFieldMooselikeMaleAmountWithinDeerHunting:
            return "ObservationDetailsMooseMaleWithinDeerHunting"
        case .groupHuntingObservationFieldMooselikeUnknownSpecimenAmount:
            return "ObservationDetailsMooseUnknown"
        case .groupHuntingObservationFieldMooselikeUnknownSpecimenAmountWithinDeerHunting:
            return "ObservationDetailsMooseUnknownWithinDeerHunting"
        case .groupHuntingObservationFieldObservationType:
            return "ObservationDetailsType"

        // Observation types
        case .observationTypeNako:
            return "ObservationTypeNako"
        case .observationTypeJalki:
            return "ObservationTypeJalki"
        case .observationTypeUloste:
            return "ObservationTypeUloste"
        case .observationTypeAani:
            return "ObservationTypeAani"
        case .observationTypeRiistakamera:
            return "ObservationTypeRiistakamera"
        case .observationTypeKoiranRiistatyo:
            return "ObservationTypeKoiranRiistatyo"
        case .observationTypeMaastolaskenta:
            return "ObservationTypeMaastolaskenta"
        case .observationTypeKolmiolaskenta:
            return "ObservationTypeKolmiolaskenta"
        case .observationTypeLentolaskenta:
            return "ObservationTypeLentolaskenta"
        case .observationTypeHaaska:
            return "ObservationTypeHaaska"
        case .observationTypeSyonnos:
            return "ObservationTypeSyonnos"
        case .observationTypeKelomispuu:
            return "ObservationTypeKelomispuu"
        case .observationTypeKiimakuoppa:
            return "ObservationTypeKiimakuoppa"
        case .observationTypeMakuupaikka:
            return "ObservationTypeMakuupaikka"
        case .observationTypePato:
            return "ObservationTypePato"
        case .observationTypePesa:
            return "ObservationTypePesa"
        case .observationTypePesaKeko:
            return "ObservationTypePesaKeko"
        case .observationTypePesaPenkka:
            return "ObservationTypePesaPenkka"
        case .observationTypePesaSeka:
            return "ObservationTypePesaSeka"
        case .observationTypeSoidin:
            return "ObservationTypeSoidin"
        case .observationTypeLuolasto:
            return "ObservationTypeLuolasto"
        case .observationTypePesimaluoto:
            return "ObservationTypePesimaluoto"
        case .observationTypeLepailyluoto:
            return "ObservationTypeLepailyluoto"
        case .observationTypePesimasuo:
            return "ObservationTypePesimasuo"
        case .observationTypeMuutonAikainenLepailyalue:
            return "ObservationTypeMuutonAikainenLepailyalue"
        case .observationTypeRiistankulkupaikka:
            return "ObservationTypeRiistankulkupaikka"
        case .observationTypePoikueymparisto:
            return "ObservationTypePoikueymparisto"
        case .observationTypeVaihtelevarakenteinenMustikkametsa:
            return "ObservationTypeVaihtelevarakenteinenMustikkametsa"
        case .observationTypeKuusisekoitteinenMetsa:
            return "ObservationTypeKuusisekoitteinenMetsa"
        case .observationTypeVaihtelevarakenteinenMantysekoitteinenMetsa:
            return "ObservationTypeVaihtelevarakenteinenMantysekoitteinenMetsa"
        case .observationTypeVaihtelevarakenteinenLehtipuusekoitteinenMetsa:
            return "ObservationTypeVaihtelevarakenteinenLehtipuusekoitteinenMetsa"
        case .observationTypeSuonReunametsa:
            return "ObservationTypeSuonReunametsa"
        case .observationTypeHakomamanty:
            return "ObservationTypeHakomamanty"
        case .observationTypeRuokailukoivikko:
            return "ObservationTypeRuokailukoivikko"
        case .observationTypeLeppakuusimetsaTaiKoivikuusimetsa:
            return "ObservationTypeLeppakuusimetsaTaiKoivikuusimetsa"
        case .observationTypeRuokailupajukkoTaiKoivikko:
            return "ObservationTypeRuokailupajukkoTaiKoivikko"
        case .observationTypeMuu:
            return "ObservationTypeMuu"

        // Fitness classes
        case .harvestFitnessClassErinomainen:
            return "FitnessClassExcellent"
        case .harvestFitnessClassNormaali:
            return "FitnessClassNormal"
        case .harvestFitnessClassLaiha:
            return "FitnessClassThin"
        case .harvestFitnessClassNaantynyt:
            return "FitnessClassStarved"

        // Antler types
        case .harvestAntlerTypeHanko:
            return "AntlersTypeHanko"
        case .harvestAntlerTypeLapio:
            return "AntlersTypeLapio"
        case .harvestAntlerTypeSeka:
            return "AntlersTypeSeka"

        // Deer hunting types
        case .deerHuntingTypeStandHunting:
            return "DeerHuntingTypeStanding"
        case .deerHuntingTypeDogHunting:
            return "DeerHuntingTypeDog"
        case .deerHuntingTypeOther:
            return "DeerHuntingTypeOther"

        case .groupHuntingMessageNoHuntingDays:
            return "GroupHuntingNoHuntingDays"
        case .groupHuntingMessageNoHuntingDaysButCanCreate:
            return "GroupHuntingNoHuntingDaysButCanCreate"
        case .groupHuntingMessageNoHuntingDaysDeer:
            return "GroupHuntingNoHuntingDaysDeer"

        case .groupHuntingMethodPassilinjaKoiraOhjaajineenMetsassa:
            return "GroupHuntingMethodPassilinjaKoiraOhjaajineenMetsassa"
        case .groupHuntingMethodHiipiminenPysayttavalleKoiralle:
            return "GroupHuntingMethodHiipiminenPysayttavalleKoiralle"
        case .groupHuntingMethodPassilinjaJaTiivisAjoketju:
            return "GroupHuntingMethodPassilinjaJaTiivisAjoketju"
        case .groupHuntingMethodPassilinjaJaMiesajoJaljityksena:
            return "GroupHuntingMethodPassilinjaJaMiesajoJaljityksena"
        case .groupHuntingMethodJaljitysEliNaakiminenIlmanPasseja:
            return "GroupHuntingMethodJaljitysEliNaakiminenIlmanPasseja"
        case .groupHuntingMethodVaijyntaKulkupaikoilla:
            return "GroupHuntingMethodVaijyntaKulkupaikoilla"
        case .groupHuntingMethodVaijyntaRavintokohteilla:
            return "GroupHuntingMethodVaijyntaRavintokohteilla"
        case .groupHuntingMethodHoukuttelu:
            return "GroupHuntingMethodHoukuttelu"
        case .groupHuntingMethodMuu:
            return "GroupHuntingMethodMuu"

        default:
            print("MISSING LOCALIZATION for \(stringId)")
            return nil
        }
    }

    func getStringFormatLocalizationKey(stringFormatId: RR.stringFormat) -> String? {
        switch stringFormatId {
        case .groupHuntingLabelPermitFormatted:
            return "GroupHuntingLabelPermitFormatted"
        case .genericHoursAndMinutesFormat:
            return "HoursAndMinutesFormat"
        default:
            print("MISSING LOCALIZATION for stringFormat \(stringFormatId)")
            return nil
        }
    }

    func getPluralsStringLocalizationKey(pluralsId: RR.plurals) -> String? {
        switch pluralsId {
        case .hours:
            return "PluralsHours"
        case .minutes:
            return "PluralsMinutes"
        default:
            print("MISSING LOCALIZATION for plural \(pluralsId)")
            return nil
        }
    }
}
