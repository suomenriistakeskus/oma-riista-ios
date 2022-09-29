import Foundation

@objc class RequiredHarvestFields: NSObject {

    @objc enum Required: Int {
        case YES
        case NO
        case VOLUNTARY
    }

    @objc enum HuntingMethod: Int {
        case UNDEFINED
        case SHOT
        case CAPTURED_ALIVE
        case SHOT_BUT_LOST

        static func fromString(string: String) -> HuntingMethod? {
            var i = 0
            while let item = HuntingMethod(rawValue: i) {
                if item.toString() == string { return item }
                i += 1
            }
            return HuntingMethod.UNDEFINED
        }

        func toString() -> String {
            switch self {
            case .SHOT: return "SHOT"
            case .CAPTURED_ALIVE: return "CAPTURED_ALIVE"
            case .SHOT_BUT_LOST: return "SHOT_BUT_LOST"
            default: return ""
            }
        }
    }

    @objc static func huntingMethodFromString(string: String) -> HuntingMethod {
        return HuntingMethod.fromString(string: string)!
    }

    @objc static func huntingMethodToString(value: HuntingMethod) -> String {
        if (value == HuntingMethod.UNDEFINED) {
            return ""
        }
        return value.toString()
    }

    @objc enum HarvestReportingType: Int {
        case BASIC
        case PERMIT
        case SEASON
        case HUNTING_DAY
    }

    @objc static func getFormFields(huntingYear: Int,
                                    gameSpeciesCode: Int,
                                    reportingType: HarvestReportingType,
                                    deerHuntingTypeEnabled: Bool) -> Report {
        return Report(gameSpeciesCode: gameSpeciesCode, huntingYear: huntingYear,
                      reportingType: reportingType, deerHuntingTypeEnabled: deerHuntingTypeEnabled);
    }

    @objc static func getSpecimenFields(huntingYear: Int, gameSpeciesCode: Int, huntingMethod: HuntingMethod, reportingType: HarvestReportingType) -> Specimen {
        return Specimen(huntingYear: huntingYear, gameSpeciesCode: gameSpeciesCode, huntingMethod: huntingMethod, reportingType: reportingType);
    }

    @objc class Report: NSObject {
        let PermitRequiredWithoutSeason: Set = [AppConstants.SpeciesCode.RoeDeer,

                                                AppConstants.SpeciesCode.Bear,
                                                AppConstants.SpeciesCode.Lynx,
                                                AppConstants.SpeciesCode.Wolf,
                                                AppConstants.SpeciesCode.Wolverine,

                                                AppConstants.SpeciesCode.GreySeal,
                                                AppConstants.SpeciesCode.EuropeanBeaver,
                                                AppConstants.SpeciesCode.Otter,
                                                AppConstants.SpeciesCode.Polecat,
                                                AppConstants.SpeciesCode.RingedSeal,
                                                AppConstants.SpeciesCode.WildBoar,

                                                AppConstants.SpeciesCode.BeanGoose,
                                                AppConstants.SpeciesCode.CommonEider,
                                                AppConstants.SpeciesCode.Coot,
                                                AppConstants.SpeciesCode.Garganey,
                                                AppConstants.SpeciesCode.Goosander,
                                                AppConstants.SpeciesCode.GreylagGoose,
                                                AppConstants.SpeciesCode.LongTailedDuck,
                                                AppConstants.SpeciesCode.Pintail,
                                                AppConstants.SpeciesCode.Pochard,
                                                AppConstants.SpeciesCode.RedBreastedMergander,
                                                AppConstants.SpeciesCode.Shoveler,
                                                AppConstants.SpeciesCode.TuftedDuck,
                                                AppConstants.SpeciesCode.Wigeon,
        ]

        let gameSpeciesCode: Int
        let huntingYear: Int
        let reportingType: HarvestReportingType
        let deerHuntingTypeEnabled: Bool

        init(gameSpeciesCode: Int, huntingYear: Int, reportingType: HarvestReportingType, deerHuntingTypeEnabled: Bool) {
            self.gameSpeciesCode = gameSpeciesCode
            self.huntingYear = huntingYear
            self.reportingType = reportingType
            self.deerHuntingTypeEnabled = deerHuntingTypeEnabled
        }

        @objc func getPermitNumber() -> Required {
            return ((reportingType == HarvestReportingType.PERMIT) || (reportingType != HarvestReportingType.SEASON && PermitRequiredWithoutSeason.contains(gameSpeciesCode))) ?
                Required.YES : Required.NO;
        }
        
        @objc func getDeerHuntingType() -> Required {
            if (!deerHuntingTypeEnabled) {
                return Required.NO
            }

            if (gameSpeciesCode == AppConstants.SpeciesCode.WhiteTailedDeer) {
                return reportingType == HarvestReportingType.PERMIT ? Required.NO : Required.VOLUNTARY;
            }

            return Required.NO;
        }

        func getHarvestArea() -> Required {
            if (gameSpeciesCode == AppConstants.SpeciesCode.Bear || gameSpeciesCode == AppConstants.SpeciesCode.GreySeal) {
                return reportingType == HarvestReportingType.SEASON ? Required.YES : Required.NO;
            }
            return Required.NO;
        }

        @objc func getHuntingMethod() -> Required {
            if (gameSpeciesCode == AppConstants.SpeciesCode.GreySeal) {
                return reportingType != HarvestReportingType.BASIC ? Required.YES : Required.NO;
            }
            return Required.NO;
        }

        @objc func getFeedingPlace() -> Required {
            if (gameSpeciesCode == AppConstants.SpeciesCode.WildBoar) {
                return reportingType != HarvestReportingType.BASIC ? Required.VOLUNTARY : Required.NO;
            }
            return Required.NO;
        }

        @objc func getTaigaBeanGoose() -> Required {
            if (gameSpeciesCode == AppConstants.SpeciesCode.BeanGoose) {
                return reportingType != HarvestReportingType.BASIC ? Required.VOLUNTARY : Required.NO;
            }
            return Required.NO;
        }

        func getLukeStatus() -> Required {
            if (gameSpeciesCode == AppConstants.SpeciesCode.Wolf) {
                return reportingType == HarvestReportingType.SEASON ? Required.VOLUNTARY : Required.NO;
            }
            return Required.NO;
        }
    }

    @objc class Specimen: NSObject {
        // {mufloni,saksanhirvi,japaninpeura,halli,susi,ahma,karhu,hirvi,kuusipeura,valkohäntäpeura,metsäpeura,villisika,saukko,ilves}
        let PermitMandatoryAge: Set = [47774, 47476, 47479, 47282, 46549, 47212, 47348, 47503, 47484, 47629, 200556, 47926, 47169, 46615]

        // {villisika,saukko,ilves,piisami,rämemajava,"tarhattu naali",pesukarhu,hilleri,kirjohylje,mufloni,saksanhirvi,japaninpeura,halli,susi,"villiintynyt kissa",metsäjänis,rusakko,orava,kanadanmajava,kettu,kärppä,näätä,minkki,villikani,supikoira,mäyrä,itämerennorppa,euroopanmajava,ahma,karhu,metsäkauris,hirvi,kuusipeura,valkohäntäpeura,metsäpeura}
        let PermitMandatoryGender: Set = [47926, 47169, 46615, 48537, 50336, 46542, 47329, 47240, 47305, 47774, 47476, 47479, 47282, 46549, 53004, 50106, 50386, 48089, 48250, 46587, 47230, 47223, 47243, 50114, 46564, 47180, 200555, 48251, 47212, 47348, 47507, 47503, 47484, 47629, 200556]

        // {halli,susi,saukko,ilves,ahma,karhu}
        let PermitMandatoryWeight: Set = [47282, 46549, 47169, 46615, 47212, 47348]

        // {karhu,metsäkauris,halli,villisika}
        let SeasonCommonMandatory: Set = [47348, 47507, 47282, 47926]

        let huntingYear: Int
        let gameSpeciesCode: Int
        let reportingType: HarvestReportingType
        let huntingMethod: HuntingMethod;
        let isMoose: Bool
        let isMooseOrDeerRequiringPermitForHunting: Bool
        let associatedToHuntingDay: Bool

        init(huntingYear: Int, gameSpeciesCode: Int, huntingMethod: HuntingMethod, reportingType: HarvestReportingType) {
            self.huntingYear = huntingYear;
            self.gameSpeciesCode = gameSpeciesCode;
            self.reportingType = reportingType;
            self.huntingMethod = huntingMethod;
            self.isMoose = gameSpeciesCode == AppConstants.SpeciesCode.Moose
            self.isMooseOrDeerRequiringPermitForHunting = SpeciesUtils.isMooseOrDeerRequiringPermitForHunting(speciesCode: gameSpeciesCode)
            self.associatedToHuntingDay = reportingType == HarvestReportingType.HUNTING_DAY;
        }

        @objc func getAge() -> Required {
            if (isMooseOrDeerRequiringPermitForHunting && (associatedToHuntingDay || reportingType == .BASIC)) {
                return Required.YES;
            }
            return getRequirement(permitMandatorySpecies: PermitMandatoryAge, gameSpeciesCode: gameSpeciesCode);
        }

        @objc func getGender() -> Required {
            if (isMooseOrDeerRequiringPermitForHunting && (associatedToHuntingDay || reportingType == .BASIC)) {
                return Required.YES;
            }
            return getRequirement(permitMandatorySpecies: PermitMandatoryGender, gameSpeciesCode: gameSpeciesCode);
        }

        @objc func getWeight() -> Required {
            if (gameSpeciesCode == AppConstants.SpeciesCode.RoeDeer && reportingType == HarvestReportingType.SEASON) {
                return Required.VOLUNTARY;
            }

            if (gameSpeciesCode == AppConstants.SpeciesCode.WildBoar && reportingType == HarvestReportingType.SEASON) {
                return Required.VOLUNTARY;
            }

            if (isMooseOrDeerRequiringPermitForHunting) {
                return huntingYear < 2016 ? Required.VOLUNTARY : Required.NO;
            }

            if (gameSpeciesCode == AppConstants.SpeciesCode.GreySeal &&
                huntingMethod == HuntingMethod.SHOT_BUT_LOST) {
                return huntingYear < 2015 ? Required.VOLUNTARY : Required.NO;
            }

            return getRequirement(permitMandatorySpecies: PermitMandatoryWeight, gameSpeciesCode: gameSpeciesCode);
        }

        @objc func getRequirement(permitMandatorySpecies: Set<Int>, gameSpeciesCode: Int) -> Required {
            return reportingType == HarvestReportingType.PERMIT && permitMandatorySpecies.contains(gameSpeciesCode) ||
                reportingType == HarvestReportingType.SEASON && SeasonCommonMandatory.contains(gameSpeciesCode) ||
                reportingType == HarvestReportingType.HUNTING_DAY
                ? Required.YES : Required.VOLUNTARY;
        }

        @objc func getWeightEstimated() -> Required {
            return isMooseOrDeerRequiringPermitForHunting ? Required.VOLUNTARY : Required.NO;
        }

        @objc func getWeightMeasured() -> Required {
            return isMooseOrDeerRequiringPermitForHunting ? Required.VOLUNTARY : Required.NO;
        }

        @objc func getAdditionalInfo() -> Required {
            return isMooseOrDeerRequiringPermitForHunting ? Required.VOLUNTARY : Required.NO;
        }

        @objc func getNotEdible() -> Required {
            if (isMooseOrDeerRequiringPermitForHunting) {
                return isMoose && associatedToHuntingDay && huntingYear >= 2016 ? Required.YES : Required.VOLUNTARY;
            }

            return Required.NO;
        }

        @objc func getFitnessClass() -> Required {
            if (isMoose) {
                return associatedToHuntingDay && huntingYear >= 2016 ? Required.YES : Required.VOLUNTARY;
            }

            return Required.NO;
        }

        @objc func getAntlersWidth(age: String, gender: String) -> Required {
            return commonMooselikeAdultMale(age: age, gender: gender);
        }

        // For UI only
        @objc func getAntlersWidth() -> Required {
            return isMooseOrDeerRequiringPermitForHunting ? Required.VOLUNTARY : Required.NO;
        }

        // For UI only
        @objc func getAntlerPoints() -> Required {
            return isMooseOrDeerRequiringPermitForHunting ? Required.VOLUNTARY : Required.NO;
        }

        @objc func getAntlerPoints(age: String, gender: String) -> Required {
            return commonMooselikeAdultMale(age: age, gender: gender);
        }

        @objc func commonMooselikeAdultMale(age: String, gender: String) -> Required {
            if (isMooseOrDeerRequiringPermitForHunting && age == SpecimenAgeAdult && gender == SpecimenGenderMale) {
                return associatedToHuntingDay && isMoose && huntingYear >= 2016 ? Required.YES : Required.VOLUNTARY;
            }
            return Required.NO;
        }

        // For UI only
        @objc func getAntlersType() -> Required {
            return isMoose ? Required.VOLUNTARY : Required.NO;
        }

        @objc func getAntlersType(age: String, gender: String) -> Required {
            if (isMoose && age == SpecimenAgeAdult && gender == SpecimenGenderMale) {
                return associatedToHuntingDay ? Required.YES : Required.VOLUNTARY;
            }
            return Required.NO;
        }

        // For UI only
        @objc func getAlone() -> Required {
            return isMoose ? Required.VOLUNTARY : Required.NO;
        }

        @objc func getAlone(age: String) -> Required {
            if (isMoose && age == SpecimenAgeYoung) {
                return associatedToHuntingDay ? Required.YES : Required.VOLUNTARY;
            }
            return Required.NO;
        }
    }
}
