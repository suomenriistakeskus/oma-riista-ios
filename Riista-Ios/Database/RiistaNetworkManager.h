#import <Foundation/Foundation.h>
#import <MKNetworkKit/MKNetworkEngine.h>

extern NSString *const RiistaMobileClient;
extern NSInteger const LOGIN_NETWORK_UNREACHABLE;
extern NSInteger const LOGIN_TIMEOUT;
extern NSInteger const LOGIN_INCORRECT_CREDENTIALS;
extern NSInteger const LOGIN_OUTDATED_VERSION;

// default timeout in seconds to be used in login
extern int const LOGIN_DEFAULT_TIMEOUT_SECONDS;

extern NSString *const RiistaReloginFailedKey;
extern NSString *const RiistaLoginDomain;


@class DiaryEntry;
@class DiaryImage;

typedef void(^RiistaLoginCompletionBlock)(NSError *error);
typedef void(^RiistaYearUpdateCheckCompletionBlock)(BOOL updates, NSError *error);
typedef void(^RiistaDiaryEntryFetchCompletion)(NSArray *entries, NSError *error);
typedef void(^RiistaDiaryEntrySendCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaDiaryEntryImageDownloadCompletion)(UIImage *image, NSError *error);
typedef void(^RiistaDiaryEntryImageOperationCompletion)(NSError *error);
typedef void(^RiistaPermitPreloadCompletion)(NSData *permits, NSError *error);
typedef void(^RiistaPermitCheckNumberCompletion)(NSDictionary *permit, NSError *error);

typedef void(^RiistaDiaryObservationFetchCompletion)(NSArray *entries, NSError *error);
typedef void(^RiistaDiaryObservationSendCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaDiaryObservationImageOperationCompletion)(NSError *error);

typedef void(^RiistaAnnouncementsListCompletion)(NSArray *items, NSError *error);

typedef void(^RiistaJsonArrayCompletion)(NSArray *items, NSError *error);
typedef void(^RiistaJsonCompletion)(NSDictionary *item, NSError *error);

@interface RiistaNetworkOperation : MKNetworkOperation

@end

@interface RiistaNetworkManager : NSObject

@property (strong, nonatomic) MKNetworkEngine *networkEngine;
@property (strong, nonatomic) MKNetworkEngine *imageNetworkEngine;

+ (RiistaNetworkManager*)sharedInstance;

+ (NSString*)getBaseApiPath;

- (void)login:(NSString*)username password:(NSString*)password timeoutSeconds:(int)timeoutSeconds completion:(RiistaLoginCompletionBlock)completion;

/**
 * Login wrapper that adds notifications for unsuccessful login attempts with wrong credentials
 * @param username
 * @param password
 * @param completion Completion block
 */
- (void)relogin:(NSString*)username password:(NSString*)password timeoutSeconds:(int)timeoutSeconds completion:(RiistaLoginCompletionBlock)completion;

/**
 * Send and register user Firebase notification token to the server.
 */
- (void)registerUserNotificationToken;

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
 * Loads remote image from server
 * @param uuid Image uuid
 * @param completion Completion block
 */
- (void)loadDiaryEntryImage:(NSString*)uuid completion:(RiistaDiaryEntryImageDownloadCompletion)completion;


- (void)clubAreaMaps:(RiistaJsonArrayCompletion)completion;

- (void)clubAreaMap:(NSString*) externalId completion:(RiistaJsonCompletion)completion;

- (void)listMooseAreaMaps:(RiistaJsonArrayCompletion)completion;
- (void)listPienriistaAreaMaps:(RiistaJsonArrayCompletion)completion;


@end
