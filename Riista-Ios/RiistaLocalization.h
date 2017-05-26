#import <Foundation/Foundation.h>

#define RiistaLocalizedString(key, comment) \
[[RiistaLocalization sharedInstance] localizedStringForKey:(key) value:(comment)]

#define RiistaMappedValueString(key, comment) \
[[RiistaLocalization sharedInstance] mappedValueStringForKey:(key) value:(comment)]

#define RiistaLanguageRefresh \
[[RiistaLocalization sharedInstance] setLanguageFromSettings]

#define LocalizationSetLanguage(language) \
[[RiistaLocalization sharedInstance] setLanguage:(language)]

#define LocalizationGetLanguage \
[[RiistaLocalization sharedInstance] getLanguage]

#define LocalizationReset \
[[RiistaLocalization sharedInstance] resetLocalization]


@interface RiistaLocalization : NSObject {
    NSString* language;
}

+ (RiistaLocalization*) sharedInstance;
- (NSString*) localizedStringForKey:(NSString*)key value:(NSString*)comment;
- (NSString*) mappedValueStringForKey:(NSString*)key value:(NSString*)comment;
- (void) setLanguageFromSettings;
- (void) setLanguage:(NSString*)language;
- (NSString*) getLanguage;
- (void) resetLocalization;

@end
