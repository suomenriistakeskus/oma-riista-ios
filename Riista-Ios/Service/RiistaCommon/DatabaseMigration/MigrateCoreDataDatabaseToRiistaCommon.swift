import Foundation

@objc class MigrateCoreDataDatabaseToRiistaCommon: NSObject {

    @objc static let shared: MigrateCoreDataDatabaseToRiistaCommon = {
        MigrateCoreDataDatabaseToRiistaCommon()
    }()

    private enum Migration: CaseIterable {
        case srva, observation
    }

    private var completedMigrations: Set<Migration> = Set()


    @objc func migrate(from: NSManagedObjectContext, _ onCompleted: @escaping OnCompleted) {
        BackgroundOperationStatus.shared.startOperation(.databaseMigration)

        MigrateSrvaEntriesToRiistaCommon().migrate(from: from) {
            self.notifyOnCompletedIfFullyMigrated(completedMigration: .srva, onCompleted: onCompleted)
        }

        MigrateObservationEntriesToRiistaCommon().migrate(from: from) {
            self.notifyOnCompletedIfFullyMigrated(completedMigration: .observation, onCompleted: onCompleted)
        }
    }

    private func notifyOnCompletedIfFullyMigrated(completedMigration: Migration, onCompleted: @escaping OnCompleted) {
        completedMigrations.insert(completedMigration)

        if (completedMigrations.count == Migration.allCases.count) {
            BackgroundOperationStatus.shared.finishOperation(.databaseMigration)

            onCompleted()
        }
    }
}
