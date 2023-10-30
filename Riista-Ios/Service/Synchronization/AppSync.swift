import Foundation
import Reachability
import Alamofire
import RiistaCommon
import Async

@objc class AppSync: NSObject {
    @objc static let shared: AppSync = AppSync()

    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

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


    private lazy var periodicSync: PeriodicTask = {
        PeriodicTask(name: "PeriodicSync", intervalSeconds: 5*60.0) { [weak self] onCompleted in
            guard let self = self else {
                onCompleted()
                return
            }

            let preconditionsMet = self.areSyncPreconditionsMet(
                requiredSyncPreconditions: SyncPrecondition.requiredForPeriodicSync,
                logTag: "periodic sync"
            )

            if (preconditionsMet) {
                let synchronizationLevel = self.determineSynchronizationLevelForPeriodicSync()

                self.logger.v { "Synchronization level = \(synchronizationLevel) for periodic sync."}

                self.synchronize(
                    usingLevel: synchronizationLevel,
                    markAsPendingIfAlreadySynchronizing: false,
                    forceContentReload: false,
                    onCompleted: onCompleted
                )
            } else {
                self.logger.w { "Preconditions not met for periodic sync. Completing current synchronization."}
                onCompleted()
            }
        }
    }()

    /**
     * Is the app currently synchronizing user content?
     */
    @objc private var synchronizingUserContent: Bool {
        return currentSynchronization?.synchronizationLevel == .userContent
    }

    /**
     * The current synchronization
     */
    private var currentSynchronization: Synchronization? {
        didSet {
            updateSyncIndication()
            updateManualSynchronizationPossible()
        }
    }

    /**
     * Information for the next / pending synchronization.
     */
    private lazy var pendingSynchronization: PendingSynchronization = {
        PendingSynchronization { [weak self] in
            self?.updateManualSynchronizationPossible()
            self?.updateSyncIndication()
        }
    }()


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

        queuePeriodicSyncIfPreconditionsMet(synchronizeNow: precondition.triggersImmediatePeriodicSyncWhenEnabled)
    }

    @objc func disableSyncPrecondition(_ precondition: SyncPrecondition) {
        if (enabledSyncPreconditions.remove(precondition) != nil) {
            logger.v { "Disabled sync precondition \(precondition)" }

            updateManualSynchronizationPossible()

            if (precondition.isRequiredForPeriodicSync) {
                periodicSync.stop()
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

    @objc func synchronizeManually(forceContentReload: Bool) {
        if (areSyncPreconditionsMet(for: .manual)) {
            synchronize(
                usingLevel: .userContent,
                markAsPendingIfAlreadySynchronizing: true,
                forceContentReload: forceContentReload,
                onCompleted: nil
            )
        }
    }


    @objc func synchronize(
        usingLevel synchronizationLevel: SynchronizationLevel,
        markAsPendingIfAlreadySynchronizing: Bool,
        forceContentReload: Bool,
        onCompleted: OnCompleted?
    ) {
        if (forceContentReload) {
            pendingSynchronization.addFlag(.forceContentReload)
        }

        if (currentSynchronization != nil) {
            if (markAsPendingIfAlreadySynchronizing && synchronizationLevel == .userContent) {
                logger.v { "Already synchronizing, marking pending .userContent sync" }
                pendingSynchronization.addFlags([.forceUserContentSync, .syncImmediatelyAfterCurrentSync])
            } else {
                logger.v { "Already synchronizing, not starting sync again" }
            }
            onCompleted?()
            return
        }

        logger.v { "Starting synchronization" }

        let synchronization = Synchronization(
            synchronizationLevel: synchronizationLevel,
            synchronizationConfig: SynchronizationConfig(
                forceContentReload: pendingSynchronization.contains(.forceContentReload)
            )
        )

        // clear pending flags now that we've created a synchronization based on them
        pendingSynchronization.clear()

        currentSynchronization = synchronization

        synchronization.synchronize { [self] _ in
            if (pendingSynchronization.contains(.syncImmediatelyAfterCurrentSync)) {
                scheduleImmediateSync(
                    synchronizeUserContent: pendingSynchronization.contains(.forceUserContentSync),
                    forceContentReload: pendingSynchronization.contains(.forceContentReload)
                )
            }

            self.currentSynchronization = nil
            onCompleted?()
        }
    }

    private func scheduleImmediateSync(
        synchronizeUserContent: Bool,
        forceContentReload: Bool
    ) {
        Async.main(after: 0.1) { [self] in
            self.synchronize(
                usingLevel: synchronizeUserContent ? .userContent : .metadata,
                markAsPendingIfAlreadySynchronizing: false,
                forceContentReload: forceContentReload,
                onCompleted: nil
            )
        }
    }

    private func determineSynchronizationLevelForPeriodicSync() -> SynchronizationLevel {
        let syncMode = SynchronizationMode.currentValue

        if (syncMode == .automatic && areSyncPreconditionsMet(for: syncMode)) {
            return .userContent
        }
        if (pendingSynchronization.flags.contains(.forceUserContentSync)) {
            return .userContent
        }

        return .metadata
    }


    // MARK: Checking sync preconditions

    private func queuePeriodicSyncIfPreconditionsMet(synchronizeNow: Bool) {
        let preconditionsMet = areSyncPreconditionsMet(
            requiredSyncPreconditions: SyncPrecondition.requiredForPeriodicSync,
            logTag: "periodic sync"
        )

        if (preconditionsMet) {
            periodicSync.start(launchFirstTaskNow: synchronizeNow)
        }
    }

    private func areSyncPreconditionsMet(for synchronizationMode: SynchronizationMode) -> Bool {
        return areSyncPreconditionsMet(
            requiredSyncPreconditions: SyncPrecondition.requiredFor(synchronizationMode: synchronizationMode),
            logTag: "\(synchronizationMode)"
        )
    }

    private func areSyncPreconditionsMet(requiredSyncPreconditions: Set<SyncPrecondition>, logTag: String) -> Bool {
        let preconditionsMet = requiredSyncPreconditions.isSubset(of: enabledSyncPreconditions)

        if (preconditionsMet) {
            logger.v { "Sync preconditions met for \(logTag)" }
        } else {
            logger.v { "Sync preconditions NOT met for \(logTag)" }
        }

        return preconditionsMet
    }



    // MARK: Manual sync possibility

    private func updateManualSynchronizationPossible() {
        let pendingImmediateUserContentSync = pendingSynchronization.containsAll(
            [.forceUserContentSync, .syncImmediatelyAfterCurrentSync]
        )

        manualSynchronizationPossible = !synchronizingUserContent && areSyncPreconditionsMet(for: .manual) &&
            !pendingImmediateUserContentSync
    }


    // MARK: Sync indication

    private func updateSyncIndication() {
        let pendingImmediateUserContentSync = pendingSynchronization.containsAll(
            [.forceUserContentSync, .syncImmediatelyAfterCurrentSync]
        )
        BackgroundOperationStatus.shared.updateOperationStatus(
            .synchronization,
            inProgress: synchronizingUserContent || pendingImmediateUserContentSync
        )
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

    var isRequiredForPeriodicSync: Bool {
        return Self.requiredForPeriodicSync.contains(self)
    }


    static func requiredFor(synchronizationMode: SynchronizationMode) -> Set<AppSync.SyncPrecondition> {
        switch synchronizationMode {
        case .manual:           return requiredForManualSync
        case .automatic:        return requiredForAutomaticSync
        }
    }

    static var requiredForPeriodicSync: Set<AppSync.SyncPrecondition> = {
        let requiredSyncPreconditions = AppSync.SyncPrecondition.allCases.filter { precondition in
            switch precondition {
            case .automaticSyncEnabled:                     return false
            case .userIsNotModifyingSynchronizableEntry:    return true
            case .networkReachable:                         return true
            case .appIsActive:                              return true
            case .credentialsVerified:                      return true
            case .databaseMigrationFinished:                return true
            case .furtherAppUsageAllowed:                   return true
            }
        }

        return Set(requiredSyncPreconditions)
    }()

    static var requiredForAutomaticSync: Set<AppSync.SyncPrecondition> = {
        let requiredSyncPreconditions = AppSync.SyncPrecondition.allCases.filter { precondition in
            switch precondition {
            case .automaticSyncEnabled:                     return true
            case .userIsNotModifyingSynchronizableEntry:    return true
            case .networkReachable:                         return true
            case .credentialsVerified:                      return true
            case .appIsActive:                              return true
            case .databaseMigrationFinished:                return true
            case.furtherAppUsageAllowed:                    return true
            }
        }

        return Set(requiredSyncPreconditions)
    }()

    static var requiredForManualSync: Set<AppSync.SyncPrecondition> = {
        let requiredSyncPreconditions = AppSync.SyncPrecondition.allCases.filter { precondition in
            switch precondition {
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

        return Set(requiredSyncPreconditions)
    }()

    /**
     * Should the periodic sync be performed immediately when precondition is enabled (assuming other conditions are met)?
     *
     * Allows having sync preconditions that prevent scheduled periodic sync.
     */
    var triggersImmediatePeriodicSyncWhenEnabled: Bool {
        switch self {
        case .userIsNotModifyingSynchronizableEntry:    return false // require explicit call to start sync

        // enabling automatic _user content_ sync should trigger immediate sync in order
        // to give user an impression that app reacted to user request
        case .automaticSyncEnabled:                     return true
        case .networkReachable:                         return true
        case .appIsActive:                              return true
        case .credentialsVerified:                      return true
        case .databaseMigrationFinished:                return true
        case .furtherAppUsageAllowed:                   return true
        }
    }
}
