#import "SrvaSaveOperations.h"
#import "SrvaEntry.h"
#import "RiistaGameDatabase.h"
#import "RiistaLocalization.h"
#import "RiistaSettings.h"
#import "RiistaAppDelegate.h"
#import "Oma_riista-Swift.h"

@implementation SrvaSaveOperations
{
}

+ (SrvaSaveOperations*)sharedInstance
{
    static SrvaSaveOperations *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [SrvaSaveOperations new];
    });
    return pInst;
}

- (void)dealloc
{
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)saveEditSrva:(SrvaEntry*)srvaEntry newImages:(NSArray*)newImages moContext:(NSManagedObjectContext*)moContext presentViewController:(UIViewController *)presentViewController navigateToLog:(RiistaNavigateToLog)navigateToLog
{
    [moContext refreshObject:srvaEntry mergeChanges:YES];
    if (srvaEntry.isDeleted) {
        //Entry has been deleted from persistent storage, can't really do anything.
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:0 userInfo:nil];
        [self showEditError:error presentViewController:presentViewController];
        return;
    }

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        [[RiistaGameDatabase sharedInstance] editLocalSrva:srvaEntry newImages:newImages];

        __weak SrvaSaveOperations *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editSrvaEntry:srvaEntry completion:^(NSDictionary *response, NSError *error) {
            if (weakSelf) {
                [weakSelf navigateToDiaryLog:navigateToLog];
            }
        }];
    }
    else {
        [[RiistaGameDatabase sharedInstance] editLocalSrva:srvaEntry newImages:newImages];
        [self navigateToDiaryLog:navigateToLog];
    }
}

- (void)showEditError:(NSError*)error presentViewController:(UIViewController *)presentViewController
{
    MDCAlertController *alert = [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"Error", nil)
                                                                     message:error.code == 409 ? RiistaLocalizedString(@"OutdatedDiaryEntry", nil) : RiistaLocalizedString(@"DiaryEditFailed", nil)];
    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                       handler:^(MDCAlertAction * _Nonnull action) {
        // Do nothing
    }];

    [alert addAction:okAction];

    [presentViewController presentViewController:alert animated:YES completion:nil];
}

-(void)navigateToDiaryLog:(RiistaNavigateToLog)navigateToLog
{
    navigateToLog();
}

- (void)saveNewSrv:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryEditCompletion)completion
{
    [[RiistaGameDatabase sharedInstance] addLocalSrva:srvaEntry];

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        [[RiistaGameDatabase sharedInstance] editSrvaEntry:srvaEntry completion:completion];
    }
    else {
        completion(nil, nil);
    }
}

- (void)deleteSrva:(SrvaEntry*)srvaEntry
{
    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        [self doDeleteSrvaNow:srvaEntry];
    }
    else {
        [[RiistaGameDatabase sharedInstance] deleteLocalSrva:srvaEntry];
        [self doDeleteSrvaIfLocalOnly:srvaEntry];
    }
}

- (void)doDeleteSrvaNow:(SrvaEntry*)srvaEntry
{
    [[RiistaGameDatabase sharedInstance] deleteLocalSrva:srvaEntry];

    __weak SrvaSaveOperations *weakSelf = self;

    // Just delete local copy if not sent to server yet
    if ([self doDeleteSrvaIfLocalOnly:srvaEntry]) {
        return;
    }

    [[RiistaGameDatabase sharedInstance] deleteSrvaEntry:srvaEntry completion:^(NSError *error) {
        if (weakSelf) {
            if (!error) {
                [weakSelf doDeleteLocalEntry:srvaEntry];
            }
        }
    }];
}

- (BOOL)doDeleteSrvaIfLocalOnly:(SrvaEntry*)srvaEntry
{
    if (srvaEntry.remoteId == nil) {
        [self doDeleteLocalEntry:srvaEntry];
        return YES;
    }
    return NO;
}

- (void)doDeleteLocalEntry:(DiaryEntryBase*)entry
{
    [entry.managedObjectContext performBlock:^(void) {
        [entry.managedObjectContext deleteObject:entry];
        [entry.managedObjectContext performBlock:^(void) {
            NSError *err;
            if ([entry.managedObjectContext save:&err]) {

                RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
                [delegate.managedObjectContext performBlock:^(void) {
                    NSError *Err;
                    [delegate.managedObjectContext save:&Err];
                }];
            }
        }];
    }];
}

@end
