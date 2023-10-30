import Foundation
import CoreData
import Async
import RiistaCommon

class MigrateObservationEntriesToRiistaCommon {
    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

    func migrate(from context: NSManagedObjectContext, _ onCompleted: @escaping OnCompleted) {
        guard let observationEntries = fetchObservationEntries(context: context) else {
            logger.w { "Failed to fetch observation entries, cannot migrate" }
            return
        }

        migrateObservationEntries(observationEntries: observationEntries, context: context) {
            onCompleted()
        }
    }



    private func migrateObservationEntries(
        observationEntries: Array<ObservationEntry>,
        context: NSManagedObjectContext,
        _ onCompleted: @escaping OnCompleted
    ) {
        logger.v { "About to migrate \(observationEntries.count) observation entries" }

        migrateObservationEntries(
            remainingObservationEntries: ArraySlice(observationEntries),
            successfullyMigratedCount: 0,
            migrationFailureCount: 0,
            skippedMigrationsCount: 0,
            context: context
        ) { successCount, failureCount, skipCount in
            self.logger.v {
                "Completed observation entry migration: \(successCount) succeeded, \(failureCount) failed, \(skipCount) skipped"
            }
            onCompleted()
        }
    }

    private func migrateObservationEntries(
        remainingObservationEntries: ArraySlice<ObservationEntry>,
        successfullyMigratedCount: Int,
        migrationFailureCount: Int,
        skippedMigrationsCount: Int,
        context: NSManagedObjectContext,
        completion: @escaping (Int, Int, Int) -> Void
    ) {
        if (remainingObservationEntries.isEmpty) {
            completion(successfullyMigratedCount, migrationFailureCount, skippedMigrationsCount)
            return
        }

        let observationEntry = remainingObservationEntries.first!
        let remainingObservationEntries = remainingObservationEntries.dropFirst()

        if (!shouldMigrateObservationEntry(observationEntry: observationEntry)) {
            logger.v {
                "Not migrating observation with remote id \(observationEntry.remoteId ?? -1) / object id \(observationEntry.objectID)"
            }

            migrateObservationEntries(
                remainingObservationEntries: remainingObservationEntries,
                successfullyMigratedCount: successfullyMigratedCount,
                migrationFailureCount: migrationFailureCount,
                skippedMigrationsCount: skippedMigrationsCount + 1,
                context: context,
                completion: completion
            )
            return
        }

        // schedule migration, but don't migrate immediately
        // --> allows main thread to perform other tasks as well in between
        scheduleObservationEntryMigration(observationEntry: observationEntry, context: context) { [self] success in
            logger.v {
                "Migration of observation with remote id \(observationEntry.remoteId ?? -1) / object id \(observationEntry.objectID) " +
                (success ? "succeeded" : "FAILED")
            }

            self.migrateObservationEntries(
                remainingObservationEntries: remainingObservationEntries,
                successfullyMigratedCount: successfullyMigratedCount + (success ? 1 : 0),
                migrationFailureCount: migrationFailureCount + (success ? 0 : 1),
                skippedMigrationsCount: skippedMigrationsCount,
                context: context,
                completion: completion
            )
        }
    }

    private func shouldMigrateObservationEntry(observationEntry: ObservationEntry) -> Bool {
        if let commonObservationId = observationEntry.commonObservationId, commonObservationId.int32Value > 0 {
            logger.v {
                "observation already migrated: remote id \(observationEntry.remoteId ?? -1) / object id \(observationEntry.objectID)"
            }

            return false
        } else {
            return true
        }
    }

    private func scheduleObservationEntryMigration(
        observationEntry: ObservationEntry,
        context: NSManagedObjectContext,
        completion: @escaping OnCompletedWithStatus
    ) {
        Async.main {
            self.migrateObservationEntry(observationEntry: observationEntry, context: context, completion: completion)
        }
    }

    private func migrateObservationEntry(
        observationEntry: ObservationEntry,
        context: NSManagedObjectContext,
        completion: @escaping OnCompletedWithStatus
    ) {
        guard let commonObservation = observationEntry.toCommonObservation(objectId: observationEntry.objectID) else {
            logger.v { "Failed to convert observation event to CommonObservationEvent" }
            completion(false)
            return
        }

        RiistaSDK.shared.observationContext.saveObservation(
            observation: commonObservation,
            completionHandler: handleOnMainThread { response, error in
                if (error != nil) {
                    self.logger.w { "Got errors when saving observation event to common lib" }
                    completion(false)
                    return
                }

                if let successResponse = response as? ObservationOperationResponse.Success {
                    if let commonObservationId: KotlinLong = successResponse.observation.localId {
                        observationEntry.commonObservationId = NSNumber(value: commonObservationId.int32Value)
                    } else {
                        self.logger.d { "Failed to obtain id of migrated observation event. Considering still as success" }
                        // save some value to prevent migrating again
                        observationEntry.commonObservationId = NSNumber(value: Int32.max)
                    }

                    self.logger.v {
                        "observation with remote id \(observationEntry.remoteId ?? -1) / object id \(observationEntry.objectID) " +
                        "saved to common lib. Saving managed object context."
                    }

                    do {
                        try context.save()

                        self.logger.v { " - ManagedObjectContext saved" }
                    } catch {
                        self.logger.e { " - ManagedObjectContext save FAILED" }
                    }

                    completion(true)
                } else {
                    completion(false)
                }
            }
        )
    }

    private func fetchObservationEntries(context: NSManagedObjectContext) -> [ObservationEntry]? {
        let fetchRequest = NSFetchRequest<ObservationEntry>(entityName: "ObservationEntry")
        fetchRequest.returnsObjectsAsFaults = false

        return try? context.fetch(fetchRequest)
    }
}
