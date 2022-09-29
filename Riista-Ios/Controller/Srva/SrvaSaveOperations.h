#import <Foundation/Foundation.h>

@class SrvaEntry;
@class DiaryEntryBase;

typedef void(^RiistaDiaryEntryEditCompletion)(NSDictionary *response, NSError *error);
typedef void(^RiistaNavigateToLog)(void);

@interface SrvaSaveOperations : NSObject

+ (SrvaSaveOperations*)sharedInstance;

- (void)saveEditSrva:(SrvaEntry*)srvaEntry newImages:(NSArray*)newImages moContext:(NSManagedObjectContext*)moContext presentViewController:(UIViewController *)viewControllerToPresent navigateToLog:(RiistaNavigateToLog)navigateToLog;
- (void)showEditError:(NSError*)error presentViewController:(UIViewController *)viewControllerToPresent;
- (void)navigateToDiaryLog:(RiistaNavigateToLog)navigateToLog;
- (void)saveNewSrv:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryEditCompletion)completion;
- (void)deleteSrva:(SrvaEntry*)srvaEntry;

- (void)doDeleteSrvaNow:(SrvaEntry*)srvaEntry;
- (BOOL)doDeleteSrvaIfLocalOnly:(SrvaEntry*)srvaEntry;
- (void)doDeleteLocalEntry:(DiaryEntryBase*)entry;

@end
