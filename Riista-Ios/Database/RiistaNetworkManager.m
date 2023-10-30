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

NSString *const RiistaDiaryImageLoadPath = BASE_API_PATH @"gamediary/image/%@";

NSString *const RiistaPermitPreloadPath = BASE_API_PATH @"gamediary/preloadPermits";
NSString *const RiistaPermitCheckNumberPath = BASE_API_PATH @"gamediary/checkPermitNumber";

NSString *const RiistaListAnnouncementsPath = BASE_API_PATH @"announcement/list";

NSString *const RiistaClubAreaMapsPath = BASE_API_PATH @"area/club";
NSString *const RiistaClubAreaMapPath = BASE_API_PATH @"area/code/%@";

NSString *const RiistaMooseAreaMapsPath = BASE_API_PATH @"area/mh/hirvi";
NSString *const RiistaPienriistaAreaMapsPath = BASE_API_PATH @"area/mh/pienriista";

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

    [RiistaSDKHelper loginWithUsername:username
                              password:password
                        timeoutSeconds:timeoutSeconds
                           onCompleted:^(RiistaCommonNetworkResponse<RiistaCommonUserInfoDTO *> * _Nullable response, NSError * _Nullable error) {
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
