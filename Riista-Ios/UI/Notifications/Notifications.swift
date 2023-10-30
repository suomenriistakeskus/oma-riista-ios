import Foundation

extension Notification.Name {

    // MARK: Navigation

    // used when navigation item is updated for a viewcontroller that lives under tabbarcontroller
    static let NavigationItemUpdated = Notification.Name(rawValue: "NavigationItemUpdated")


    // MARK: Authentication

    static let RequestLogout = Notification.Name(rawValue: "RequestLogout")


    // MARK: Background operation status

    static let BackgroundOperationInProgressStatusChanged = Notification.Name(rawValue: "BackgroundOperationInProgressStatusChanged")


    // MARK: Synchronization

    // param: current status as NSNumber(bool:) value
    static let ManualSynchronizationPossibleStatusChanged = Notification.Name(rawValue: NotificationNames.ManualSynchronizationPossibleStatusChanged)


    // MARK: Settings

    static let LanguageSelectionUpdated = Notification.Name(rawValue: NotificationNames.LanguageSelectionUpdated)
}

// for objective-c usage, only those names included
@objcMembers class NotificationNames: NSObject {
    static let ManualSynchronizationPossibleStatusChanged = "ManualSynchronizationPossibleStatusChanged"

    static let EntityModifiedName: Notification.Name = EntityModified.self.name

    static let LanguageSelectionUpdated = "LanguageSelectionUpdated"

}
