#import <Foundation/Foundation.h>

@class DiaryEntry;
@class DiaryImage;
@class ObservationEntry;
@class RiistaSpecies;
@class RiistaDiaryEntryUpdate;
@class SeasonStats;

extern NSString *const RiistaCalendarEntriesUpdatedKey;
extern NSString *const RiistaLanguageSelectionUpdatedKey;
extern NSString *const ISO_8601;
extern NSInteger const RiistaCalendarStartMonth;

typedef void(^RiistaOperationCompletion)(BOOL wasSuccess);
typedef void(^RiistaDiaryEntryUploadCompletion)(NSArray *updates, NSError *error);
typedef void(^RiistaDiaryEntryEditCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaDiaryEntryDeleteCompletion)(NSError *error);
typedef void(^RiistaSynchronizationCompletion)(void);
typedef void(^DiaryImageSubmitCompletion)(BOOL errors);
typedef void(^RiistaUserImageLoadCompletion)(NSArray *images, NSUInteger currentIndex);

@interface RiistaGameDatabase : NSObject

@property (strong, nonatomic, readonly) NSDictionary *categories;
@property (strong, nonatomic, readonly) NSDictionary *species;

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
- (void)editLocalEvent:(DiaryEntry*)diaryEntry;

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

// Same as editDiaryEntry but for swift-world
- (void)synchronizeDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaOperationCompletion)completion;

/**
 * Edits single event on server
 * Update will be notified with notifications
 * @param diaryEntry DiaryEntry object
 * @param completion Completion block
 */
- (void)editDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryEditCompletion)completion;

// a helper for swift-world. Same as deleteDiaryEntry but with different completion block
- (void)deleteDiaryEntryCompat:(DiaryEntry*)diaryEntry completion:(RiistaOperationCompletion)completion;

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



@end
