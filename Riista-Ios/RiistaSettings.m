#import "RiistaSettings.h"
#import "DataModels.h"

NSInteger const HarvestSpecVersion = 4;
NSInteger const ObservationSpecVersion = 2;
NSInteger const SrvaSpecVersion = 1;

NSInteger const MooseId = 47503;
NSInteger const FallowDeerId = 47484;
NSInteger const WhiteTailedDeerId = 47629;
NSInteger const WildForestDeerId = 200556;
NSInteger const BearId = 47348;

NSString *const RiistaSettingsSyncModeKey = @"SyncMode";
NSString *const RiistaSettingsLanguageKey = @"Language";
NSString *const RiistaSettingsMapTypeKey = @"MapType";

NSString *const RiistaDefaultAppLanguage = @"en";

NSString *const RiistaUserInfoUpdatedKey = @"UserInfoUpdated";

NSString *const kUserInfoFileName = @"/user.json";

@implementation RiistaSettings

+ (RiistaSyncMode)syncMode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    RiistaSyncMode mode = RiistaSyncModeAutomatic;
    if ([userDefaults objectForKey:RiistaSettingsSyncModeKey]) {
        mode = (int)[userDefaults integerForKey:RiistaSettingsSyncModeKey];
    }
    return mode;
}

+ (NSString*)language
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *language = RiistaDefaultAppLanguage;

    if ([userDefaults objectForKey:RiistaSettingsLanguageKey]) {
        language = [userDefaults stringForKey:RiistaSettingsLanguageKey];
    }
    else {
        // Init settings value to system language if supported or default value if not
        NSArray *supportedLanguages = @[@"fi", @"sv", @"en"];
        NSString *systemLanguage = [[NSLocale preferredLanguages] firstObject];

        // Since iOS9 there is country code attached to language code
        NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:systemLanguage];
        NSString *languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"];

        if ([supportedLanguages containsObject:languageCode]) {
            [self setLanguageSetting:languageCode];
            language = languageCode;
        } else {
            [self setLanguageSetting:RiistaDefaultAppLanguage];
        }
    }

    return language;
}

+ (RiistaMapType)mapType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    RiistaMapType mapType = MmlTopographicMapType;

    if ([userDefaults objectForKey:RiistaSettingsMapTypeKey]) {
        mapType = (int)[userDefaults integerForKey:RiistaSettingsMapTypeKey];
    }

    return mapType;
}

+ (void)setLanguageSetting:(NSString*)value
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:value forKey:RiistaSettingsLanguageKey];
    [userDefaults synchronize];
}

+ (void)setMapTypeSetting:(RiistaMapType)value
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:value forKey:RiistaSettingsMapTypeKey];
    [userDefaults synchronize];
}

+ (NSLocale*)locale
{
    return [[NSLocale alloc] initWithLocaleIdentifier:[self language]];
}

+ (UserInfo*)userInfo
{
    UserInfo *retVal = nil;
    NSString *filePath = [self userInfoFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        retVal = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        if (retVal) {
            NSLog(@"User info loaded");
        }
    }
    else {
        NSLog(@"User information does not exist");
    }

    return retVal;
}

+ (void)setUserInfo:(UserInfo*)value
{
    [NSKeyedArchiver archiveRootObject:value toFile:[self userInfoFilePath]];

    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaUserInfoUpdatedKey object:value];
}

+ (NSString*)userInfoFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths count] > 0 ? [paths objectAtIndex:0] : nil;
    NSString *filePath = [documentsDir stringByAppendingString:kUserInfoFileName];

    return filePath;
}

@end
