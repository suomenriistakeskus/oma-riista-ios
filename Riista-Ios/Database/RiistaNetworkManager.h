#import <Foundation/Foundation.h>
#import <MKNetworkKit/MKNetworkEngine.h>

extern NSString *const RiistaLoginPath;
extern NSString *const RiistaMobileClient;
extern NSInteger const LOGIN_NETWORK_UNREACHABLE;
extern NSInteger const LOGIN_TIMEOUT;
extern NSInteger const LOGIN_INCORRECT_CREDENTIALS;
extern NSInteger const LOGIN_OUTDATED_VERSION;

extern NSString *const RiistaReloginFailedKey;
extern NSString *const RiistaLoginDomain;

@class DiaryEntry;
@class DiaryImage;
@class ObservationEntry;
@class SrvaEntry;

typedef void(^RiistaLoginCompletionBlock)(NSError *error);
typedef void(^RiistaDiaryEntryYearsCompletionBlock)(NSArray* years, NSError *error);
typedef void(^RiistaYearUpdateCheckCompletionBlock)(BOOL updates, NSError *error);
typedef void(^RiistaDiaryEntryFetchCompletion)(NSArray *entries, NSError *error);
typedef void(^RiistaDiaryEntrySendCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaDiaryEntryImageDownloadCompletion)(UIImage *image, NSError *error);
typedef void(^RiistaDiaryEntryImageOperationCompletion)(NSError *error);
typedef void(^RiistaPermitPreloadCompletion)(NSData *permits, NSError *error);
typedef void(^RiistaPermitCheckNumberCompletion)(NSDictionary *permit, NSError *error);

typedef void(^RiistaDiaryObservationFetchCompletion)(NSArray *entries, NSError *error);
typedef void(^RiistaDiaryObservationSendCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaDiaryObservationMetaCompletion)(NSData *metadata, NSError *error);
typedef void(^RiistaDiaryObservationImageOperationCompletion)(NSError *error);

typedef void(^RiistaDiarySrvaFetchCompletion)(NSArray *entries, NSError *error);
typedef void(^RiistaDiarySrvaMetaCompletion)(NSData *metadata, NSError *error);
typedef void(^RiistaDiarySrvaSendCompletion)(NSDictionary *response, NSError *error);

typedef void(^RiistaAnnouncementsListCompletion)(NSArray *items, NSError *error);

@interface RiistaNetworkOperation : MKNetworkOperation

@end

@interface RiistaNetworkManager : NSObject

@property (strong, nonatomic) MKNetworkEngine *networkEngine;
@property (strong, nonatomic) MKNetworkEngine *imageNetworkEngine;

+ (RiistaNetworkManager*)sharedInstance;

- (void)login:(NSString*)username password:(NSString*)password completion:(RiistaLoginCompletionBlock)completion;

/**
 * Login wrapper that adds notifications for unsuccessful login attempts with wrong credentials
 * @param username
 * @param password
 * @param completion Completion block
 */
- (void)relogin:(NSString*)username password:(NSString*)password completion:(RiistaLoginCompletionBlock)completion;

/**
 * Fetch user announcements
 * @param completion Completion block
 */
- (void)listAnnouncements:(RiistaAnnouncementsListCompletion)completion;

/**
 * Get list of permits associated with user
 * @param completion Completion block
 */
- (void)preloadPermits:(RiistaPermitPreloadCompletion)completion;

/**
 * Get permit details for permit number.
 * Error if number not found
 * @param permitNumber Permit identifier
 * @param completion Completion block
 */
- (void)checkPermitNumber:(NSString*)permitNumber completion:(RiistaPermitCheckNumberCompletion)completion;

/**
 * Fetch diary entry years from server
 * @param retry Relogin and retry if there is no session
 * @param completion Completion block
 */
- (void)diaryEntryYears:(BOOL)retry completion:(RiistaDiaryEntryYearsCompletionBlock)completion;

/**
 * Check if there are updates for given year
 * @param year
 * @param lastFetch last time entries were fetched
 * @param completion Completion block
 */
- (void)updatesForYear:(NSInteger)year lastFetch:(NSDate*)fetchDate completion:(RiistaYearUpdateCheckCompletionBlock)completion;

/**
 * Fetches diary entries for given year
 * @param year
 * @param context Managed object context
 * @param completion Completion block
 */
- (void)diaryEntriesForYear:(NSInteger)year context:(NSManagedObjectContext*)context completion:(RiistaDiaryEntryFetchCompletion)completion;

/**
 * Sends given diary entry to server
 * @param diaryEntry
 * @param completion Completion block
 */
- (void)sendDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntrySendCompletion)completion;

/**
 * Loads remote image from server
 * @param uuid Image uuid
 * @param completion Completion block
 */
- (void)loadDiaryEntryImage:(NSString*)uuid completion:(RiistaDiaryEntryImageDownloadCompletion)completion;

/**
 * Completes insert/deletion operations for images having such status
 * @param image DiaryImage object
 * @param diaryEntry DiaryEntry object
 * @param completion Completion block
 */
- (void)diaryEntryImageOperationForImage:(DiaryImage*)image diaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryImageOperationCompletion)completion;

#pragma mark - Observations

/**
 * Get observation metadata
 * @param completion Completion block
 */
- (void)preloadObservationMeta:(RiistaDiaryObservationMetaCompletion)completion;

/**
 * Fetches diary observations for given year
 * @param year
 * @param completion Completion block
 */
- (void)diaryObservationsForYear:(NSInteger)year completion:(RiistaDiaryObservationFetchCompletion)completion;

/**
 * Sends given diary observation to server
 * @param diaryEntry
 * @param completion Completion block
 */
- (void)sendDiaryObservation:(ObservationEntry*)diaryObservation completion:(RiistaDiaryObservationSendCompletion)completion;

/**
 * Completes insert/deletion operations for images having such status
 * @param image DiaryImage object
 * @param diaryEntry DiaryEntry object
 * @param completion Completion block
 */
- (void)diaryObservationImageOperationForImage:(DiaryImage*)image observationEntry:(ObservationEntry*)observationEntry completion:(RiistaDiaryObservationImageOperationCompletion)completion;

#pragma mark - Srva

/**
 * Fetches all SRVA entries
 * @param completion Completion block
 */
- (void)srvaEntries:(RiistaDiarySrvaFetchCompletion)completion;

/**
 * Get Srva metadata
 * @param completion Completion block
 */
- (void)preloadSrvaMeta:(RiistaDiarySrvaMetaCompletion)completion;

/**
 * Sends given diary SRVA to server
 * @param diaryEntry
 * @param completion Completion block
 */
- (void)sendDiarySrva:(SrvaEntry*)diarySrva completion:(RiistaDiarySrvaSendCompletion)completion;

/**
 * Completes insert/deletion operations for images having such status
 * @param image DiaryImage object
 * @param srvaEntry SrvaEntry object
 * @param completion Completion block
 */
- (void)diarySrvaImageOperationForImage:(DiaryImage*)image srvaEntry:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryImageOperationCompletion)completion;

@end
