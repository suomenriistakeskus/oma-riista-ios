#import "RiistaSettings.h"
#import "DataModels.h"

NSInteger const HarvestSpecVersion = 9;
NSInteger const ObservationSpecVersion = 4;
// first observation spec version having observation category support
NSInteger const ObservationSpecVersionWithObservationCategory = 4;
NSInteger const SrvaSpecVersion = 1;

NSInteger const MooseId = 47503;
NSInteger const FallowDeerId = 47484;
NSInteger const WhiteTailedDeerId = 47629;
NSInteger const WildForestDeerId = 200556;
NSInteger const BearId = 47348;

NSString *const RiistaSettingsLanguageKey = @"Language";
NSString *const RiistaSettingsMapTypeKey = @"MapType";

// synchronize with AppConstants
NSString *const RiistaDefaultAppLanguage = @"en";

NSString *const RiistaUserInfoUpdatedKey = @"UserInfoUpdated";

NSString *const RiistaPushAnnouncementKey = @"RiistaPushAnnouncementKey";

NSString *const RiistaSelecteClubAreaMapKey = @"RiistaSelecteClubAreaMapKey";
NSString *const RiistaShowMyMapLocationKey = @"RiistaShowMyMapLocationKey";
NSString *const RiistaInvertMapColorsKey = @"RiistaInvertMapColorsKey";
NSString *const RiistaHideMapButtonsKey = @"RiistaHideMapButtonsKey";
NSString *const RiistaShowStateOwnedLandsKey = @"RiistaShowStateOwnedLandsKey";
NSString *const RiistaShowRhyBordersKey = @"RiistaShowRhyBordersKey";
NSString *const RiistaShowGameTrianglesKey = @"RiistaShowGameTrianglesKey";
NSString *const RiistaShowMooseRestrictionsKey = @"RiistaShowMooseRestrictionsKey";
NSString *const RiistaShowSmallGameRestrictionsKey = @"RiistaShowSmallGameRestrictionsKey";
NSString *const RiistaShowAviHuntingBanKey = @"RiistaShowAviHuntingBanKey";
NSString *const RiistaSelectedMooseAreaKey = @"RiistaSelectedMooseAreaKey";
NSString *const RiistaSelectePienriistaAreaKey = @"RiistaSelectePienriistaAreaKey";

NSString *const RiistaUseExperimentalMode = @"RiistaUseExperimentalMode";

NSString *const kUserInfoFileName = @"/user.json";

@implementation RiistaSettings


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

+ (NSString*)activeClubAreaMapId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:RiistaSelecteClubAreaMapKey];
}

+ (void)setActiveClubAreaMapId:(NSString*)mapId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:mapId forKey:RiistaSelecteClubAreaMapKey];
    [userDefaults synchronize];
}

+ (BOOL)showMyMapLocation
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *value = [userDefaults objectForKey:RiistaShowMyMapLocationKey];
    if (value) {
        return [value boolValue];
    }
    return YES; //Default
}

+ (void)setShowMyMapLocation:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:show] forKey:RiistaShowMyMapLocationKey];
    [userDefaults synchronize];
}

+ (BOOL)invertMapColors
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaInvertMapColorsKey];
}

+ (void)setInvertMapColors:(BOOL)invert
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:invert forKey:RiistaInvertMapColorsKey];
    [userDefaults synchronize];
}

+ (BOOL)hideMapButtons
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaHideMapButtonsKey];
}

+ (void)setHideMapButtons:(BOOL)hide
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:hide forKey:RiistaHideMapButtonsKey];
    [userDefaults synchronize];
}

+ (BOOL)showStateOwnedLands
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaShowStateOwnedLandsKey];
}

+ (void)setShowStateOwnedLands:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:show forKey:RiistaShowStateOwnedLandsKey];
    [userDefaults synchronize];
}

+ (BOOL)showRhyBorders
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaShowRhyBordersKey];
}

+ (void)setShowRhyBorders:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:show forKey:RiistaShowRhyBordersKey];
    [userDefaults synchronize];
}

+ (BOOL)showGameTriangles
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaShowGameTrianglesKey];
}

+ (void)setShowGameTriangles:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:show forKey:RiistaShowGameTrianglesKey];
    [userDefaults synchronize];
}

+ (BOOL)showMooseRestrictions
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaShowMooseRestrictionsKey];
}

+ (void)setShowMooseRestrictions:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:show forKey:RiistaShowMooseRestrictionsKey];
    [userDefaults synchronize];
}

+ (BOOL)showSmallGameRestrictions
{
    NSLog(@"showSmallGameRestrictions");
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaShowSmallGameRestrictionsKey];
}

+ (void)setShowSmallGameRestrictions:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:show forKey:RiistaShowSmallGameRestrictionsKey];
    [userDefaults synchronize];
}

+ (BOOL)showAviHuntingBan
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaShowAviHuntingBanKey];
}

+ (void)setShowAviHuntingBan:(BOOL)show
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:show forKey:RiistaShowAviHuntingBanKey];
    [userDefaults synchronize];
}

+ (AreaMap*)selectedMooseArea
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [userDefaults objectForKey:RiistaSelectedMooseAreaKey];
    @try {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];

        if (array.count == 1) {
            AreaMap *item = [array objectAtIndex:0];
            return item;
        }
    } @catch (NSException *exception) {
        DDLog(@"Failed to load moose area from user defaults");
    }

    return nil;
}

+ (void)setSelectedMooseArea:(AreaMap*)area
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (area == nil) {
        [userDefaults setObject:nil forKey:RiistaSelectedMooseAreaKey];
    }
    else {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObject:area];
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:array];

        [userDefaults setObject:encodedObject forKey:RiistaSelectedMooseAreaKey];
    }

    [userDefaults synchronize];
}

+ (AreaMap*)selectedPienriistaArea
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [userDefaults objectForKey:RiistaSelectePienriistaAreaKey];
    @try {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];

        if (array.count == 1) {
            AreaMap *item = [array objectAtIndex:0];
            return item;
        }
    } @catch (NSException *exception) {
        DDLog(@"Failed to load pienriista area from user defaults");
    }

    return nil;
}

+ (void)setSelectedPienriistaArea:(AreaMap*)area
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (area == nil) {
        [userDefaults setObject:nil forKey:RiistaSelectePienriistaAreaKey];
    }
    else {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObject:area];
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:array];

        [userDefaults setObject:encodedObject forKey:RiistaSelectePienriistaAreaKey];
    }
    [userDefaults synchronize];
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

+ (BOOL)useExperimentalMode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:RiistaUseExperimentalMode];
}

+ (void)setUseExperimentalMode:(BOOL)useExperimentalMode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:useExperimentalMode forKey:RiistaUseExperimentalMode];
    [userDefaults synchronize];
}

@end
