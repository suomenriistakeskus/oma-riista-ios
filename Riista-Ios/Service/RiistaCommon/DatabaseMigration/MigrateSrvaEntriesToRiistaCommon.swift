import Foundation
import CoreData
import Async
import RiistaCommon

class MigrateSrvaEntriesToRiistaCommon {
    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

    func migrate(from context: NSManagedObjectContext, _ onCompleted: @escaping OnCompleted) {
        guard let srvaEntries = fetchSrvaEntries(context: context) else {
            logger.w { "Failed to fetch SRVA entries, cannot migrate" }
            return
        }

        migrateSrvaEntries(srvaEntries: srvaEntries, context: context) {
            onCompleted()
        }
    }



    private func migrateSrvaEntries(
        srvaEntries: Array<SrvaEntry>,
        context: NSManagedObjectContext,
        _ onCompleted: @escaping OnCompleted
    ) {
        logger.v { "About to migrate \(srvaEntries.count) SRVA entries" }

        migrateSrvaEntries(
            remainingSrvaEntries: ArraySlice(srvaEntries),
            successfullyMigratedCount: 0,
            migrationFailureCount: 0,
            skippedMigrationsCount: 0,
            context: context
        ) { successCount, failureCount, skipCount in
            self.logger.v {
                "Completed SRVA entry migration: \(successCount) succeeded, \(failureCount) failed, \(skipCount) skipped"
            }
            onCompleted()
        }
    }

    private func migrateSrvaEntries(
        remainingSrvaEntries: ArraySlice<SrvaEntry>,
        successfullyMigratedCount: Int,
        migrationFailureCount: Int,
        skippedMigrationsCount: Int,
        context: NSManagedObjectContext,
        completion: @escaping (Int, Int, Int) -> Void
    ) {
        if (remainingSrvaEntries.isEmpty) {
            completion(successfullyMigratedCount, migrationFailureCount, skippedMigrationsCount)
            return
        }

        let srvaEntry = remainingSrvaEntries.first!
        let remainingSrvaEntries = remainingSrvaEntries.dropFirst()

        if (!shouldMigrateSrvaEntry(srvaEntry: srvaEntry)) {
            logger.v {
                "Not migrating SRVA with remote id \(srvaEntry.remoteId ?? -1) / object id \(srvaEntry.objectID)"
            }

            migrateSrvaEntries(
                remainingSrvaEntries: remainingSrvaEntries,
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
        scheduleSrvaEntryMigration(srvaEntry: srvaEntry, context: context) { [self] success in
            logger.v {
                "Migration of SRVA with remote id \(srvaEntry.remoteId ?? -1) / object id \(srvaEntry.objectID) " +
                (success ? "succeeded" : "FAILED")
            }

            self.migrateSrvaEntries(
                remainingSrvaEntries: remainingSrvaEntries,
                successfullyMigratedCount: successfullyMigratedCount + (success ? 1 : 0),
                migrationFailureCount: migrationFailureCount + (success ? 0 : 1),
                skippedMigrationsCount: skippedMigrationsCount,
                context: context,
                completion: completion
            )
        }
    }

    private func shouldMigrateSrvaEntry(srvaEntry: SrvaEntry) -> Bool {
        if let commonSrvaEventId = srvaEntry.commonSrvaEventId, commonSrvaEventId.int32Value > 0 {
            logger.v {
                "SRVA already migrated: remote id \(srvaEntry.remoteId ?? -1) / object id \(srvaEntry.objectID)"
            }

            return false
        } else {
            return true
        }
    }

    private func scheduleSrvaEntryMigration(
        srvaEntry: SrvaEntry,
        context: NSManagedObjectContext,
        completion: @escaping OnCompletedWithStatus
    ) {
        Async.main {
            self.migrateSrvaEntry(srvaEntry: srvaEntry, context: context, completion: completion)
        }
    }

    private func migrateSrvaEntry(
        srvaEntry: SrvaEntry,
        context: NSManagedObjectContext,
        completion: @escaping OnCompletedWithStatus
    ) {
        guard let commonSrvaEvent = srvaEntry.toSrvaEvent(objectId: srvaEntry.objectID) else {
            logger.v { "Failed to convert srva event to CommonSrvaEvent" }
            completion(false)
            return
        }

        RiistaSDK.shared.srvaContext.saveSrvaEvent(
            srvaEvent: commonSrvaEvent,
            completionHandler: handleOnMainThread { response, error in
                if (error != nil) {
                    self.logger.w { "Got errors when saving srva event to common lib" }
                    completion(false)
                    return
                }

                if let successResponse = response as? SrvaEventOperationResponse.Success {
                    if let commonSrvaEventId: KotlinLong = successResponse.srvaEvent.localId {
                        srvaEntry.commonSrvaEventId = NSNumber(value: commonSrvaEventId.int32Value)
                    } else {
                        self.logger.d { "Failed to obtain id of migrated SRVA event. Considering still as success" }
                        // save some value to prevent migrating again
                        srvaEntry.commonSrvaEventId = NSNumber(value: Int32.max)
                    }

                    self.logger.v {
                        "SRVA with remote id \(srvaEntry.remoteId ?? -1) / object id \(srvaEntry.objectID) " +
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

    private func fetchSrvaEntries(context: NSManagedObjectContext) -> [SrvaEntry]? {
        let fetchRequest = NSFetchRequest<SrvaEntry>(entityName: "SrvaEntry")
        fetchRequest.returnsObjectsAsFaults = false

        return try? context.fetch(fetchRequest)
    }
}
