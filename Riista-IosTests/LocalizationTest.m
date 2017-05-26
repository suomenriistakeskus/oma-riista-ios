#import <XCTest/XCTest.h>
#import "RiistaLocalization.h"

@interface LocalizationTest : XCTestCase

@end

@implementation LocalizationTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testValueMappedStrings
{
    NSString *result = RiistaMappedValueString(@"UNDEFINED_KEY", nil);
    XCTAssert([result isEqualToString:@"UNDEFINED_KEY"]);

    result = RiistaMappedValueString(@"NAKO", nil);
    XCTAssert([result isEqualToString:@"Seen"]);

    result = RiistaMappedValueString(nil, nil);
    XCTAssertNil(result);
}

@end
