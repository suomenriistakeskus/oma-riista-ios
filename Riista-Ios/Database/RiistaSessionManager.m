#import "RiistaSessionManager.h"
#import "KeyChainItemWrapper.h"
#import "RiistaMetadataManager.h"

// Settings storage name
static NSString *const RIISTA_COOKIESTORAGE_NAME = @"RiistaCookies";
static NSString *const COOKIE_URL = @"";

static NSString *const LOGIN_PROPERTY_NAME = @"userLoggedIn";

NSString *const RiistaAppLogin = @"RiistaAppLogin";

@implementation RiistaSessionManager
{
    BOOL _privateLoginState;
    NSNotificationCenter *notificationCenter;
    NSHTTPCookieStorage *cookieStorage;
    NSUserDefaults *userDefaults;
    NSString *loggedInUser;
}

- (id)init
{
    self = [super init];
    if (self) {
        _privateLoginState = NO;
        notificationCenter = [NSNotificationCenter defaultCenter];
        cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

+ (RiistaSessionManager*)sharedInstance
{
    static RiistaSessionManager *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [RiistaSessionManager new];
    });
    return pInst;
}

- (void)initializeSession
{
    [self loadUserLogin];
}

- (RiistaCredentials*)userCredentials
{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:RiistaAppLogin accessGroup:nil];
    
    NSString *username = [keychainItem objectForKey:(__bridge id)kSecAttrAccount];
    NSData *passwordData = [keychainItem objectForKey:(__bridge id)kSecValueData];
    if (passwordData.length > 0) {
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        if (username.length > 0 && password.length > 0) {
            RiistaCredentials *credentials = [RiistaCredentials new];
            credentials.username = username;
            credentials.password = password;
            return credentials;
        }
    }
    return nil;
}

- (void)storeCredentials:(RiistaCredentials*)credentials
{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:RiistaAppLogin accessGroup:nil];
    [keychainItem setObject:credentials.username forKey:(__bridge id)kSecAttrAccount];
    [keychainItem setObject:[credentials.password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    [keychainItem setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)kSecAttrAccessible];
}

- (void)removeCredentials
{
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:RiistaAppLogin accessGroup:nil];
    [keychainItem resetKeychainItem];
}

- (void)storeUserLogin
{
    NSArray *cookies = [cookieStorage cookies];
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
    
    [userDefaults setObject:cookieData forKey:RIISTA_COOKIESTORAGE_NAME];
    [userDefaults synchronize];
}

- (void)loadUserLogin
{
    NSData *cookiesdata = [userDefaults objectForKey:RIISTA_COOKIESTORAGE_NAME];
    if(cookiesdata.length > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage setCookie:cookie];
        }
        [[RiistaMetadataManager sharedInstance] fetchAll];
    }
}

- (void)removeUserLogin
{
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        [cookieStorage deleteCookie:cookie];
    }
    [self storeUserLogin];
}

- (NSHTTPCookie*)cookieWithName:(NSString*)cookieName
{
    NSURL *url = [NSURL URLWithString:COOKIE_URL];
    NSArray *cookies = [cookieStorage cookiesForURL:url];
    
    NSUInteger loginCookieIndex = [cookies indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((NSHTTPCookie*)obj).name isEqualToString:cookieName];
    }];
    
    if (loginCookieIndex != NSNotFound) {
        return cookies[loginCookieIndex];
    } else {
        return nil;
    }
}

- (BOOL)userLoggedIn
{
    return _privateLoginState;
}

@end

@implementation RiistaCredentials

- (void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:self.username forKey:@"username"];
    [encoder encodeObject:self.username forKey:@"password"];
}

- (id)initWithCoder:(NSCoder*)decoder {
    if((self = [super init])) {
        self.username = [decoder decodeObjectForKey:@"username"];
        self.password = [decoder decodeObjectForKey:@"password"];
    }
    return self;
}

@end
