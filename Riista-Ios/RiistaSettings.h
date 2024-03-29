#import <Foundation/Foundation.h>

@class UserInfo, AreaMap;

extern NSInteger const HarvestSpecVersion;
extern NSInteger const ObservationSpecVersion;
extern NSInteger const ObservationSpecVersionWithObservationCategory;
extern NSInteger const SrvaSpecVersion;

extern NSInteger const MooseId;
extern NSInteger const FallowDeerId;
extern NSInteger const WhiteTailedDeerId;
extern NSInteger const WildForestDeerId;
extern NSInteger const BearId;

extern NSString *const RiistaSettingsLanguageKey;
extern NSString *const RiistaDefaultAppLanguage;
extern NSString *const RiistaUserInfoUpdatedKey;
extern NSString *const RiistaPushAnnouncementKey;

// UI Settings - here since they need to be compile time constants

static const CGFloat RiistaDefaultValueElementHeight = 80;
static const CGFloat RiistaCheckboxElementHeight = 50;
static const CGFloat RiistaInstructionsViewHeight = 80;

typedef enum {
    GoogleMapType         = 10,
    MmlMapType            = 20,
    MmlTopographicMapType = 21,
    MmlBackgroundMapType  = 22,
    MmlAerialMapType      = 23
} RiistaMapType;

@interface RiistaSettings : NSObject

+ (NSString*)language;
+ (NSLocale*)locale;
+ (RiistaMapType)mapType;

+ (void)setLanguageSetting:(NSString*)value;
+ (void)setMapTypeSetting:(RiistaMapType)value;

+ (NSString*)activeClubAreaMapId;
+ (void)setActiveClubAreaMapId:(NSString*)mapId;

+ (BOOL)showMyMapLocation;
+ (void)setShowMyMapLocation:(BOOL)show;

+ (BOOL)invertMapColors;
+ (void)setInvertMapColors:(BOOL)invert;

+ (BOOL)hideMapButtons;
+ (void)setHideMapButtons:(BOOL)hide;

+ (BOOL)showStateOwnedLands;
+ (void)setShowStateOwnedLands:(BOOL)show;

+ (BOOL)showRhyBorders;
+ (void)setShowRhyBorders:(BOOL)show;

+ (BOOL)showGameTriangles;
+ (void)setShowGameTriangles:(BOOL)show;

+ (BOOL)showLeadShotBan;
+ (void)setShowLeadShotBan:(BOOL)show;

+ (BOOL)showMooseRestrictions;
+ (void)setShowMooseRestrictions:(BOOL)show;

+ (BOOL)showSmallGameRestrictions;
+ (void)setShowSmallGameRestrictions:(BOOL)show;

+ (BOOL)showAviHuntingBan;
+ (void)setShowAviHuntingBan:(BOOL)show;

+ (AreaMap*)selectedMooseArea;
+ (void)setSelectedMooseArea:(AreaMap*)area;

+ (AreaMap*)selectedPienriistaArea;
+ (void)setSelectedPienriistaArea:(AreaMap*)area;

+ (UserInfo*)userInfo;
+ (void)setUserInfo:(UserInfo*)value;

+ (BOOL)useExperimentalMode;
+ (void)setUseExperimentalMode:(BOOL)useExperimentalMode;

@end
