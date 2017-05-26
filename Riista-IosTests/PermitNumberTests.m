#import <XCTest/XCTest.h>
#import "FinnishHuntingPermitNumberValidator.h"

@interface PermitNumberTests : XCTestCase

@end

@implementation PermitNumberTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParseValidPermitNumber {
    BOOL result = [FinnishHuntingPermitNumberValidator validate:@"2014-1-050-00128-6" verifyChecksum:YES];
    XCTAssert(result == YES);

    result = [FinnishHuntingPermitNumberValidator validate:@"2015-5-000-00014-2" verifyChecksum:YES];
    XCTAssert(result == YES);
}

- (void)testParseWrongChecksum {
    BOOL result = [FinnishHuntingPermitNumberValidator validate:@"2014-1-050-00128-5" verifyChecksum:YES];
    XCTAssert(result == NO);
}

- (void)testParseTooShort {
    BOOL result = [FinnishHuntingPermitNumberValidator validate:@"2014-1-00128-5" verifyChecksum:YES];
    XCTAssert(result == NO);
}

- (void)testParseTooLong {
    BOOL result = [FinnishHuntingPermitNumberValidator validate:@"2014-1-050-00128-000-5" verifyChecksum:YES];
    XCTAssert(result == NO);
}

@end
