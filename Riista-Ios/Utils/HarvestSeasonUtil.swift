import Foundation
import RiistaCommon

@objcMembers class HarvestSeasonUtil: NSObject {
    static func isInsideHuntingSeason(day: Foundation.Date, gameSpeciesCode: Int) -> Bool {
        return RiistaSDK().harvestSeasons.isDuringHuntingSeason(speciesCode: Int32(gameSpeciesCode), date: day.toLocalDate())
    }
}
