import Foundation

@objcMembers class HarvestSeasonUtil: NSObject {

    static func isInsideHuntingSeason(day: Date, gameSpeciesCode: Int) -> Bool {
        let huntingYear = RiistaUtils.startYear(from: day)

        return gameSpeciesCode == AppConstants.SpeciesCode.GreySeal && isHalliSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Bear && isBearSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.RoeDeer && isRoeDeerSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.BeanGoose && isMetsahanhiSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Polecat && huntingYear >= 2017 ||
            gameSpeciesCode == AppConstants.SpeciesCode.WildBoar && huntingYear >= 2017 ||

            gameSpeciesCode == AppConstants.SpeciesCode.CommonEider && isCommonEiderSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Coot && isCootSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Garganey && isGarganeySeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Goosander && isGoosanderSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.LongTailedDuck && isLongTailedDuckSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Pintail && isPintailSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Pochard && isPochardSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.RedBreastedMergander && isRedBreastedMerganserSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Shoveler && isSholeverSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.TuftedDuck && isTuftedDuckSeason(day: day, huntingYear: huntingYear) ||
            gameSpeciesCode == AppConstants.SpeciesCode.Wigeon && isWigeonSeason(day: day, huntingYear: huntingYear)
    }

    // 1.8 - 31.12 and 16.4 - 31.7
    private static func isHalliSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2017)  {
            return false
        }

        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 1),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31)) ||
            RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear + 1, m: 4, d: 16),
                                                      andDate: ld(y: huntingYear + 1, m: 7, d: 31))
    }

    // 20.8 - 31.10
    private static func isBearSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2017)  {
            return false
        }

        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 10, d: 31))
    }

    // 1.9 - 31.1 and 1.2 - 15.2 and 16.5 - 15.6
    private static func isRoeDeerSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2017)  {
            return false
        }

        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 9, d: 1),
                                                         andDate: ld(y: huntingYear + 1, m: 2, d: 15)) ||
            RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear + 1, m: 5, d: 16),
                                                      andDate: ld(y: huntingYear + 1, m: 6, d: 15))
    }

    // 20.8-27.8 and 1.10 - 30.11
    private static func isMetsahanhiSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2017)  {
            return false
        }

        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 8, d: 27)) ||
            RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 10, d: 1),
                                                      andDate: ld(y: huntingYear, m: 11, d: 30))
    }

    // Haahka
    private static func isCommonEiderSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2019) {
            return false;
        }

        // 1.6. - 15.6.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear + 1, m: 6, d: 1),
                                                         andDate: ld(y: huntingYear + 1, m: 6, d: 15))
    }

    // Nokikana
    private static func isCootSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2020) {
            return false;
        }

        // 20.8. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Heinätavi
    private static func isGarganeySeason(day: Date, huntingYear: Int) -> Bool {
        // Starting from 2020
        if (huntingYear < 2020) {
            return false;
        }

        // 20.8. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Isokoskelo
    private static func isGoosanderSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2020) {
            return false;
        }

        // 1.9. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 9, d: 1),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Alli
    private static func isLongTailedDuckSeason(day: Date, huntingYear: Int) -> Bool {
        // Starting from 2020
        if (huntingYear < 2020) {
            return false;
        }

        // 1.9. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 9, d: 1),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Jouhisorsa
    private static func isPintailSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2020) {
            return false;
        }

        // 20.8. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Punasotka
    private static func isPochardSeason(day: Date, huntingYear: Int) -> Bool {
        // Pochard is protected starting from 2020.
        return false;
    }

    // Tukkakoskelo
    private static func isRedBreastedMerganserSeason(day: Date, huntingYear: Int) -> Bool {
        // Protected starting from 2020.
        return false;
    }

    // Lapasorsa
    private static func isSholeverSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2020) {
            return false;
        }

        // 20.8. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Tukkasotka
    private static func isTuftedDuckSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2020) {
            return false;
        }

        // 20.8. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    // Haapana
    private static func isWigeonSeason(day: Date, huntingYear: Int) -> Bool {
        if (huntingYear < 2020) {
            return false;
        }

        // 20.8. — 31.12.
        return RiistaDateTimeUtils.betweenDatesInclusive(day, isBetweenDate: ld(y: huntingYear, m: 8, d: 20),
                                                         andDate: ld(y: huntingYear, m: 12, d: 31))
    }

    private static func ld(y: Int, m: Int, d: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: y, month: m, day: d, hour: 0, minute: 0, second: 0)

        return calendar.date(from: components)!
    }
}
