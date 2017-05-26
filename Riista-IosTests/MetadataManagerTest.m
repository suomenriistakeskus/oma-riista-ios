#import <XCTest/XCTest.h>
#import "RiistaUtils.h"

@interface MetadataManagerTest : XCTestCase

@end

@implementation MetadataManagerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

//- (void)testObservationMetadata
//{
//    NSFileManager *fileMngr = [NSFileManager defaultManager];
//    NSString *filename = @"test_obs_meta.json";
//
//    RiistaMetadataManager *mngr = [RiistaMetadataManager sharedInstance];
//
//    XCTAssertFalse([mngr hasObservationMetadata]);
//
//    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//    NSString *path = [bundle pathForResource:@"TestObservationMetadata" ofType:@"txt"];
//
//    NSData *fileData = [fileMngr contentsAtPath:path];
//
//    [mngr performSelector:@selector(saveObservationMetadata:filename:) withObject:fileData withObject:filename];
//
//    XCTAssertTrue([mngr hasObservationMetadata]);
//
//    XCTAssertNil([mngr getObservationMetadataForSpecies:999]);
//
//    ObservationSpecimenMetadata *species = [mngr getObservationMetadataForSpecies:47774];
//
//    XCTAssertNotNil(species);
//
//    NSError *error = nil;
//    [fileMngr removeItemAtURL:[[RiistaUtils applicationDirectory] URLByAppendingPathComponent:filename] error:&error];
//}

@end
