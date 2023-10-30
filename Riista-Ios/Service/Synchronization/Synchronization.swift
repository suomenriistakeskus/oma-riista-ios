import Foundation
import RiistaCommon


typealias OnSynchronizationCompleted = (_ synchronization: Synchronization) -> Void

class Synchronization {
    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

    let synchronizationLevel: SynchronizationLevel
    let synchronizationConfig: SynchronizationConfig

    init(synchronizationLevel: SynchronizationLevel, synchronizationConfig: SynchronizationConfig) {
        self.synchronizationLevel = synchronizationLevel
        self.synchronizationConfig = synchronizationConfig
    }

    func synchronize(_ onCompleted: @escaping OnSynchronizationCompleted) {
        logger.v { "Starting the actual synchronization" }

        RiistaGameDatabase.sharedInstance().synchronizeDiaryEntries(
            synchronizationLevel,
            synchronizationConfig: synchronizationConfig
        ) { [self] in
            self.logger.v { "Actual synchronization completed" }

            onCompleted(self)
        }
    }
}
