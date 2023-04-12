import Foundation

/**
 Migrates the ObservationEntry entities from model V12 to V20. This migration consists of migrating
 withinMooseHunting field to observationCategory field which occurs during metadata update from v3 to v4.
 This same migration is performed when migrating from V12 to V13

 Don't update the observationSpecVersion in process. The reasoning behind this is that it is possible
 that user has already received observations made with newer clients (white tailed deer on android clients
 that participate in deer pilots). In this case we already have the observation data stored offline but the
 data is missing some of the newer fields (e.g. deerHuntingType). By not updating the observationSpecVersion
 the iOS client will overwrite stored observations when newer observations are fetched from the backend.

 This class is closely related to MigrationFromV12ToV20.xcmappingmodel
 */
internal class ObservationEntryMappingV12ToV20: NSEntityMigrationPolicy {

    @objc func observationCategoryFor(withinMooseHunting: NSNumber?) -> NSString {
        return ObservationEntryMappingV12ToV13.determineCategoryFor(withinMooseHunting: withinMooseHunting)
    }
}
