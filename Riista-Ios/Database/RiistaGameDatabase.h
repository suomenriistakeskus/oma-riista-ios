#import <Foundation/Foundation.h>

@class DiaryEntry;
@class DiaryImage;
@class ObservationEntry;
@class RiistaSpecies;
@class RiistaDiaryEntryUpdate;
@class SeasonStats;
@class RiistaCommonSynchronizationLevel;
@class RiistaCommonSynchronizationConfig;

extern NSString *const RiistaCalendarEntriesUpdatedKey;
extern NSString *const ISO_8601;
extern NSInteger const RiistaCalendarStartMonth;

typedef void(^RiistaSynchronizationCompletion)(void);

@interface RiistaGameDatabase : NSObject

@property (strong, nonatomic, readonly) NSDictionary *categories;
@property (strong, nonatomic, readonly) NSDictionary *species;

// Is the data currently being synchronized?
@property (assign, atomic, readonly) BOOL synchronizing;

+ (RiistaGameDatabase*)sharedInstance;

- (void)initUserSession;


/**
 * Gets list of species with given category id
 */
- (NSArray*)speciesListWithCategoryId:(NSInteger)categoryId;

/**
 * Looks for species with given id
 */
- (RiistaSpecies*)speciesById:(NSInteger)speciesId;

/**
 * Fetches latest diary entries from server and sends unsent diary entries
 * Updates will be notified with notifications
 * @param completion Completion block
 */
- (void)synchronizeDiaryEntries:(RiistaCommonSynchronizationLevel * _Nonnull)synchronizationLevel
          synchronizationConfig:(RiistaCommonSynchronizationConfig * _Nonnull)synchronizationConfig
                     completion:(RiistaSynchronizationCompletion _Nullable)completion;


@end
