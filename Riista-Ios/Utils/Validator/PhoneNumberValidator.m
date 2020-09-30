#import "PhoneNumberValidator.h"
#import "NBPhoneNumberUtil.h"

NSString *const DEFAULT_REGION = @"FI";

@interface PhoneNumberValidator ()

@end

@implementation PhoneNumberValidator

+ (BOOL)isValid:(NSString *)value
{
    if ([value length] == 0)
    {
        return YES;
    }

    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *error = nil;
    NBPhoneNumber *phoneNumber = [phoneUtil parse:value defaultRegion:DEFAULT_REGION error:&error];

    if (error == nil)
    {
        return [phoneUtil isValidNumber:phoneNumber];
    }
    return NO;
}

@end
