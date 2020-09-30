#import "RiistaDateTimeUtils.h"

@implementation RiistaDateTimeUtils

+ (NSTimeZone*)finnishTimezone
{
    return [NSTimeZone timeZoneWithName:@"EET"];
}

+ (NSDate*)removeTime:(NSDate*)originalDate
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:flags fromDate:originalDate];

    return [calendar dateFromComponents:dateComponents];
}

+ (NSDate*)addDays:(NSDate*)originalDate daysToAdd:(int)daysCount
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:daysCount];

    return [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents
                                                         toDate:originalDate
                                                        options:0];
}

+ (NSDate*)seasonStartForStartYear:(int)year
{
    NSDateComponents *components = [NSDateComponents new];
    [components setYear:year];
    [components setMonth:8];
    [components setDay:1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];

    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

+ (NSDate*)seasonEndForStartYear:(int)year
{
    NSDateComponents *components = [NSDateComponents new];
    [components setYear:year + 1];
    [components setMonth:8];
    [components setDay:1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];

    NSDate *nextStart = [[NSCalendar currentCalendar] dateFromComponents:components];

    return [nextStart dateByAddingTimeInterval:-1.0];
}

+ (BOOL)betweenDatesInclusive:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
{
    NSDate *lowerLimit = [self removeTime:beginDate];
    NSDate *upperLimit = [self addDays:[self removeTime:endDate] daysToAdd:1];

    NSComparisonResult result = [date compare:lowerLimit];
    if (result == NSOrderedAscending || result == NSOrderedSame) {
        return NO;
    }

    result = [date compare:upperLimit];
    if (result == NSOrderedDescending) {
        return NO;
    }

    return YES;
}

@end
