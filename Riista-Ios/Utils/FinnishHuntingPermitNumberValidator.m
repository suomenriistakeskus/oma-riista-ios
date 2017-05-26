#import "FinnishHuntingPermitNumberValidator.h"

static const NSString *REGEX_PATTERN = @"[1-9][0-9]{3}-[1-5]-[0-9]{3}-[0-9]{5}-[0-9]";
static const int WEIGHTS[] = {7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7};
static const int VALID_DIGITS_LENGTH = 13;
static const int VALID_LENGTH = 18;


@implementation FinnishHuntingPermitNumberValidator

+ (BOOL)validate:(NSString*)value verifyChecksum:(BOOL)verifyChecksum
{
    if (value == nil || [value length] == 0) {
        return true;
    }

    if ([value length] != VALID_LENGTH) {
        return false;
    }

    NSPredicate *formatPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", REGEX_PATTERN];
    if (![formatPredicate evaluateWithObject:value]) {
        return false;
    }

    if (!verifyChecksum) {
        return true;
    }

    char checksum = [value characterAtIndex:([value length] - 1)];
    char calculatedChecksum = [self calculateChecksum:value];

    return checksum == calculatedChecksum;
}

+ (char)calculateChecksum:(NSString*)s
{
    return [self calculateChecksumOnlyDigits:[self onlyDigits:s]];
}

+ (NSString*)onlyDigits:(NSString*)value
{
    return [value stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

+ (char)calculateChecksumOnlyDigits:(NSString*)s
{
    int sum = 0;

    for (int i = 0; i < VALID_DIGITS_LENGTH; i++) {
        sum += ([s characterAtIndex:i] - '0') * WEIGHTS[i];
    }

    int remainder = (int)(sum % 10);

    if (remainder == 0) {
        return '0';
    }

    return '0' + (10 - remainder);
}

@end
