#import <Foundation/Foundation.h>

@class DiaryEntry;
@class DiaryImage;
@class ObservationEntry;
@class RiistaSpecies;
@class RiistaDiaryEntryUpdate;
@class SrvaEntry;
@class SeasonStats;

extern NSString *const RiistaCalendarEntriesUpdatedKey;
extern NSString *const RiistaLanguageSelectionUpdatedKey;
extern NSString *const RiistaSynchronizationStatusKey;
extern NSString *const ISO_8601;
extern NSInteger const RiistaCalendarStartMonth;

typedef void(^RiistaOperationCompletion)(BOOL wasSuccess);
typedef void(^RiistaDiaryEntryUploadCompletion)(NSArray *updates, NSError *error);
typedef void(^RiistaDiaryEntryEditCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaDiaryEntryDeleteCompletion)(NSError *error);
typedef void(^RiistaObservationEntryUploadCompletion)(NSArray *updates, NSError *error);
typedef void(^RiistaObservationEntryEditCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaObservationEntryDeleteCompletion)(NSError *error);
typedef void(^RiistaSynchronizationCompletion)(void);
typedef void(^DiaryImageSubmitCompletion)(BOOL errors);
typedef void(^RiistaUserImageLoadCompletion)(NSArray *images, NSUInteger currentIndex);

@interface RiistaGameDatabase : NSObject

@property (strong, nonatomic, readonly) NSDictionary *categories;
@property (strong, nonatomic, readonly) NSDictionary *species;

// Used for enabling/disabling automatic synchronization
@property (assign, nonatomic) BOOL autosync;

// Is the data currently being synchronized?
@property (assign, atomic, readonly) BOOL synchronizing;

+ (RiistaGameDatabase*)sharedInstance;

- (void)initUserSession;

/**
 * Fetches all log events
 * Includes entries marked to be deleted
 * @return DiaryEntry objects
 */
- (NSArray*)allEvents;

/**
 * Only access for analytics purposes from outside!
 */
- (NSArray*)unsentDiaryEntries;

/**
 * Fetches diary entry with given remote id
 */
- (DiaryEntry*)diaryEntryWithId:(NSInteger)id;

/**
 * Fetches diary entry with given objectId
 */
- (DiaryEntry*)diaryEntryWithObjectId:(NSManagedObjectID*)objectId context:(NSManagedObjectContext*)context;

/**
 * Adds event to database using locally created entry
 */
- (void)addLocalEvent:(DiaryEntry*)diaryEntry;

/**
 * Saves changes of given database event
 * @param diaryEntry DiaryEntry object
 * @param newImages New diary images
 */
- (void)editLocalEvent:(DiaryEntry*)diaryEntry newImages:(NSArray*)images;

/**
 * Marks local database event as deleted
 * Does not actually delete local or remote entry
 * @param diaryEntry DiaryEntry object
 */
- (void)deleteLocalEvent:(DiaryEntry*)diaryEntry;

/**
 * Adds event to database using event received from remote source
 * @param diaryEntry
 * @param context
 * @return whether the new event was inserted or not
 */
- (BOOL)insertReceivedEvent:(DiaryEntry*)diaryEntry context:(NSManagedObjectContext*)context;

/**
 * Deletes all events
 */
- (void)clearEvents;

/**
 * Gives list of event start years
 */
- (NSArray*)eventYears:(NSString*)eventType;

/**
 * Gets statistics for given years
 */
- (SeasonStats*)statsForHarvestSeason:(NSInteger)startYear;

/**
 * Gets list of species with given category id
 */
- (NSArray*)speciesListWithCategoryId:(NSInteger)categoryId;

/**
 * Looks for species with given id
 */
- (RiistaSpecies*)speciesById:(NSInteger)speciesId;

/**
 * Gets latest species in time descending order
 * @return Array of gameSpeciesCode values
 */
- (NSArray*)latestEventSpecies:(NSInteger)amount;

/**
 * Fetches latest diary entries from server and sends unsent diary entries
 * Updates will be notified with notifications
 * @param completion Completion block
 */
- (void)synchronizeDiaryEntries:(RiistaSynchronizationCompletion)completion;

/**
 * Sends unsent diary entries to server
 * Updates will be notified with notifications
 * @param completion Completion block
 */
- (void)sendAndNotifyUnsentDiaryEntries:(RiistaDiaryEntryUploadCompletion)completion;

/**
 * Edits single event on server
 * Update will be notified with notifications
 * @param diaryEntry DiaryEntry object
 * @param completion Completion block
 */
- (void)editDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryEditCompletion)completion;

/**
 * Delete single event on server
 * Update will be notified with notifications
 * @param diaryEntry DiaryEntry object
 * @param completion Completion block
 */
- (void)deleteDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryDeleteCompletion)completion;

/**
 * Creates array of DiaryEntry objects using array of dictionary values
 * @param dictValues Array of NSDictionary objects representing diary entries
 */
- (NSArray*)diaryEntriesFromDictValues:(NSArray*)dictValues context:(NSManagedObjectContext*)context;

/**
 * Creates dictionary from diary entry
 * @param diaryEntry DiaryEntry object
 * @param isNew Has the diary entry been sent to server
 */
- (NSDictionary*)dictFromDiaryEntry:(DiaryEntry*)diaryEntry isNew:(BOOL)isNew;

/**
 * Load all images for entry type from the database in order
 */
- (void)userImagesWithCurrentImage:(DiaryImage*)image entryType:(NSString*)entryType completion:(RiistaUserImageLoadCompletion)completion;

#pragma mark - Observations

- (NSArray*)allObservations;
- (ObservationEntry*)observationEntryWithId:(NSInteger)id;
- (ObservationEntry*)observationEntryWithObjectId:(NSManagedObjectID*)objectId context:(NSManagedObjectContext*)context;
- (void)addLocalObservation:(ObservationEntry*)observationEntry;
- (void)editLocalObservation:(ObservationEntry*)observationEntry newImages:(NSArray*)images;
- (void)editLocalObservation:(ObservationEntry*)observationEntry;
- (void)deleteLocalObservation:(ObservationEntry*)observationEntry;
- (void)clearObservations;

- (NSArray*)observationYears;
- (SeasonStats*)statsForObservationSeason:(NSInteger)startYear;
- (NSArray*)latestObservationSpecies:(NSInteger)amount;

// a helper for swift-world. Same as editObservationEntry but with different completion block
- (void)synchronizeObservationEntry:(ObservationEntry *)observationEntry completion:(RiistaOperationCompletion)completion;
- (void)editObservationEntry:(ObservationEntry *)observationEntry completion:(RiistaDiaryEntryEditCompletion)completion;
// a helper for swift-world. Same as deleteObservationEntry but with different completion block
- (void)deleteObservationEntryCompat:(ObservationEntry *)observationEntry completion:(RiistaOperationCompletion)completion;
- (void)deleteObservationEntry:(ObservationEntry *)observationEntry completion:(RiistaDiaryEntryDeleteCompletion)completion;

- (NSArray*)observationEntriesFromDictValues:(NSArray*)dictValues context:(NSManagedObjectContext*)context;
- (NSDictionary*)dictFromObservationEntry:(ObservationEntry*)observationEntry isNew:(BOOL)isNew;

#pragma mark - Srva

- (SeasonStats*)statsForSrvaYear:(NSInteger)startYear;
- (NSArray*)latestSrvaSpecies:(NSInteger)amount;
- (SrvaEntry*)srvaEntryWithObjectId:(NSManagedObjectID*)objectId context:(NSManagedObjectContext*)context;
- (void)addLocalSrva:(SrvaEntry*)srvaEntry;
- (void)editLocalSrva:(SrvaEntry*)srvaEntry newImages:(NSArray*)images;
- (void)editSrvaEntry:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryEditCompletion)completion;
- (void)deleteLocalSrva:(SrvaEntry*)srvaEntry;
- (void)deleteSrvaEntry:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryDeleteCompletion)completion;
- (NSDictionary*)dictFromSrvaEntry:(SrvaEntry*)srvaEntry isNew:(BOOL)isNew;

@end
