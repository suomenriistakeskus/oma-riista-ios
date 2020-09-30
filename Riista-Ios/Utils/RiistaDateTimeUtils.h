#import <Foundation/Foundation.h>

@interface RiistaDateTimeUtils : NSObject

+ (NSTimeZone*)finnishTimezone;

+ (NSDate*)removeTime:(NSDate*)originalDate;
+ (NSDate*)addDays:(NSDate*)originalDate daysToAdd:(int)numberOfDays;

+ (NSDate*)seasonStartForStartYear:(int)year;
+ (NSDate*)seasonEndForStartYear:(int)year;

/**
 * Is date in range of two limiting dates. Inclusive, ignore time components.
 *
 * @param date Date to compare
 * @param beginDate
 * @param endDate
 */
+ (BOOL)betweenDatesInclusive:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;

@end
