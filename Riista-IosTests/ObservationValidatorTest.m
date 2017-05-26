#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>

#import "GeoCoordinate.h"
#import "ObservationValidator.h"
#import "ObservationEntry.h"
#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"
#import "RiistaAppDelegate.h"

@interface ObservationValidatorTest : XCTestCase

@end

@interface MockMetadataManager : NSObject <MetadataManager>

@end

@implementation ObservationValidatorTest

id<MetadataManager> metadataManager;

- (void)setUp
{
    [super setUp];

    metadataManager = [MockMetadataManager new];
}

- (void)tearDown
{
    metadataManager = nil;

    [super tearDown];
}

- (void)testValidate
{
    XCTAssert(NO);
}

- (void)testValidateSpeciesId
{
    BOOL result = [ObservationValidator validateSpeciesId:0];
    XCTAssertFalse(result);

    result = [ObservationValidator validateSpeciesId:47503];
    XCTAssertTrue(result);
}

- (void)testValidateEntryType
{
    BOOL result = [ObservationValidator validateEntryType:nil];
    XCTAssertFalse(result);

    result = [ObservationValidator validateEntryType:@""];
    XCTAssertFalse(result);

    result = [ObservationValidator validateEntryType:DiaryEntryTypeHarvest];
    XCTAssertFalse(result);

    result = [ObservationValidator validateEntryType:DiaryEntryTypeObservation];
    XCTAssertTrue(result);
}

- (void)testValidatePosition
{
    RiistaAppDelegate *app = [[UIApplication sharedApplication] delegate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"GeoCoordinate" inManagedObjectContext:[app managedObjectContext]];
    NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];

    GeoCoordinate *coord = (GeoCoordinate*)object;

    BOOL result = [ObservationValidator validatePosition:coord];
    XCTAssertFalse(result);

    coord.latitude = [NSNumber numberWithInt: 7007200];
    coord.longitude = [NSNumber numberWithInt: 600350];
    coord.source = DiaryEntryLocationGps;

    XCTAssertTrue([ObservationValidator validatePosition:coord]);

    coord.source = DiaryEntryLocationManual;
    XCTAssertTrue([ObservationValidator validatePosition:coord]);

    coord.latitude = [NSNumber numberWithInt:0];
    XCTAssertFalse([ObservationValidator validatePosition:coord]);

    coord.latitude = [NSNumber numberWithInt:7007200];
    coord.longitude = [NSNumber numberWithInt:0];
    XCTAssertFalse([ObservationValidator validatePosition:coord]);

    coord.latitude = [NSNumber numberWithInt: 7007200];
    coord.longitude = [NSNumber numberWithInt: 600350];
    coord.source = @"source";
    XCTAssertFalse([ObservationValidator validatePosition:coord]);
}

- (void)testValidateTimestamp
{
    BOOL result = [ObservationValidator validateTimestamp:nil];
    XCTAssertFalse(result);

    result = [ObservationValidator validateTimestamp:[NSDate date]];
    XCTAssertTrue(result);

    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:1000000];
    result = [ObservationValidator validateTimestamp:date];
    XCTAssertFalse(result);

    date = [NSDate dateWithTimeIntervalSinceNow:-1000000];
    result = [ObservationValidator validateTimestamp:date];
    XCTAssertTrue(result);
}

- (void)testValidateObservationType
{
    BOOL result = [ObservationValidator validateObservationType:nil];
    XCTAssertFalse(result);

    result = [ObservationValidator validateObservationType:@""];
    XCTAssertFalse(result);

    result = [ObservationValidator validateObservationType:@"Any string"];
    XCTAssertTrue(result);
}

- (void)testValidateAmount
{
    // Missing metadata
    BOOL result = [ObservationValidator validateAmount:[NSNumber numberWithInt:1]
                                              metadata:nil
                                       observationType:@"TEST1"
                                    withinMooseHunting:NO];
    XCTAssertFalse(result);

    // Missing field set for observation type
    result = [ObservationValidator validateAmount:[NSNumber numberWithInt:1]
                                         metadata:[metadataManager getObservationMetadataForSpecies:1]
                                  observationType:@"NOTFOUND"
                               withinMooseHunting:NO];
    XCTAssertFalse(result);

    // No amount allowed for observation
    result = [ObservationValidator validateAmount:[NSNumber numberWithInt:1]
                                         metadata:[metadataManager getObservationMetadataForSpecies:1]
                                  observationType:@"TEST1"
                               withinMooseHunting:NO];
    XCTAssertFalse(result);

    // OK
    result = [ObservationValidator validateAmount:nil
                                         metadata:[metadataManager getObservationMetadataForSpecies:1]
                                  observationType:@"TEST1"
                               withinMooseHunting:NO];
    XCTAssertTrue(result);

    // OK
    result = [ObservationValidator validateAmount:[NSNumber numberWithInt:1]
                                        metadata:[metadataManager getObservationMetadataForSpecies:2]
                                 observationType:@"TEST2"
                              withinMooseHunting:NO];
    XCTAssertTrue(result);

    // Zero amount
    result = [ObservationValidator validateAmount:[NSNumber numberWithInt:0]
                                         metadata:[metadataManager getObservationMetadataForSpecies:2]
                                  observationType:@"TEST2"
                               withinMooseHunting:NO];
    XCTAssertFalse(result);

    // Too high amount
    result = [ObservationValidator validateAmount:[NSNumber numberWithInt:1000]
                                         metadata:[metadataManager getObservationMetadataForSpecies:2]
                                  observationType:@"TEST2"
                               withinMooseHunting:NO];
    XCTAssertFalse(result);
}

- (void)testValidateSpecimens
{
    XCTAssert(NO);
}

@end

@implementation MockMetadataManager

- (BOOL)hasObservationMetadata
{
    return NO;
}

- (ObservationSpecimenMetadata *)getObservationMetadataForSpecies:(NSInteger)speciesCode
{
    if (speciesCode == 1) {
        return [self noSpeciesNoAmountData];
    }
    else if (speciesCode == 2) {
        return [self noSpeciesWithAmountData];
    }

    return nil;
}

- (ObservationSpecimenMetadata *)noSpeciesNoAmountData
{
    ObservationSpecimenMetadata *meta =[ObservationSpecimenMetadata new];
    meta.gameSpeciesCode = 1;
    meta.baseFields = [NSDictionary new];
    meta.specimenFields = [NSDictionary new];

    ObservationContextSensitiveFieldSets *fieldset = [ObservationContextSensitiveFieldSets new];
    fieldset.type = @"TEST1";
    fieldset.withinMooseHunting = NO;
    fieldset.baseFields = [NSDictionary new];
    fieldset.specimenFields = [NSDictionary new];
    fieldset.allowedAges = [NSArray new];
    fieldset.allowedMarkings = [NSArray new];
    fieldset.allowedStates = [NSArray new];

    meta.contextSensitiveFieldSets = [[NSArray alloc] initWithObjects:fieldset, nil];

    return meta;
}

- (ObservationSpecimenMetadata *)noSpeciesWithAmountData
{
    ObservationSpecimenMetadata *meta =[ObservationSpecimenMetadata new];
    meta.gameSpeciesCode = 2;
    meta.baseFields = [NSDictionary new];
    meta.specimenFields = [NSDictionary new];

    ObservationContextSensitiveFieldSets *fieldset = [ObservationContextSensitiveFieldSets new];
    fieldset.type = @"TEST2";
    fieldset.withinMooseHunting = NO;
    fieldset.baseFields = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"YES", @"amount", nil];
    fieldset.specimenFields = [NSDictionary new];
    fieldset.allowedAges = [NSArray new];
    fieldset.allowedMarkings = [NSArray new];
    fieldset.allowedStates = [NSArray new];

    meta.contextSensitiveFieldSets = [[NSArray alloc] initWithObjects:fieldset, nil];

    return meta;
}

@end
