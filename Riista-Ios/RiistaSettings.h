#import <Foundation/Foundation.h>

@class UserInfo;

extern NSInteger const HarvestSpecVersion;
extern NSInteger const ObservationSpecVersion;
extern NSInteger const SrvaSpecVersion;

extern NSInteger const MooseId;
extern NSInteger const FallowDeerId;
extern NSInteger const WhiteTailedDeerId;
extern NSInteger const WildForestDeerId;
extern NSInteger const BearId;

extern NSString *const RiistaSettingsSyncModeKey;
extern NSString *const RiistaSettingsLanguageKey;
extern NSString *const RiistaDefaultAppLanguage;
extern NSString *const RiistaUserInfoUpdatedKey;

typedef enum {
    RiistaSyncModeManual,
    RiistaSyncModeAutomatic
} RiistaSyncMode;

typedef enum {
    GoogleMapType         = 10,
    MmlMapType            = 20,
    MmlTopographicMapType = 21,
    MmlBackgroundMapType  = 22,
    MmlAerialMapType      = 23
} RiistaMapType;

@interface RiistaSettings : NSObject

+ (RiistaSyncMode)syncMode;
+ (NSString*)language;
+ (NSLocale*)locale;
+ (RiistaMapType)mapType;

+ (void)setLanguageSetting:(NSString*)value;
+ (void)setMapTypeSetting:(RiistaMapType)value;

+ (UserInfo*)userInfo;
+ (void)setUserInfo:(UserInfo*)value;

@end
