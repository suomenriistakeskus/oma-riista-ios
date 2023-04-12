#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaSessionManager.h"
#import "RiistaSettings.h"
#import "DiaryEntry.h"
#import "DiaryImage.h"
#import "RiistaUtils.h"
#import "DataModels.h"
#import "RiistaPermitManager.h"
#import "AnnouncementsSync.h"
#import "NSDateformatter+Locale.h"
#import "RiistaCommon/RiistaCommon.h"

#import "Oma_riista-Swift.h"

@import Firebase;

#define BASE_API_PATH @"api/mobile/v2/"

NSString *const RiistaRegisterPushTokenPath = BASE_API_PATH @"push/register";
NSString *const RiistaAccountPath = BASE_API_PATH @"gamediary/account";
NSString *const RiistaYearUpdateCheckPath = @"api/mobile/v1/gamediary/entries/haschanges/%ld/%@";

NSString *const RiistaDiaryEntriesPath = BASE_API_PATH @"gamediary/harvests/%ld?harvestSpecVersion=%ld";
NSString *const RiistaDiaryEntryUpdatePath = BASE_API_PATH @"gamediary/harvest/%ld";
NSString *const RiistaDiaryEntryInsertPath = BASE_API_PATH @"gamediary/harvest";
NSString *const RiistaDiaryEntryDeletePath = BASE_API_PATH @"gamediary/harvest/%ld";
NSString *const RiistaDiaryImageUploadPath = BASE_API_PATH @"gamediary/image/uploadforharvest";

NSString *const RiistaDiaryImageLoadPath = BASE_API_PATH @"gamediary/image/%@";
NSString *const RiistaDiaryImageDeletePath = BASE_API_PATH @"gamediary/image/%@";
NSString *const RiistaPermitPreloadPath = BASE_API_PATH @"gamediary/preloadPermits";
NSString *const RiistaPermitCheckNumberPath = BASE_API_PATH @"gamediary/checkPermitNumber";

NSString *const RiistaListMhPermitsPath = BASE_API_PATH @"permit/mh";
NSString *const RiistaListAnnouncementsPath = BASE_API_PATH @"announcement/list";

NSString *const RiistaClubAreaMapsPath = BASE_API_PATH @"area/club";
NSString *const RiistaClubAreaMapPath = BASE_API_PATH @"area/code/%@";

NSString *const RiistaMooseAreaMapsPath = BASE_API_PATH @"area/mh/hirvi";
NSString *const RiistaPienriistaAreaMapsPath = BASE_API_PATH @"area/mh/pienriista";

NSString *const RiistaShootingTestCalendarEventsPath = BASE_API_PATH @"shootingtest/calendarevents";
NSString *const RiistaShootingTestCalendarEventPath = BASE_API_PATH @"shootingtest/calendarevent/%ld";

BOOL const UseSSL = YES;

NSString *const RiistaMobileClient = @"mobileapiv2";
NSInteger const LOGIN_NETWORK_UNREACHABLE = 0;
NSInteger const LOGIN_TIMEOUT = -1001;
NSInteger const LOGIN_INCORRECT_CREDENTIALS = 403;
NSInteger const LOGIN_OUTDATED_VERSION = 418;
int const LOGIN_DEFAULT_TIMEOUT_SECONDS = 60;

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
        _networkEngine = [[MKNetworkEngine alloc] initWithHostName:Environment.apiHostName customHeaderFields:@{RiistaPlatformKey: RiistaPlatformValue, RiistaDeviceKey: [[UIDevice currentDevice] systemVersion], RiistaClientVersionKey: [RiistaUtils appVersion]}];
        _imageNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:Environment.apiHostName customHeaderFields:@{RiistaPlatformKey: RiistaPlatformValue, RiistaDeviceKey: [[UIDevice currentDevice] systemVersion], RiistaClientVersionKey: [RiistaUtils appVersion]}];
        [_imageNetworkEngine useCache];
        [_networkEngine registerOperationSubclass:[RiistaNetworkOperation class]];
        dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
        [dateFormatter setDateFormat:ISO_8601];
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

+ (NSString*)getBaseApiPath
{
    return [NSString stringWithFormat:@"%@/%@", Environment.apiHostName, BASE_API_PATH];
}

- (void)login:(NSString*)username password:(NSString*)password timeoutSeconds:(int)timeoutSeconds completion:(RiistaLoginCompletionBlock)completion
{
    [CrashlyticsHelper logWithMsg:@"Logging in using RiistaSDK"];

    LoginAnalytics *analytics = [LoginAnalytics forRiistaSdk];
    [analytics sendLoginBegin];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [[RiistaCommonRiistaSDK riistaSDK] loginUsername:username
                                            password:password
                                      timeoutSeconds:timeoutSeconds
                                   completionHandler:^(RiistaCommonNetworkResponse<RiistaCommonUserInfoDTO *> * _Nullable response, NSError * _Nullable error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        if (error != nil) {
            [analytics sendLoginFailureWithStatusCode:-1];
            [CrashlyticsHelper sendErrorWithDomain:@"RiistaSDKLogin" code:-1 data:nil error:error];
            return;
        }

        [response onSuccessHandler:^(RiistaCommonInt * _Nonnull statusCode, RiistaCommonNetworkResponseData<RiistaCommonUserInfoDTO *> * _Nonnull data) {
            [analytics sendLoginSuccessWithStatusCode:statusCode.intValue];
            [CrashlyticsHelper logWithMsg:@"Login using RiistaSDK succeeded"];

            // copy authentication cookies so that further network requests made by MKNetworkKit
            // have a change of succeeding
            [RiistaSDKHelper copyAuthenticationCookiesFromRiistaSDK];

            id userInfo = [JSONUtils parseString:data.raw];
            [self onLoginSucceeded:userInfo completion:completion];
        }];

        [response onErrorHandler:^(RiistaCommonInt * _Nullable statusCode, RiistaCommonKotlinThrowable * _Nullable exception) {
            NSInteger errorCode = statusCode != nil ? [statusCode integerValue] : 0;
            [analytics sendLoginFailureWithStatusCode:statusCode.intValue];
            [CrashlyticsHelper logWithMsg:@"Login using RiistaSDK failed"];

            if (exception != nil) {
                [CrashlyticsHelper logWithMsg:exception.message];
            }
            [CrashlyticsHelper sendErrorWithDomain:@"RiistaSDKLogin" code:statusCode.intValue data:nil];

            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:errorCode userInfo:nil];
            if (completion) {
                completion(error);
            }
        }];
    }];
}

- (void)onLoginSucceeded:(NSDictionary*)userInfo completion:(RiistaLoginCompletionBlock)completion
{
    [[RiistaSessionManager sharedInstance] storeUserLogin];
    [[UserSession shared] checkHuntingDirectorAvailabilityWithCompletionHandler:nil];
    [[UserSession shared] checkHuntingControlAvailabilityWithRefresh:YES completionHandler:nil];

    [self saveUserInfo:userInfo];
    [[RiistaPermitManager sharedInstance] preloadPermits:nil];
    [self registerUserNotificationToken];

    if (completion) {
        completion(nil);
    }

}

- (void)saveUserInfo:(NSDictionary*)responseJSON
{
    UserInfo *user = [UserInfo modelObjectWithDictionary:responseJSON];
    [RiistaSettings setUserInfo:user];
}

- (void)relogin:(NSString*)username password:(NSString*)password timeoutSeconds:(int)timeoutSeconds completion:(RiistaLoginCompletionBlock)completion
{
    [self login:username password:password timeoutSeconds:timeoutSeconds completion:^(NSError* error) {
        if (error && (error.code == 401 || error.code == 403)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RiistaReloginFailedKey object:self];
        }
        completion(error);
    }];
}

- (void)registerUserNotificationToken
{
    [[FIRMessaging messaging] tokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
      if (error != nil) {
          NSLog(@"Error fetching remote instance ID: %@", error);
      } else {
          NSLog(@"Remote instance ID token: %@", token);
          if (token) {
              NSDictionary *args = @{
                                     @"platform": @"IOS",
                                     @"pushToken": token,
                                     @"deviceName": [[UIDevice currentDevice] systemName],
                                     @"clientVersion": [RiistaUtils appVersion]
                                     };
              MKNetworkOperation *registerOperation = [self.networkEngine operationWithPath:RiistaRegisterPushTokenPath params:args httpMethod:@"POST" ssl:UseSSL];
              registerOperation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

              [registerOperation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
                  NSLog(@"Push token registration OK");
              } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
                  NSLog(@"Push token registration error: %@", error);
              }];
              [self.networkEngine enqueueOperation:registerOperation];
          }
      }
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

- (void)listMhPermits:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaListMhPermitsPath params:@{} httpMethod:@"GET" ssl:UseSSL];
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
                    [weakSelf relogin:credentials.username
                             password:credentials.password
                       timeoutSeconds:LOGIN_DEFAULT_TIMEOUT_SECONDS
                           completion:^(NSError *error) {
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

    NSString *dateString = [dateFormatter stringFromDate:fetchDate];

    MKNetworkOperation *operation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaYearUpdateCheckPath, (long)year, dateString]
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:UseSSL];
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
    long harvestSpecVersion = HarvestSpecVersion;

    MKNetworkOperation *operation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryEntriesPath, (long)year, (long)harvestSpecVersion]
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:UseSSL];
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

    // Make sure the harvest contains valid data. iOS version 2.4.1.1 had a bug where new antler fields (e.g. antlersGirst) were
    // initialized with value of 0 in core data (should've been nil). Sanitizing harvest clears these values and thus sending
    // to backend should succeed.
    //
    // This should also fix sending some of the diary entries that were made with earlier app versions that had bugs.
    [HarvestSanitizer sanitizeWithHarvest:diaryEntry];

    NSDictionary *diaryEntryDict = [[RiistaGameDatabase sharedInstance] dictFromDiaryEntry:diaryEntry isNew:![diaryEntry.remote boolValue]];
    if (diaryEntryDict == nil) {
        [SynchronizationAnalytics sendFailedToSendHarvest: diaryEntry];

        // harvest is missing required data, don't send this one
        NSError *error = [NSError errorWithDomain:@"InvalidData" code:0 userInfo:nil];
        completion(nil, error);
        return;
    }
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:diaryEntryDict httpMethod:httpMethod ssl:UseSSL];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(completedOperation.responseJSON, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        [SynchronizationAnalytics sendFailedToSendHarvest: diaryEntry
                                               statusCode: error.code];
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
    if (uuid == nil) {
        // 22 i.e. just some value: this code will be replaced shortly (hopefully at least)
        NSError *error = [NSError errorWithDomain:@"InvalidData" code:22 userInfo:nil];
        completion(nil, error);
        return;
    }

    NSString *lowercaseUuid = [uuid lowercaseString];
    MKNetworkOperation *operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageLoadPath, lowercaseUuid]
                                                                        params:@{}
                                                                    httpMethod:@"GET"
                                                                           ssl:UseSSL];
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
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageUploadPath]
                                                        params:@{@"harvestId": diaryEntry.remoteId, @"uuid": image.imageid}
                                                    httpMethod:@"POST"
                                                           ssl:UseSSL];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        NSString *lowercaseUuid = [image.imageid lowercaseString];
        operation = [self.imageNetworkEngine operationWithPath:[NSString stringWithFormat:RiistaDiaryImageDeletePath, lowercaseUuid]
                                                        params:@{}
                                                    httpMethod:@"DELETE"
                                                           ssl:UseSSL];
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
        [self sendImage:image networkOperation:operation completion:completion];
    } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
        [self.networkEngine enqueueOperation:operation];
    } else {
        completion(nil);
    }
}

- (void)sendImage:(DiaryImage*)image networkOperation:(MKNetworkOperation*)networkOperation completion:(RiistaDiaryEntryImageOperationCompletion)completion
{
    ImageLoadOptions *options = [[[ImageLoadOptions originalSized]
                                  withFixRotation:YES]
                                 withDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    ImageLoadRequest *imageLoadRequest = [ImageLoadRequest fromDiaryImage:image options:options];
    if (imageLoadRequest == nil) {
        NSError *error = [NSError errorWithDomain:@"image" code:0 userInfo:nil];
        completion(error);
        return;
    }

    [[LocalImageManager instance] loadImage:imageLoadRequest
                                  onSuccess:^(IdentifiableImage * _Nonnull identifiableImage) {
        if (image) {
            NSData *imageData = [RiistaUtils imageAsDownscaledData:identifiableImage.image];
            [networkOperation addData:imageData forKey:@"file" mimeType:@"image/jpeg" fileName:@"image.jpeg"];
            [self.networkEngine enqueueOperation:networkOperation];
        } else {
            NSError *error = [NSError errorWithDomain:@"image" code:0 userInfo:nil];
            completion(error);
        }
    }
                                    onError:^(enum PhotoAccessFailureReason reason, ImageLoadRequest * _Nullable loadRequest) {
        NSError *error = [NSError errorWithDomain:@"image" code:0 userInfo:nil];
        completion(error);
    }];
}



- (void)clubAreaMaps:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaClubAreaMapsPath params:@{} httpMethod:@"GET" ssl:UseSSL];

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

- (void)clubAreaMap:(NSString*) externalId completion:(RiistaJsonCompletion)completion
{
    NSString *path = [NSString stringWithFormat:RiistaClubAreaMapPath, externalId];
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:path params:@{} httpMethod:@"GET" ssl:UseSSL];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *entry = [completedOperation responseJSON];
            completion(entry, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)listMooseAreaMaps:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaMooseAreaMapsPath params:@{} httpMethod:@"GET" ssl:UseSSL];

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

- (void)listPienriistaAreaMaps:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaPienriistaAreaMapsPath params:@{} httpMethod:@"GET" ssl:UseSSL];

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

- (void)listShootingTestCalendarEvents:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:RiistaShootingTestCalendarEventsPath
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:UseSSL];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *events = [completedOperation responseJSON];
            completion(events, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)getShootingTestCalendarEvent:(long)eventId completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:[NSString stringWithFormat:RiistaShootingTestCalendarEventPath, eventId]
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *event = [completedOperation responseJSON];
            completion(event, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)startEvent:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"POST"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)closeEvent:(NSString*)url completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"POST"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)reopenEvent:(NSString*)url completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"POST"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)updateOfficials:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"PUT"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)listAvailableOfficialsForEvent:(NSString*)url completion:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)listAvailableOfficialsForRhy:(NSString*)url completion:(RiistaJsonArrayCompletion)completion;
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)listSelectedOfficialsForEvent:(NSString*)url completion:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)searchWithHuntingNumberForEvent:(NSString*)url hunterNumber:(NSString*)hunterNumber completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"POST"
                                                                      ssl:YES];
    [operation setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
        return [NSString stringWithFormat:@"hunterNumber=%@", hunterNumber];
    } forType:@"application/x-www-form-urlencoded"];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)searchWithSsnForEvent:(NSString*)url ssn:(NSString*)ssn completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"POST"
                                                                      ssl:YES];
    [operation setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
        return [NSString stringWithFormat:@"ssn=%@", ssn];
    } forType:@"application/x-www-form-urlencoded"];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)addParticipant:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"POST"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)getParticipantDetailed:(NSString*)url completion:(RiistaJsonCompletion)completion{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)getAttempt:(NSString*)url completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)addAttempt:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"PUT"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)updateAttempt:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"POST"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)deleteAttempt:(NSString*)url completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"DELETE"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)listParticipants:(NSString*)url unfinishedOnly:(BOOL)unfinishedOnly completion:(RiistaJsonArrayCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];
    [operation setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
        return [NSString stringWithFormat:@"unfinishedOnly=%s", unfinishedOnly ? "true" : "false"];
    } forType:@"application/x-www-form-urlencoded"];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSArray *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)getParticipantSummary:(NSString*)url completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:@{}
                                                               httpMethod:@"GET"
                                                                      ssl:YES];

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            NSDictionary *response = [completedOperation responseJSON];
            completion(response, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)completeAllPayments:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"PUT"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
}

- (void)updatePaymentState:(NSString*)url body:(NSDictionary*)body completion:(RiistaJsonCompletion)completion
{
    MKNetworkOperation *operation = [self.networkEngine operationWithPath:url
                                                                   params:body
                                                               httpMethod:@"POST"
                                                                      ssl:YES];
    operation.postDataEncoding = MKNKPostDataEncodingTypeJSON;

    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        if (completion) {
            completion(nil, nil);
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
    [self.networkEngine enqueueOperation:operation];
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
