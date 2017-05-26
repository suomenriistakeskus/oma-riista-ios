#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaSessionManager.h"
#import "RiistaSettings.h"
#import "DiaryEntry.h"
#import "DiaryImage.h"
#import "ObservationEntry.h"
#import "RiistaUtils.h"
#import "DataModels.h"
#import "RiistaPermitManager.h"
#import "RiistaMetadataManager.h"
#import "SrvaEntry.h"
#import "AnnouncementsSync.h"

NSString *const RiistaHostname = @"oma.riista.fi";

#define BASE_API_PATH @"api/mobile/v2/"

NSString *const RiistaLoginPath = @"login";
NSString *const RiistaAccountPath = BASE_API_PATH @"gamediary/account";
NSString *const RiistaYearUpdateCheckPath = @"api/mobile/v1/gamediary/entries/haschanges/%ld/%@";

NSString *const RiistaDiaryEntriesPath = BASE_API_PATH @"gamediary/harvests/%ld?harvestSpecVersion=%ld";
NSString *const RiistaDiaryEntryUpdatePath = BASE_API_PATH @"gamediary/harvest/%ld";
NSString *const RiistaDiaryEntryInsertPath = BASE_API_PATH @"gamediary/harvest";
NSString *const RiistaDiaryEntryDeletePath = BASE_API_PATH @"gamediary/harvest/%ld";
NSString *const RiistaDiaryImageUploadPath = BASE_API_PATH @"gamediary/image/uploadforharvest";

NSString *const RiistaObservationMetaPath = BASE_API_PATH @"gamediary/observation/metadata/%ld";
NSString *const RiistaDiaryObservationsPath = BASE_API_PATH @"gamediary/observations/%ld?observationSpecVersion=%ld";
NSString *const RiistaDiaryObservationUpdatePath = BASE_API_PATH @"gamediary/observation/%ld";
NSString *const RiistaDiaryObservationInsertPath = BASE_API_PATH @"gamediary/observation";
NSString *const RiistaDiaryObservationDeletePath = BASE_API_PATH @"gamediary/observation/%ld";
NSString *const RiistaDiaryObservationImageUploadPath = BASE_API_PATH @"gamediary/image/uploadforobservation";

NSString *const RiistaSrvaEventsPath = BASE_API_PATH @"srva/srvaevents?srvaEventSpecVersion=%ld";
NSString *const RiistaSrvaMetaPath = BASE_API_PATH @"srva/parameters?srvaEventSpecVersion=%ld";
NSString *const RiistaDiarySrvaUpdatePath = BASE_API_PATH @"srva/srvaevent/%ld";
NSString *const RiistaDiarySrvaInsertPath = BASE_API_PATH @"srva/srvaevent";
NSString *const RiistaDiarySrvaDeletePath = BASE_API_PATH @"srva/srvaevent/%ld";
NSString *const RiistaDiarySrvaImageUploadPath = BASE_API_PATH @"srva/image/upload";
NSString *const RiistaSrvaImageDeletePath = BASE_API_PATH @"srva/image/%@";

NSString *const RiistaDiaryImageLoadPath = BASE_API_PATH @"gamediary/image/%@";
NSString *const RiistaDiaryImageDeletePath = BASE_API_PATH @"gamediary/image/%@";
NSString *const RiistaPermitPreloadPath = BASE_API_PATH @"gamediary/preloadPermits";
NSString *const RiistaPermitCheckNumberPath = BASE_API_PATH @"gamediary/checkPermitNumber";

NSString *const RiistaListAnnouncementsPath = BASE_API_PATH @"announcement/list";

BOOL const UseSSL = YES;

NSString *const RiistaMobileClient = @"mobileapiv2";
NSInteger const LOGIN_NETWORK_UNREACHABLE = 0;
NSInteger const LOGIN_TIMEOUT = -1001;
NSInteger const LOGIN_INCORRECT_CREDENTIALS = 403;
NSInteger const LOGIN_OUTDATED_VERSION = 418;

NSString *const RiistaReloginFailedKey = @"reloginFailed";

NSString *const RiistaPlatformKey = @"platform";
NSString *const RiistaPlatformValue = @"ios";
NSString *const RiistaDeviceKey = @"device";
NSString *const RiistaClientVersionKey = @"mobileClientVersion";

NSString *const RiistaLoginDomain = @"RiistaLogin";

@implementation RiistaNetworkManager
{
    NSDateFormatter *dateFormatter;
}

- (id)init
{
    self = [super init];
    if (self) {
        _networkEngine = [[MKNetworkEngine alloc] initWithHostName:RiistaHostname customHeaderFields:@{RiistaPlatformKey: RiistaPlatformValue, RiistaDeviceKey: [[UIDevice currentDevice] systemVersion], RiistaClientVersionKey: [RiistaUtils appVersion]}];
        _imageNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:RiistaHostname customHeaderFields:@{RiistaPlatformKey: RiistaPlatformValue, RiistaDeviceKey: [[UIDevice currentDevice] systemVersion], RiistaClientVersionKey: [RiistaUtils appVersion]}];
        [_imageNetworkEngine useCache];
        [_networkEngine registerOperationSubclass:[RiistaNetworkOperation class]];
        dateFormatter = [NSDateFormatter new];
    }
    return self;
}

+ (RiistaNetworkManager*)sharedInstance
{
    static RiistaNetworkManager *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [RiistaNetworkManager new];
    });
    return pInst;
}

- (void)login:(NSString*)username password:(NSString*)password completion:(RiistaLoginCompletionBlock)completion
{
    MKNetworkOperation *loginOperation = [self.networkEngine operationWithPath:RiistaLoginPath params:@{} httpMethod:@"POST" ssl:UseSSL];
    [loginOperation setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDatadict) {
        return [NSString stringWithFormat:@"username=%@&password=%@&client=%@",
                [RiistaUtils encodeToPercentEscapedString:username],
                [RiistaUtils encodeToPercentEscapedString:password],
                [RiistaUtils encodeToPercentEscapedString:RiistaMobileClient]];
    } forType:@"application/x-www-form-urlencoded"];
    [loginOperation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        [[RiistaSessionManager sharedInstance] storeUserLogin];

        [self saveUserInfo:[completedOperation responseJSON]];
        [[RiistaPermitManager sharedInstance] preloadPermits:nil];
        [[RiistaMetadataManager sharedInstance] fetchAll];

        if (completion)
            completion(nil);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
    [self.networkEngine enqueueOperation:loginOperation];
}

- (void)saveUserInfo:(NSDictionary*)responseJSON
{
    UserInfo *user = [UserInfo modelObjectWithDictionary:responseJSON];
    [RiistaSettings setUserInfo:user];
}

- (void)relogin:(NSString*)username password:(NSString*)password completion:(RiistaLoginCompletionBlock)completion
{
    [self login:username password:password completion:^(NSError* error) {
        if (error && (error.code == 401 || error.code == 403)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RiistaReloginFailedKey object:self];
        }
        completion(error);
    }];
}

- (void)listAnnouncements:(RiistaAnnouncementsListCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaListAnnouncementsPath params:@{} httpMethod:@"GET" ssl:UseSSL];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *items = [completedOperation responseJSON];
            completion(items, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)preloadPermits:(RiistaPermitPreloadCompletion)completion
{
    MKNetworkOperation *preloadPermitsOperation = [self.networkEngine operationWithPath:RiistaPermitPreloadPath params:@{} httpMethod:@"GET" ssl:UseSSL];
    [preloadPermitsOperation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion([completedOperation responseData], nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:preloadPermitsOperation];
}

- (void)checkPermitNumber:(NSString*)permitNumber completion:(RiistaPermitCheckNumberCompletion)completion
{
    MKNetworkOperation *checkPermitOperation = [self.networkEngine operationWithPath:RiistaPermitCheckNumberPath params:@{} httpMethod:@"POST" ssl:UseSSL];
    [checkPermitOperation setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
        return [NSString stringWithFormat:@"permitNumber=%@", permitNumber];
    } forType:@"application/x-www-form-urlencoded"];
    [checkPermitOperation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion([completedOperation responseJSON], nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:checkPermitOperation];
}

- (void)diaryEntryYears:(BOOL)retry completion:(RiistaDiaryEntryYearsCompletionBlock)completion
{
    __weak RiistaNetworkManager *weakSelf = self;
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaAccountPath params:@{} httpMethod:@"GET" ssl:UseSSL];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSDictionary *accountData = [completedOperation responseJSON];

        [self saveUserInfo:accountData];

        if (completion) {
            completion(accountData[@"gameDiaryYears"], nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            if (retry) {
                RiistaCredentials *credentials = [[RiistaSessionManager sharedInstance] userCredentials];
                if (credentials) {
                    [weakSelf relogin:credentials.username password:credentials.password completion:^(NSError *error) {
                        if (!error) {
                            [weakSelf diaryEntryYears:NO completion:completion];
                        } else if (completion) {
                            completion(nil, error);
                        }
                    }];
                } else {
                    // Credentials were not available
                    NSError *error = [NSError errorWithDomain:RiistaLoginDomain code:0 userInfo:nil];
                    completion(nil, error);
                }
            } else if (completion) {
                completion(nil, error);
            }
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)updatesForYear:(NSInteger)year lastFetch:(NSDate*)fetchDate completion:(RiistaYearUpdateCheckCompletionBlock)completion
{
    if (fetchDate == nil) {
        // Always continue fetching if there is no previous fetch date
        completion(YES, nil);
        return;
    }
    
    [dateFormatter setDateFormat:ISO_8601];
    NSString *dateString = [dateFormatter stringFromDate:fetchDate];

    MKNetworkOperation *operation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaYearUpdateCheckPath, (long)year, dateString] params:@{} httpMethod:@"GET" ssl:UseSSL];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSError *err = nil;
            BOOL response = (BOOL)[NSJSONSerialization JSONObjectWithData:completedOperation.responseData options:NSJSONReadingAllowFragments error:&err];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)diaryEntriesForYear:(NSInteger)year context:(NSManagedObjectContext*)context completion:(RiistaDiaryEntryFetchCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryEntriesPath, (long)year, HarvestSpecVersion] params:@{} httpMethod:@"GET" ssl:UseSSL];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSArray *entries = [completedOperation responseJSON];
        if (completion) {
            completion(entries, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)sendDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntrySendCompletion)completion
{
    NSString *path = @"";
    NSString *httpMethod = @"POST";
    if ([diaryEntry.pendingOperation isEqualToNumber:[NSNumber numberWithInteger:DiaryEntryOperationDelete]]) {
        [self deleteDiaryEntry:diaryEntry completion:completion];
        return;
    } else if ([diaryEntry.remote boolValue]) {
        path = [NSString stringWithFormat:RiistaDiaryEntryUpdatePath, [diaryEntry.remoteId longValue]];
        httpMethod = @"PUT";
    } else {
        path = RiistaDiaryEntryInsertPath;
    }
    
    NSDictionary *diaryEntryDict = [[RiistaGameDatabase sharedInstance] dictFromDiaryEntry:diaryEntry isNew:![diaryEntry.remote boolValue]];
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:diaryEntryDict httpMethod:httpMethod ssl:UseSSL];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(completedOperation.responseJSON, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)deleteDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntrySendCompletion)completion
{
    NSString *path = [NSString stringWithFormat:RiistaDiaryEntryDeletePath, [diaryEntry.remoteId longValue]];
    NSString *httpMethod = @"DELETE";

    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:nil httpMethod:httpMethod ssl:UseSSL];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            // Trying to delete entry which does not exist on server is treated as successfull operation
            if (error.code == 404) {
                completion(nil, nil);
            }
            else {
                completion(nil, error);
            }
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)loadDiaryEntryImage:(NSString*)uuid completion:(RiistaDiaryEntryImageDownloadCompletion)completion
{
    NSString *lowercaseUuid = [uuid lowercaseString];
    MKNetworkOperation *operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageLoadPath, lowercaseUuid] params:@{} httpMethod:@"GET" ssl:UseSSL];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(completedOperation.responseImage, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.imageNetworkEngine enqueueOperation:operation];
}

- (void)diaryEntryImageOperationForImage:(DiaryImage*)image diaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryImageOperationCompletion)completion
{
    MKNetworkOperation *operation;
    if ([image.status integerValue] == DiaryImageStatusInsertion) {
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageUploadPath] params:@{@"harvestId": diaryEntry.remoteId,
                                                                                                                               @"uuid": image.imageid} httpMethod:@"POST" ssl:UseSSL];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        NSString *lowercaseUuid = [image.imageid lowercaseString];
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageDeletePath, lowercaseUuid] params:@{} httpMethod:@"DELETE" ssl:UseSSL];
    }
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
    
    if ([image.status integerValue] == DiaryImageStatusInsertion) {
        [RiistaUtils loadImagefromLocalUri:image.uri fullSize:YES fixRotation:YES completion:^(UIImage *image) {
        if (image) {
            NSData *imageData = [RiistaUtils imageAsDownscaledData:image];
            [operation addData:imageData forKey:@"file" mimeType:@"image/jpeg" fileName:@"image.jpeg"];
            [self.networkEngine enqueueOperation:operation];
        } else {
            NSError *error = [NSError errorWithDomain:@"image" code:0 userInfo:nil];
            completion(error);
        }
    }];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        [self.networkEngine enqueueOperation:operation];
    } else {
        completion(nil);
    }
}

#pragma mark - Observations

- (void)preloadObservationMeta:(RiistaDiaryObservationMetaCompletion)completion
{
    MKNetworkOperation *preloadMetaOperation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaObservationMetaPath, ObservationSpecVersion] params:@{} httpMethod:@"GET" ssl:UseSSL];
    [preloadMetaOperation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion([completedOperation responseData], nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:preloadMetaOperation];
}

- (void)diaryObservationsForYear:(NSInteger)year completion:(RiistaDiaryObservationFetchCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryObservationsPath, (long)year, ObservationSpecVersion] params:@{} httpMethod:@"GET" ssl:UseSSL];
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSArray *entries = [completedOperation responseJSON];
        if (completion) {
            completion(entries, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)sendDiaryObservation:(ObservationEntry*)observationEntry completion:(RiistaDiaryObservationSendCompletion)completion
{
    NSString *path = @"";
    NSString *httpMethod = @"POST";
    if ([observationEntry.pendingOperation isEqualToNumber:[NSNumber numberWithInteger:DiaryEntryOperationDelete]]) {
        [self deleteDiaryObservation:observationEntry completion:completion];
        return;
    } else if ([observationEntry.remote boolValue]) {
        path = [NSString stringWithFormat:RiistaDiaryObservationUpdatePath, [observationEntry.remoteId longValue]];
        httpMethod = @"PUT";
    } else {
        path = RiistaDiaryObservationInsertPath;
    }

    NSDictionary *diaryEntryDict = [[RiistaGameDatabase sharedInstance] dictFromObservationEntry:observationEntry isNew:![observationEntry.remote boolValue]];
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:diaryEntryDict httpMethod:httpMethod ssl:UseSSL];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(completedOperation.responseJSON, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)deleteDiaryObservation:(ObservationEntry*)observationEntry completion:(RiistaDiaryObservationSendCompletion)completion
{
    NSString *path = [NSString stringWithFormat:RiistaDiaryObservationDeletePath, [observationEntry.remoteId longValue]];
    NSString *httpMethod = @"DELETE";

    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:nil httpMethod:httpMethod ssl:UseSSL];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            // Trying to delete entry which does not exist on server is treated as successfull operation
            if (error.code == 404) {
                completion(nil, nil);
            }
            else {
                completion(nil, error);
            }
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)diaryObservationImageOperationForImage:(DiaryImage*)image observationEntry:(ObservationEntry*)observationEntry completion:(RiistaDiaryObservationImageOperationCompletion)completion
{
    MKNetworkOperation *operation;
    if ([image.status integerValue] == DiaryImageStatusInsertion) {
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryObservationImageUploadPath]
                                                        params:@{@"observationId": observationEntry.remoteId, @"uuid": image.imageid}
                                                    httpMethod:@"POST" ssl:UseSSL];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        NSString *lowercaseUuid = [image.imageid lowercaseString];
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageDeletePath, lowercaseUuid] params:@{} httpMethod:@"DELETE" ssl:UseSSL];
    }
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];

    if ([image.status integerValue] == DiaryImageStatusInsertion) {
        [RiistaUtils loadImagefromLocalUri:image.uri fullSize:YES fixRotation:YES completion:^(UIImage *image) {
            if (image) {
                NSData *imageData = [RiistaUtils imageAsDownscaledData:image];
                [operation addData:imageData forKey:@"file" mimeType:@"image/jpeg" fileName:@"image.jpeg"];
                [self.networkEngine enqueueOperation:operation];
            } else {
                NSError *error = [NSError errorWithDomain:@"image" code:0 userInfo:nil];
                completion(error);
            }
        }];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        [self.networkEngine enqueueOperation:operation];
    } else {
        completion(nil);
    }
}

- (void)srvaEntries:(RiistaDiarySrvaFetchCompletion)completion
{
    NSString *path = [NSString stringWithFormat:RiistaSrvaEventsPath, SrvaSpecVersion];
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:@{} httpMethod:@"GET" ssl:UseSSL];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *entries = [completedOperation responseJSON];
            completion(entries, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)preloadSrvaMeta:(RiistaDiarySrvaMetaCompletion)completion
{
    MKNetworkOperation *preloadMetaOperation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaSrvaMetaPath, SrvaSpecVersion] params:@{} httpMethod:@"GET" ssl:UseSSL];
    [preloadMetaOperation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion([completedOperation responseData], nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:preloadMetaOperation];
}

- (void)sendDiarySrva:(SrvaEntry*)diarySrva completion:(RiistaDiarySrvaSendCompletion)completion
{
    NSString *path = @"";
    NSString *httpMethod = @"POST";
    if ([diarySrva.pendingOperation isEqualToNumber:[NSNumber numberWithInteger:DiaryEntryOperationDelete]]) {
        [self deleteDiarySrva:diarySrva completion:completion];
        return;
    } else if (diarySrva.remoteId != nil) {
        path = [NSString stringWithFormat:RiistaDiarySrvaUpdatePath, [diarySrva.remoteId longValue]];
        httpMethod = @"PUT";
    } else {
        path = RiistaDiarySrvaInsertPath;
    }

    NSDictionary *diaryEntryDict = [[RiistaGameDatabase sharedInstance] dictFromSrvaEntry:diarySrva isNew:diarySrva.remoteId == nil];
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:diaryEntryDict httpMethod:httpMethod ssl:UseSSL];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(completedOperation.responseJSON, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)deleteDiarySrva:(SrvaEntry*)srvaEntry completion:(RiistaDiarySrvaSendCompletion)completion
{
    NSString *path = [NSString stringWithFormat:RiistaDiarySrvaDeletePath, [srvaEntry.remoteId longValue]];
    NSString *httpMethod = @"DELETE";

    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:nil httpMethod:httpMethod ssl:UseSSL];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            // Trying to delete entry which does not exist on server is treated as successfull operation
            if (error.code == 404) {
                completion(nil, nil);
            }
            else {
                completion(nil, error);
            }
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)diarySrvaImageOperationForImage:(DiaryImage*)image srvaEntry:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryImageOperationCompletion)completion
{
    MKNetworkOperation *operation;
    if ([image.status integerValue] == DiaryImageStatusInsertion) {
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiarySrvaImageUploadPath]
                                                        params:@{@"srvaEventId": srvaEntry.remoteId, @"uuid": image.imageid}
                                                    httpMethod:@"POST" ssl:UseSSL];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        NSString *lowercaseUuid = [image.imageid lowercaseString];
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaSrvaImageDeletePath, lowercaseUuid] params:@{} httpMethod:@"DELETE" ssl:UseSSL];
    }
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];

    if ([image.status integerValue] == DiaryImageStatusInsertion) {
        [RiistaUtils loadImagefromLocalUri:image.uri fullSize:YES fixRotation:YES completion:^(UIImage *image) {
            if (image) {
                NSData *imageData = [RiistaUtils imageAsDownscaledData:image];
                [operation addData:imageData forKey:@"file" mimeType:@"image/jpeg" fileName:@"image.jpeg"];
                [self.networkEngine enqueueOperation:operation];
            } else {
                NSError *error = [NSError errorWithDomain:@"image" code:0 userInfo:nil];
                completion(error);
            }
        }];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        [self.networkEngine enqueueOperation:operation];
    } else {
        completion(nil);
    }
}

@end

@implementation RiistaNetworkOperation

- (NSURLRequest *)connection: (NSURLConnection*)inConnection
             willSendRequest: (NSURLRequest*)inRequest
            redirectResponse: (NSURLResponse*)inRedirectResponse;
{
    if (inRedirectResponse) {
        NSMutableURLRequest *r = [[self readonlyRequest] mutableCopy];
        // MKNetworkkit doesn't change from POST to GET, do it manually
        if ([(NSHTTPURLResponse*)inRedirectResponse statusCode] == 302) {
            [r setHTTPBody:nil];
            [r setHTTPMethod:@"GET"];
        }
        [r setURL: [inRequest URL]];
        return r;
    } else {
        return inRequest;
    }
}

@end
