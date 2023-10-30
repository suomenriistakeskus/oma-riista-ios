import Foundation
import RiistaCommon

extension Permit {
    func toCommonHarvestPermit() -> CommonHarvestPermit {
        return CommonHarvestPermit(
            permitNumber: permitNumber,
            permitType: permitType,
            speciesAmounts: parseCommonSpeciesAmounts(),
            available: unavailable == false
        )
    }

    private func parseCommonSpeciesAmounts() -> [CommonHarvestPermitSpeciesAmount] {
        guard let speciesAmounts = speciesAmounts else {
            return []
        }

        return speciesAmounts.compactMap { speciesAmount in
            (speciesAmount as? PermitSpeciesAmounts)?.toCommonHarvestPermitSpeciesAmount()
        }
    }
}

extension PermitSpeciesAmounts {
    func toCommonHarvestPermitSpeciesAmount() -> CommonHarvestPermitSpeciesAmount {
        return CommonHarvestPermitSpeciesAmount(
            speciesCode: gameSpeciesCode.toKotlinInt(),
            validityPeriods: [
                datesToLocalDatePeriod(beginDate: beginDate, endDate: endDate),
                datesToLocalDatePeriod(beginDate: beginDate2, endDate: endDate2),
            ].compactMap { $0 },
            amount: amount.toKotlinDouble(),
            ageRequired: ageRequired,
            genderRequired: genderRequired,
            weightRequired: weightRequired
        )
    }

    private func datesToLocalDatePeriod(beginDate: Foundation.Date?, endDate: Foundation.Date?) -> LocalDatePeriod? {
        guard let beginDate = beginDate, let endDate = endDate else {
            return nil
        }

        return LocalDatePeriod(
            beginDate: beginDate.toLocalDate(),
            endDate: endDate.toLocalDate()
        )
    }
}


