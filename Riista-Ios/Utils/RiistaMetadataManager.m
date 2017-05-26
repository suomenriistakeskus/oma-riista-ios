#import <Foundation/Foundation.h>
#import "RiistaMetadataManager.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "ObservationMetadata.h"
#import "ObservationSpecimenMetadata.h"
#import "SrvaMetadata.h"

NSString *const ObservationSpecFile = @"observationmetadata_%ld.json";
NSString *const SrvaSpecFile = @"srvametadata_%ld.json";

@implementation RiistaMetadataManager
{
    ObservationMetadata *observationMeta;
    SrvaMetadata *srvaMeta;
}

+ (RiistaMetadataManager*)sharedInstance
{
    static RiistaMetadataManager *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [RiistaMetadataManager new];
    });
    return pInst;
}

- (instancetype)init
{
    if (self = [super init]) {
        observationMeta = [self loadObservationMetadata:ObservationSpecFile];
    }

    return self;
}

- (void)fetchObservationMetadata:(RiistaDiaryObservationMetaCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] preloadObservationMeta:^(NSData *response, NSError *error) {
        if (error == nil) {
            [self saveObservationMetadata:response filename:ObservationSpecFile];
        }

        if (completion) {
            if (error) {
                completion(nil, error);
            } else {
                completion(response, nil);
            }
        }

        observationMeta = [self loadObservationMetadata:ObservationSpecFile];
    }];
}

- (BOOL)hasObservationMetadata
{
    return observationMeta != nil;
}

- (ObservationSpecimenMetadata*) getObservationMetadataForSpecies:(NSInteger)speciesCode
{
    if (observationMeta != nil) {
        for (ObservationSpecimenMetadata* specimen in observationMeta.speciesList) {
            if (specimen.gameSpeciesCode == speciesCode) {
                return specimen;
            }
        }
    }

    return nil;
}

- (void)saveObservationMetadata:(NSData*)value filename:(NSString*)filename
{
    NSError *error = nil;
    if (![value writeToURL:[self ObservationFilePath:filename] options:0 error:&error]) {
        NSLog(@"Failed to write observation metadata to file: %@", [error localizedDescription]);
    }
}

- (ObservationMetadata*)loadObservationMetadata:(NSString*)fileName
{
    NSError *error;
    id jsonObject;

    NSURL *filePath = [self ObservationFilePath:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[filePath path]]) {

        NSData *fileData = [NSData dataWithContentsOfURL:filePath];
        jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:kNilOptions error:&error];
    }
    else {
        NSLog(@"File does not exist: %@", fileName);
    }

    ObservationMetadata *meta = [[ObservationMetadata alloc] initWithDictionary:jsonObject];
    return meta;
}

- (NSURL*)ObservationFilePath:(NSString *)fileName
{
    return [[RiistaUtils applicationDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:fileName, ObservationSpecVersion]];
}

- (NSURL*)SrvaFilePath:(NSString *)fileName
{
    return [[RiistaUtils applicationDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:fileName, SrvaSpecVersion]];
}

- (void)saveSrvaMetadata:(NSData*)value filename:(NSString*)filename
{
    NSError *error = nil;
    if (![value writeToURL:[self SrvaFilePath:filename] options:0 error:&error]) {
        NSLog(@"Failed to write Srva metadata to file: %@", [error localizedDescription]);
    }
}

- (SrvaMetadata*)loadSrvaMetadata:(NSString*)fileName
{
    SrvaMetadata *meta = nil;

    NSURL *filePath = [self SrvaFilePath:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[filePath path]]) {
        NSData *fileData = [NSData dataWithContentsOfURL:filePath];
        NSError *error;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:kNilOptions error:&error];
        if (jsonObject) {
            meta = [[SrvaMetadata alloc] initWithDictionary:jsonObject];
        }
    }
    else {
        NSLog(@"File does not exist: %@", fileName);
    }
    return meta;
}

- (void)fetchSrvaMetadata:(RiistaDiarySrvaMetaCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] preloadSrvaMeta:^(NSData *response, NSError *error) {
        if (error == nil) {
            [self saveSrvaMetadata:response filename:SrvaSpecFile];
        }

        if (completion) {
            if (error) {
                completion(nil, error);
            }
            else {
                completion(response, nil);
            }
        }

        srvaMeta = [self loadSrvaMetadata:SrvaSpecFile];
    }];
}

- (BOOL)hasSrvaMetadata
{
    return srvaMeta != nil;
}

- (SrvaMetadata*)getSrvaMetadata
{
    return srvaMeta;
}

- (void)fetchAll
{
    [[RiistaMetadataManager sharedInstance] fetchObservationMetadata:nil];
    [[RiistaMetadataManager sharedInstance] fetchSrvaMetadata:nil];
}

@end
