import Foundation

extension Notification.Name {

    // MARK: Authentication

    static let RequestLogout = Notification.Name(rawValue: "RequestLogout")


    // MARK: Log entries

    static let LogEntrySaved = Notification.Name(rawValue: RiistaLogEntrySavedKey)
    static let LogEntryTypeSelected = Notification.Name(rawValue: RiistaLogTypeSelectedKey)

    static let ObservationModified = Notification.Name(rawValue: NotificationNames.ObservationModified)


    // MARK: Background operation status

    static let BackgroundOperationInProgressStatusChanged = Notification.Name(rawValue: "BackgroundOperationInProgressStatusChanged")


    // MARK: Synchronization

    // param: current status as NSNumber(bool:) value
    static let ManualSynchronizationPossibleStatusChanged = Notification.Name(rawValue: NotificationNames.ManualSynchronizationPossibleStatusChanged)
}

// for objective-c usage, only those names included
@objcMembers class NotificationNames: NSObject {
    static let ManualSynchronizationPossibleStatusChanged = "ManualSynchronizationPossibleStatusChanged"

    static let ObservationModified = "ObservationModified"
}
