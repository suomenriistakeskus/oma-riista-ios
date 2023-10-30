import Foundation
import CoreData


public class MhPermit: NSManagedObject {

    var period: String? {
        if (beginDate == nil) {
            if (endDate != nil) {
                return "- \(DatetimeUtil.stringDateToDisplayString(string: endDate))"
            }
            return nil
        }

        if (endDate == nil) {
            return DatetimeUtil.stringDateToDisplayString(string: beginDate)
        }
        else if (endDate! == beginDate!) {
            return DatetimeUtil.stringDateToDisplayString(string: beginDate)
        }
        else {
            return "\(DatetimeUtil.stringDateToDisplayString(string: beginDate)) - \(DatetimeUtil.stringDateToDisplayString(string: endDate))"
        }
    }

    func getPermitName(languageCode: String?) -> String? {
        if (permitName != nil) {
            var value: String? = nil

            switch languageCode {
            case "sv":
                value = permitName?.value(forKey: "sv") as? String
            case "en":
                value = permitName?.value(forKey: "en") as? String
            // "fi"
            default:
                value = permitName?.value(forKey: "fi") as? String
            }

            if (value == nil) {
                value = permitName?.value(forKey: "fi") as? String
            }

            return value
        }

        return nil
    }

    func getPermitType(languageCode: String?) -> String? {
        if (permitType != nil) {
            var value: String? = nil

            switch languageCode {
            case "sv":
                value = permitType?.value(forKey: "sv") as? String
            case "en":
                value = permitType?.value(forKey: "en") as? String
            // "fi"
            default:
                value = permitType?.value(forKey: "fi") as? String
            }

            if (value == nil) {
                value = permitType?.value(forKey: "fi") as? String
            }

            return value
        }

        return nil
    }

    func getAreaName(languageCode: String?) -> String? {
        if (areaName != nil) {
            var value: String? = nil

            switch languageCode {
            case "sv":
                value = areaName?.value(forKey: "sv") as? String
            case "en":
                value = areaName?.value(forKey: "en") as? String
            // "fi"
            default:
                value = areaName?.value(forKey: "fi") as? String
            }

            if (value == nil) {
                value = areaName?.value(forKey: "fi") as? String
            }

            return value
        }

        return nil
    }

    func getAreaNumberAndName(languageCode: String?) -> String? {
        let name = getAreaName(languageCode: languageCode)

        if (name != nil) {
            return "\(areaNumber) \(name!)"
        }
        else {
            return areaNumber
        }
    }

    func getHarvestFeedbackUrl(languageCode: String?) -> String? {
        if (harvestFeedbackUrl != nil) {
            var value: String? = nil

            switch languageCode {
                case "sv":
                    value = harvestFeedbackUrl?.value(forKey: "sv") as? String
                case "en":
                    value = harvestFeedbackUrl?.value(forKey: "en") as? String
                // "fi"
                default:
                    value = harvestFeedbackUrl?.value(forKey: "fi") as? String
            }

            if (value == nil) {
                value = harvestFeedbackUrl?.value(forKey: "fi") as? String
            }

            return value
        }

        return nil
    }

    static func getLocalizedPermitTypeAndIdentifier(permit: MhPermit?, languageCode: String?) -> String? {
        if (permit != nil) {
            if (languageCode != nil) {
                return "\(permit?.getPermitType(languageCode: languageCode) ?? RiistaBridgingUtils.RiistaLocalizedString(forkey: "MetsahallitusPermitCardTitle")), \(permit?.permitIdentifier ?? "")"
            }
            else {
                return permit?.permitIdentifier
            }
        }

        return nil
    }

    static func getLocalizedAreaNumberAndName(permit: MhPermit?, languageCode: String?) -> String? {
        return permit?.getAreaNumberAndName(languageCode: languageCode)
    }

    static func getLocalizedPermitName(permit: MhPermit?, languageCode: String?) -> String? {
        return permit?.getPermitName(languageCode: languageCode)
    }

    static func getPeriod(permit: MhPermit?) -> String? {
        return permit?.period
    }

    static func getLocalizedHarvestFeedbackUrl(permit: MhPermit?, languageCode: String?) -> String? {
        return permit?.getHarvestFeedbackUrl(languageCode: languageCode)
    }
}
