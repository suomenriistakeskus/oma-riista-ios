import Foundation
import Reachability
import Alamofire

@objc class AppSync: NSObject {
    @objc static let shared: AppSync = AppSync()

    private lazy var logger: AppLogger = AppLogger(for: self)

    @objc enum SyncPrecondition: Int, CaseIterable {
        /**
         * Has the automatic sync been enabled?
         */
        case automaticSyncEnabled

        /**
         * Is the user doing something else than editing or creating an entry (harvest, observation, srva, hunting control event) that
         * will be synchronized during `AppSync`?
         *
         * Allows preventing synchronization while entry has been saved to database (and possibly synchronized internally) and thus
         * eliminating simultaneous synchronizations that could occur in rare circumstances i.e. when AppSync is performed right when
         * user is saving the entry.
         */
        case userIsNotModifyingSynchronizableEntry

        /**
         * Network has been at least once reachable
         */
        case networkReachable

        /**
         * Application is active i.e receiving events
         */
        case appIsActive

        /**
         * Credentials exist and preliminary tests show that they are valid i.e.
         * login call either succeeds or at least won't return 401 or 403.
         **/
        case credentialsVerified

        /**
         * Migrations from legacy app database to Riista SDK database has been run.
         */
        case databaseMigrationFinished

        /**
         * It is possible that app startup message prevents futher app usage (e.g. if app version has been deprecated)
         */
        case furtherAppUsageAllowed
    }

    private var enabledSyncPreconditions = Set<SyncPrecondition>()

    private let reachability: Reachability


    private lazy var automaticSync: PeriodicTask = {
        PeriodicTask(name: "AutomaticSync", intervalSeconds: 5*60.0) { [weak self] onCompleted in
            guard let self = self else {
                onCompleted()
                return
            }

            self.synchronize(usingMode: .automatic, onCompleted: onCompleted)
        }
    }()

    /**
     * Is the app currently synchronizing?
     */
    @objc private(set) var synchronizing: Bool = false {
        didSet {
            if (synchronizing != oldValue) {
                BackgroundOperationStatus.shared.updateOperationStatus(.synchronization, inProgress: synchronizing)

                updateManualSynchronizationPossible()
            }
        }
    }

    /**
     * Is the manual synchronization possible?
     *
     * Changes will be notified using Notification.Name.ManualSynchronizationPossibleStatusChanged
     */
    @objc private(set) var manualSynchronizationPossible: Bool = false {
        didSet {
            if (manualSynchronizationPossible != oldValue) {
                notifyManualSynchronizationPossibleStatusChanged(possible: manualSynchronizationPossible)
            }
        }
    }




    private override init() {
        self.reachability = Reachability.forInternetConnection()

        super.init()

        // assume this is the case when AppSync is first created
        enabledSyncPreconditions.insert(.userIsNotModifyingSynchronizableEntry)
        enabledSyncPreconditions.insert(.furtherAppUsageAllowed)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    // MARK: Setup & configuration

    @objc func configureUponAppStartup() {
        if (SynchronizationMode.currentValue == .automatic) {
            enableSyncPrecondition(.automaticSyncEnabled)
        }

        if (UIApplication.shared.applicationState == .active) {
            enableSyncPrecondition(.appIsActive)
        }

        registerNotificationListeners()
    }


    // MARK: Sync preconditions management

    @objc func enableSyncPrecondition(_ precondition: SyncPrecondition) {
        if (!enabledSyncPreconditions.contains(precondition)) {
            logger.v { "Enabled sync precondition \(precondition)" }
            enabledSyncPreconditions.insert(precondition)

            updateManualSynchronizationPossible()
        } else {
            logger.v { "Sync precondition \(precondition) was already enabled" }
        }

        queueAutomaticSyncIfPreconditionsMet(synchronizeNow: precondition.triggersImmediateAutomaticSyncWhenEnabled)
    }

    @objc func disableSyncPrecondition(_ precondition: SyncPrecondition) {
        if (enabledSyncPreconditions.remove(precondition) != nil) {
            logger.v { "Disabled sync precondition \(precondition)" }

            updateManualSynchronizationPossible()

            if (precondition.requiredForAutomaticSync) {
                automaticSync.stop()
            }
        } else {
            logger.v { "Sync precondition \(precondition) was already disabled" }
        }
    }



    // MARK: Sync management

    @objc func isAutomaticSyncEnabled() -> Bool {
        SynchronizationMode.currentValue.isAutomatic()
    }

    @objc func enableAutomaticSync() {
        SynchronizationMode.setCurrentValue(.automatic)
        enableSyncPrecondition(.automaticSyncEnabled)
    }

    @objc func disableAutomaticSync() {
        // disabling sync precondition will also stop automatic sync
        disableSyncPrecondition(.automaticSyncEnabled)
        SynchronizationMode.setCurrentValue(.manual)
    }


    // MARK: Synchronization

    @objc func synchronize(usingMode synchronizationMode: SynchronizationMode) {
        synchronize(usingMode: synchronizationMode, onCompleted: nil)
    }

    @objc func synchronize(usingMode synchronizationMode: SynchronizationMode, onCompleted: OnCompleted?) {
        if (!areSyncPreconditionsMet(for: synchronizationMode)) {
            logger.d { "Sync preconditions not met for \(synchronizationMode), refusing to start sync" }
            onCompleted?()
            return
        }

        if (synchronizing) {
            logger.v { "Already synchronizing, not starting sync again" }
            onCompleted?()
            return
        }

        synchronizing = true
        logger.v { "Starting synchronization using \(synchronizationMode)" }

        RiistaGameDatabase.sharedInstance().synchronizeDiaryEntries { [weak self] in
            self?.logger.v { "Synchronization completed" }

            self?.synchronizing = false
            onCompleted?()
        }
    }


    // MARK: Checking sync preconditions

    private func queueAutomaticSyncIfPreconditionsMet(synchronizeNow: Bool) {
        if (areSyncPreconditionsMet(for: .automatic)) {
            automaticSync.start(launchFirstTaskNow: synchronizeNow)
        }
    }

    private func areSyncPreconditionsMet(for synchronizationMode: SynchronizationMode) -> Bool {
        let requiredSyncPreconditions = getSyncPreconditionsForSyncMode(synchronizationMode: synchronizationMode)

        return requiredSyncPreconditions.isSubset(of: enabledSyncPreconditions)
    }

    private func getSyncPreconditionsForSyncMode(synchronizationMode: SynchronizationMode) -> Set<SyncPrecondition> {
        var requiredSyncPreconditions = Set<SyncPrecondition>()

        SyncPrecondition.allCases.forEach { precondition in
            if (precondition.isRequiredFor(synchronizationMode: synchronizationMode)) {
                requiredSyncPreconditions.insert(precondition)
            }
        }

        return requiredSyncPreconditions
    }


    // MARK: Manual sync possibility

    private func updateManualSynchronizationPossible() {
        manualSynchronizationPossible = !synchronizing && areSyncPreconditionsMet(for: .manual)
    }


    // MARK: Notifications

    private func registerNotificationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onNetworkConnectivityChanged),
            name: .reachabilityChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc private func onNetworkConnectivityChanged() {
        let currentStatus = reachability.currentReachabilityStatus()
        if (currentStatus != .NotReachable) {
            enableSyncPrecondition(.networkReachable)
        }
    }

    @objc private func onDidBecomeActiveNotification() {
        enableSyncPrecondition(.appIsActive)
    }

    @objc private func onWillResignActiveNotification() {
        disableSyncPrecondition(.appIsActive)
    }

    private func notifyManualSynchronizationPossibleStatusChanged(possible: Bool) {
        NotificationCenter.default.post(
            Notification(name: .ManualSynchronizationPossibleStatusChanged, object: NSNumber(value: possible))
        )
    }
}

// can be removed once SyncPrecondition no longer is marked with @objc
extension AppSync.SyncPrecondition: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .automaticSyncEnabled:                     return ".automaticSyncEnabled"
        case .userIsNotModifyingSynchronizableEntry:    return ".userIsNotModifyingSynchronizableEntry"
        case .networkReachable:                         return ".networkReachable"
        case .appIsActive:                              return ".appOnForeground"
        case .credentialsVerified:                      return ".credentialsVerified"
        case .databaseMigrationFinished:                return ".databaseMigrationFinished"
        case .furtherAppUsageAllowed:                   return ".furtherAppUsageAllowed"
        }
    }
}


fileprivate extension AppSync.SyncPrecondition {
    func isRequiredFor(synchronizationMode: SynchronizationMode) -> Bool {
        switch synchronizationMode {
        case .manual:           return requiredForManualSync
        case .automatic:        return requiredForAutomaticSync
        }
    }

    var requiredForAutomaticSync: Bool {
        // explicitly add all cases as that ensures that this place gets updated
        // if a new case is added
        switch self {
        case .automaticSyncEnabled:                     return true
        case .userIsNotModifyingSynchronizableEntry:    return true
        case .networkReachable:                         return true
        case .credentialsVerified:                      return true
        case .appIsActive:                              return true
        case .databaseMigrationFinished:                return true
        case .furtherAppUsageAllowed:                   return true
        }
    }

    var requiredForManualSync: Bool {
        switch self {
        case .automaticSyncEnabled:                     return false
        case .userIsNotModifyingSynchronizableEntry:    return false
        case .networkReachable:
            // don't require network for _attempting_ manual sync
            return false
        case .appIsActive:                              return true
        case .credentialsVerified:                      return true
        case .databaseMigrationFinished:                return true
        case .furtherAppUsageAllowed:                   return true
        }
    }

    /**
     * Should the automatic sync be performed immediately when precondition is enabled (assuming other conditions are met)?
     *
     * Allows having sync preconditions that prevent scheduled automatic sync.
     */
    var triggersImmediateAutomaticSyncWhenEnabled: Bool {
        switch self {
        case .automaticSyncEnabled:                     return true
        case .userIsNotModifyingSynchronizableEntry:    return false // require explicit call to start sync
        case .networkReachable:                         return true
        case .appIsActive:                              return true
        case .credentialsVerified:                      return true
        case .databaseMigrationFinished:                return true
        case .furtherAppUsageAllowed:                   return true
        }

    }
}
