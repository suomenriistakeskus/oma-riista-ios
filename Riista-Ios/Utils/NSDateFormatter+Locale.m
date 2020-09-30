#import "NSDateFormatter+Locale.h"

#import "RiistaDateTimeUtils.h"

@implementation NSDateFormatter (Locale)

- (id)initWithSafeLocale {
    static NSLocale* en_US_POSIX = nil;
    self = [self init];

    // Use en_US_POSIX locale to override user/system preferences including 12/24h time format
    if (en_US_POSIX == nil) {
        en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }
    [self setLocale:en_US_POSIX];
    [self setTimeZone:[RiistaDateTimeUtils finnishTimezone]];

    return self;
}

@end
