import Foundation
import TypedNotification
import RiistaCommon

struct EntityModified: TypedNotification {
    struct Data {
        let entityType: DiaryEntryType
        let entityPointOfTime: LocalDateTime
        let entitySpecies: RiistaCommon.Species

        /**
         * Has the entity been reported for other (true) or is the entity user's own entity (false)?
         */
        let entityReportedForOthers: Bool
    }

    let object: Data
}
