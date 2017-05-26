#import <XCTest/XCTest.h>
//#import "RiistaPermitManager.h"

@interface PermitManagerTest : XCTestCase

//@property (strong, nonatomic) RiistaPermitManager *manager;

@end

@implementation PermitManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

//    self.manager = [RiistaPermitManager sharedInstance];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
- (void)testSpeciesSeasonActive {
    PermitSpeciesAmounts *speciesAmounts;
    int tolerance = 0;

    [self.manager isSpeciesSeasonActive:speciesAmounts daysTolerance:tolerance];

    XCTFail(@"Unimplemented");
}
*/

@end
