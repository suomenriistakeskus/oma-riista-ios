import Foundation
import CoreData
import Async
import RiistaCommon

class MigrateDiaryEntriesToRiistaCommon {
    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

    func migrate(from context: NSManagedObjectContext, _ onCompleted: @escaping OnCompleted) {
        guard let diaryEntries = fetchDiaryEntries(context: context) else {
            logger.w { "Failed to fetch diary entries, cannot migrate" }
            return
        }

        migrateDiaryEntries(diaryEntries: diaryEntries, context: context) {
            onCompleted()
        }
    }



    private func migrateDiaryEntries(
        diaryEntries: Array<DiaryEntry>,
        context: NSManagedObjectContext,
        _ onCompleted: @escaping OnCompleted
    ) {
        logger.v { "About to migrate \(diaryEntries.count) diary entries" }

        migrateDiaryEntries(
            remainingDiaryEntries: ArraySlice(diaryEntries),
            successfullyMigratedCount: 0,
            migrationFailureCount: 0,
            skippedMigrationsCount: 0,
            context: context
        ) { successCount, failureCount, skipCount in
            self.logger.v {
                "Completed diary entry migration: \(successCount) succeeded, \(failureCount) failed, \(skipCount) skipped"
            }
            onCompleted()
        }
    }

    private func migrateDiaryEntries(
        remainingDiaryEntries: ArraySlice<DiaryEntry>,
        successfullyMigratedCount: Int,
        migrationFailureCount: Int,
        skippedMigrationsCount: Int,
        context: NSManagedObjectContext,
        completion: @escaping (Int, Int, Int) -> Void
    ) {
        if (remainingDiaryEntries.isEmpty) {
            completion(successfullyMigratedCount, migrationFailureCount, skippedMigrationsCount)
            return
        }

        let diaryEntry = remainingDiaryEntries.first!
        let remainingDiaryEntries = remainingDiaryEntries.dropFirst()

        if (!shouldMigrateDiaryEntry(diaryEntry: diaryEntry)) {
            logger.v {
                "Not migrating diary with remote id \(diaryEntry.remoteId ?? -1) / object id \(diaryEntry.objectID)"
            }

            migrateDiaryEntries(
                remainingDiaryEntries: remainingDiaryEntries,
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
        scheduleDiaryEntryMigration(diaryEntry: diaryEntry, context: context) { [self] success in
            logger.v {
                "Migration of diary with remote id \(diaryEntry.remoteId ?? -1) / object id \(diaryEntry.objectID) " +
                (success ? "succeeded" : "FAILED")
            }

            self.migrateDiaryEntries(
                remainingDiaryEntries: remainingDiaryEntries,
                successfullyMigratedCount: successfullyMigratedCount + (success ? 1 : 0),
                migrationFailureCount: migrationFailureCount + (success ? 0 : 1),
                skippedMigrationsCount: skippedMigrationsCount,
                context: context,
                completion: completion
            )
        }
    }

    private func shouldMigrateDiaryEntry(diaryEntry: DiaryEntry) -> Bool {
        if let commonHarvestId = diaryEntry.commonHarvestId, commonHarvestId.int32Value > 0 {
            logger.v {
                "diary already migrated: remote id \(diaryEntry.remoteId ?? -1) / object id \(diaryEntry.objectID)"
            }

            return false
        } else {
            return true
        }
    }

    private func scheduleDiaryEntryMigration(
        diaryEntry: DiaryEntry,
        context: NSManagedObjectContext,
        completion: @escaping OnCompletedWithStatus
    ) {
        Async.main {
            self.migrateDiaryEntry(diaryEntry: diaryEntry, context: context, completion: completion)
        }
    }

    private func migrateDiaryEntry(
        diaryEntry: DiaryEntry,
        context: NSManagedObjectContext,
        completion: @escaping OnCompletedWithStatus
    ) {
        // Sanitize diary entry as the first step. Earlier app versios may have had bugs which
        // may have caused errorneous data to exist in local database. Attempt to fix those errors
        // before migrating data to common lib.
        HarvestSanitizer.sanitize(harvest: diaryEntry)

        guard let commonHarvest = diaryEntry.toCommonHarvest(objectId: diaryEntry.objectID) else {
            logger.v { "Failed to convert diary event to CommonHarvest" }
            completion(false)
            return
        }

        RiistaSDK.shared.harvestContext.saveHarvest(
            harvest: commonHarvest,
            completionHandler: handleOnMainThread { response, error in
                if (error != nil) {
                    self.logger.w { "Got errors when saving diary event to common lib" }
                    completion(false)
                    return
                }

                if let successResponse = response as? HarvestOperationResponse.Success {
                    if let commonHarvestId: KotlinLong = successResponse.harvest.localId {
                        diaryEntry.commonHarvestId = NSNumber(value: commonHarvestId.int32Value)
                    } else {
                        self.logger.d { "Failed to obtain id of migrated diary entry. Considering still as success" }
                        // save some value to prevent migrating again
                        diaryEntry.commonHarvestId = NSNumber(value: Int32.max)
                    }

                    self.logger.v {
                        "diary with remote id \(diaryEntry.remoteId ?? -1) / object id \(diaryEntry.objectID) " +
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

    private func fetchDiaryEntries(context: NSManagedObjectContext) -> [DiaryEntry]? {
        let fetchRequest = NSFetchRequest<DiaryEntry>(entityName: "DiaryEntry")
        fetchRequest.returnsObjectsAsFaults = false

        return try? context.fetch(fetchRequest)
    }
}
