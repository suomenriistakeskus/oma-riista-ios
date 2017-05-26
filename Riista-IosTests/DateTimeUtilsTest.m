#import <XCTest/XCTest.h>
#import "RiistaDateTimeUtils.h"

@interface DateTimeUtilsTest : XCTestCase

@end

@implementation DateTimeUtilsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRemoveTime {
    NSDate *input = [NSDate date];
    NSDate *output = [RiistaDateTimeUtils removeTime:input];

    NSDateComponents *inputComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:input];
    NSDateComponents *outputComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:output];

    XCTAssertEqual(outputComponents.year, inputComponents.year);
    XCTAssertEqual(outputComponents.month, inputComponents.month);
    XCTAssertEqual(outputComponents.day, inputComponents.day);
    XCTAssertEqual(outputComponents.hour, 0);
    XCTAssertEqual(outputComponents.minute, 0);
    XCTAssertEqual(outputComponents.second, 0);
}

- (void)testAddZeroDays {
    NSDate *input = [NSDate date];
    NSDate *output = [RiistaDateTimeUtils addDays:input daysToAdd:0];

    NSDateComponents *inputComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:input];
    NSDateComponents *outputComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:output];

    XCTAssertEqual(outputComponents.year, inputComponents.year);
    XCTAssertEqual(outputComponents.month, inputComponents.month);
    XCTAssertEqual(outputComponents.day, inputComponents.day);
}

- (void)testAddPlusDays {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];

    components.day = 31;
    components.month = 12;
    components.year = 2014;

    NSDate *input = [calendar dateFromComponents:components];
    NSDate *output = [RiistaDateTimeUtils addDays:input daysToAdd:60];

    NSDateComponents *outputComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:output];

    XCTAssertEqual(outputComponents.year, 2015);
    XCTAssertEqual(outputComponents.month, 3);
    XCTAssertEqual(outputComponents.day, 1);
}

- (void)testAddMinusDays {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];

    components.day = 10;
    components.month = 1;
    components.year = 2015;

    NSDate *input = [calendar dateFromComponents:components];
    NSDate *output = [RiistaDateTimeUtils addDays:input daysToAdd:-30];

    NSDateComponents *outputComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:output];

    XCTAssertEqual(outputComponents.year, 2014);
    XCTAssertEqual(outputComponents.month, 12);
    XCTAssertEqual(outputComponents.day, 11);
}

- (void)testSeasonStartTime {
    NSDate *startDate = [RiistaDateTimeUtils seasonStartForStartYear:2015];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:startDate];

    XCTAssertEqual(components.year, 2015);
    XCTAssertEqual(components.month, 8);
    XCTAssertEqual(components.day, 1);
    XCTAssertEqual(components.hour, 0);
    XCTAssertEqual(components.minute, 0);
}

- (void)testSeasonEndTime {
    NSDate *endDate = [RiistaDateTimeUtils seasonEndForStartYear:2015];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:endDate];

    XCTAssertEqual(components.year, 2016);
    XCTAssertEqual(components.month, 7);
    XCTAssertEqual(components.day, 31);
    XCTAssertEqual(components.hour, 23);
    XCTAssertEqual(components.minute, 59);
}

- (void)testDateInRange {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];

    components.day = 10;
    components.month = 1;
    components.year = 2015;
    NSDate *beginDate = [calendar dateFromComponents:components];

    components.day = 20;
    components.month = 2;
    components.year = 2015;
    NSDate *endDate = [calendar dateFromComponents:components];

    components.day = 20;
    components.month = 1;
    NSDate *checkDate = [calendar dateFromComponents:components];
    XCTAssertTrue([RiistaDateTimeUtils betweenDatesInclusive:checkDate isBetweenDate:beginDate andDate:endDate]);

    components.day = 9;
    components.month = 1;
    components.hour = 23;
    components.minute = 50;
    checkDate = [calendar dateFromComponents:components];
    XCTAssertFalse([RiistaDateTimeUtils betweenDatesInclusive:checkDate isBetweenDate:beginDate andDate:endDate]);

    components.day = 10;
    components.month = 1;
    components.hour = 0;
    components.minute = 10;
    checkDate = [calendar dateFromComponents:components];
    XCTAssertTrue([RiistaDateTimeUtils betweenDatesInclusive:checkDate isBetweenDate:beginDate andDate:endDate]);

    components.day = 20;
    components.month = 2;
    components.hour = 23;
    components.minute = 50;
    checkDate = [calendar dateFromComponents:components];
    XCTAssertTrue([RiistaDateTimeUtils betweenDatesInclusive:checkDate isBetweenDate:beginDate andDate:endDate]);

    components.day = 21;
    components.month = 2;
    components.hour = 0;
    components.minute = 10;
    checkDate = [calendar dateFromComponents:components];
    XCTAssertFalse([RiistaDateTimeUtils betweenDatesInclusive:checkDate isBetweenDate:beginDate andDate:endDate]);
}

@end
