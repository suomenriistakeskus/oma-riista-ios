import Foundation
import RiistaCommon

extension CalendarEventType {
    // todo: use LocalizableEnum in mobile-common-lib when more calendar event types are needed
    var localizedName: String {
        switch (self) {
        case CalendarEventType.ampumakoe:
            return "ShootingTestCalendarEventTypeNormal".localized()
        case CalendarEventType.jousiampumakoe:
            return "ShootingTestCalendarEventTypeBow".localized()
        default:
            return name
        }
    }
}
