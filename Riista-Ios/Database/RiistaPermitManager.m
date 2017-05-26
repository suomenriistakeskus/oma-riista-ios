#import "RiistaPermitManager.h"
#import "Permit.h"
#import "PermitSpeciesAmounts.h"
#import "RiistaSpecimen.h"
#import "DiaryEntry.h"
#import "RiistaNetworkManager.h"
#import "RiistaDateTimeUtils.h"
#import "RiistaUtils.h"

NSString *const PreloadPermitFilePath = @"preloadPermits.json";
NSString *const ManualPermitFilePath = @"manualPermits.json";

@interface RiistaPermitManager ()

@property (nonatomic, strong) NSMutableDictionary *preloadPermits;
@property (nonatomic, strong) NSMutableDictionary *manualPermits;

@end

@implementation RiistaPermitManager

+ (RiistaPermitManager*)sharedInstance
{
    static RiistaPermitManager *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [RiistaPermitManager new];
    });
    return pInst;
}

- (instancetype)init {
    if (self = [super init]) {
    }

    return self;
}

- (void)dealloc {
}

- (NSArray*)getAllPermits
{
    [self reloadPermits];

    // Preloaded permits overwrite manual ones with same number
    NSMutableDictionary *results = [NSMutableDictionary new];
    [results setValuesForKeysWithDictionary:self.manualPermits];
    [results setValuesForKeysWithDictionary:self.preloadPermits];

    NSArray *retVal = [results allValues];
    [self sortPermitList:retVal];

    return retVal;
}

- (void)reloadPermits
{
    if ([self.preloadPermits count] == 0) {
        self.preloadPermits = [self readPermitFile:PreloadPermitFilePath];
    }

    if ([self.manualPermits count] == 0) {
        self.manualPermits = [self readPermitFile:ManualPermitFilePath];
    }
}

- (NSMutableDictionary*)readPermitFile:(NSString*)fileName
{
    NSError *error;
    id jsonObject;

    NSURL *filePath = [self permitFilePath:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[filePath path]]) {

        NSData *fileData = [NSData dataWithContentsOfURL:filePath];
        jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:kNilOptions error:&error];
    }
    else {
        NSLog(@"File does not exist: %@", fileName);
    }

    NSMutableDictionary *retVal = [[NSMutableDictionary alloc] init];
    if ([jsonObject isKindOfClass:[NSArray class]] && error == nil) {
        for (id item in jsonObject) {
            Permit *permitItem = [Permit modelObjectWithDictionary:item];
            [retVal setObject:permitItem forKey:permitItem.permitNumber];
        }
    }

    return retVal;
}

- (NSArray*)getAvailablePermits
{
    NSMutableArray *results = [[NSMutableArray alloc] init];

    for (Permit *permit in [self getAllPermits]) {
        if (!permit.unavailable) {
            [results addObject:permit];
        }
    }

    // Return immutable array
    return [results copy];
}

- (void)sortPermitList:(NSArray*)permitList
{
    permitList = [permitList sortedArrayUsingComparator:^NSComparisonResult(Permit *permit1, Permit *permit2) {
        return [permit1.permitNumber compare:permit2.permitNumber];
    }];
}

- (Permit*)getPermit:(NSString*)permitNumber
{
    [self reloadPermits];

    if ([self.preloadPermits objectForKey:permitNumber] != nil) {
        return [self.preloadPermits objectForKey:permitNumber];
    }

    if ([self.manualPermits objectForKey:permitNumber] != nil) {
        return [self.manualPermits objectForKey:permitNumber];
    }

    return nil;
}

- (PermitSpeciesAmounts*)getSpeciesAmountFromPermit:(Permit*)permit forSpecies:(int)speciesCode
{
    if (permit != nil) {
        for (PermitSpeciesAmounts *speciesAmount in permit.speciesAmounts) {
            if (speciesAmount.gameSpeciesCode == speciesCode) {
                return speciesAmount;
            }
        }
    }

    return nil;
}

- (void)clearPermits
{
    [self.preloadPermits removeAllObjects];
    [self.manualPermits removeAllObjects];

    NSError *error;
    NSURL *filePath = [self permitFilePath:PreloadPermitFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[filePath path]]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtURL:filePath error:&error];
        if (!success) NSLog(@"Failed to remove: %@", filePath);
    }

    filePath = [self permitFilePath:ManualPermitFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[filePath path]]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtURL:filePath error:&error];
        if (!success) NSLog(@"Failed to remove: %@", filePath);
    }
}

- (void)addManualPermit:(Permit*)permit
{
    [self reloadPermits];

    // Already has permit, do not duplicate to manual list
    if ([self.preloadPermits objectForKey:permit.permitNumber] != nil) {
        return;
    }

    [self.manualPermits setObject:permit forKey:permit.permitNumber];

    NSMutableArray *dictionaryArray = [[NSMutableArray alloc] init];
    for (Permit *item in [self.manualPermits allValues]) {
        [dictionaryArray addObject:[item dictionaryRepresentation]];
    }

    NSError *error;
    NSData *jsonArray = [NSJSONSerialization dataWithJSONObject:dictionaryArray options:kNilOptions error:&error];

    [self savePermits:jsonArray filename:ManualPermitFilePath];
}

- (void)preloadPermits:(RiistaPermitPreloadCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] preloadPermits:^(NSData *response, NSError *error) {
        if (error == nil) {
            [self savePermits:response filename:PreloadPermitFilePath];

            // Force reload the next time permits are accessed
            [self.preloadPermits removeAllObjects];
        }

        if (completion) {
            if (error) {
                completion(nil, error);
            } else {
                completion(response, nil);
            }
        }
    }];
}

- (void)savePermits:(NSData*)value filename:(NSString*)fileName
{
    NSError *error = nil;
    if (![value writeToURL:[self permitFilePath:fileName] options:0 error:&error]) {
        NSLog(@"Failed to write permits to file: %@", [error localizedDescription]);
    }
}

- (NSURL*)permitFilePath:(NSString *)fileName
{
    return [[RiistaUtils applicationDirectory] URLByAppendingPathComponent:fileName];
}

- (BOOL)validateEntryWithPermit:(DiaryEntry*)entry permit:(Permit*)permit
{
    return [self validateEntryPermitInformation:entry.gameSpeciesCode
                                    pointOfTime:entry.pointOfTime
                                         amount:entry.amount
                                       specimens:entry.specimens
                                         permit:permit];
}

- (BOOL)validateEntryPermitInformation:(NSNumber*)gameSpeciesCode
                           pointOfTime:(NSDate*)pointOfTime
                                amount:(NSNumber*)amount
                             specimens:(NSOrderedSet*)specimens
                                permit:(Permit*)permit
{
    BOOL speciesOk = false;
    BOOL dateOk = false;
    BOOL specimenOk = false;

    if (gameSpeciesCode == nil || pointOfTime == nil || amount == nil || permit == nil) {
        return NO;
    }

    PermitSpeciesAmounts *speciesAmountMatch = nil;
    for (PermitSpeciesAmounts *speciesAmount in permit.speciesAmounts) {
        if (speciesAmount.gameSpeciesCode == [gameSpeciesCode integerValue]) {
            speciesOk = YES;

            if ([RiistaDateTimeUtils betweenDatesInclusive:pointOfTime isBetweenDate:speciesAmount.beginDate andDate:speciesAmount.endDate]
                || [RiistaDateTimeUtils betweenDatesInclusive:pointOfTime isBetweenDate:speciesAmount.beginDate2 andDate:speciesAmount.endDate2]) {
                dateOk = YES;

                speciesAmountMatch = speciesAmount;
                break;
            }
        }
    }

    if (speciesAmountMatch == nil) {
        NSLog(@"Species [%@] or date [%@] does not match permit %@", gameSpeciesCode, pointOfTime, permit.permitNumber);
        return NO;
    }

    specimenOk = [self validateEntrySpecimenForPermit:amount specimens:specimens speciesAmounts:speciesAmountMatch];

    return speciesOk && dateOk && specimenOk;
}

- (BOOL)validateEntrySpecimenForPermit:(NSNumber*)amount specimens:(NSOrderedSet*)specimens speciesAmounts:(PermitSpeciesAmounts*)speciesAmounts
{
    if (speciesAmounts.ageRequired || speciesAmounts.genderRequired || speciesAmounts.weightRequired) {
        if ([amount unsignedIntegerValue] != [specimens count]) {
            NSLog(@"Amount != specimen count (%@ != %lu)", amount, (unsigned long)[specimens count]);

            return NO;
        }

        BOOL isOk = YES;

        for (RiistaSpecimen *specimen in specimens) {
            if (speciesAmounts.genderRequired && [specimen.gender length] == 0) {
                NSLog(@"Gender required");
                isOk = false;
            }

            if (speciesAmounts.ageRequired && [specimen.age length] == 0) {
                NSLog(@"Age required");
                isOk = false;
            }

            if (speciesAmounts.weightRequired && specimen.weight <= 0) {
                NSLog(@"Weight required");
                isOk = false;
            }
        }

        return isOk;
    }

    return YES;
}

- (BOOL)validateEntryPermitInformation:(DiaryEntry*)entry
{
    if (entry == nil) {
        return NO;
    }
    else if ([entry.permitNumber length] == 0) {
        return YES;
    }

    Permit *permit = [self getPermit:entry.permitNumber];
    return permit != nil && [self validateEntryWithPermit:entry permit:permit];
}

- (BOOL)isSpeciesSeasonActive:(PermitSpeciesAmounts*)speciesItem daysTolerance:(int)daysTolerance
{
    NSDate *dateNow = [RiistaDateTimeUtils removeTime:[NSDate date]];

    if ([RiistaDateTimeUtils betweenDatesInclusive:dateNow
                                     isBetweenDate:[RiistaDateTimeUtils addDays:speciesItem.beginDate daysToAdd:-daysTolerance]
                                           andDate:[RiistaDateTimeUtils addDays:speciesItem.endDate daysToAdd:daysTolerance]]) {
        return YES;
    }
    else if (speciesItem.beginDate2 != nil && speciesItem.endDate2 != nil) {
        return [RiistaDateTimeUtils betweenDatesInclusive:dateNow
                                            isBetweenDate:[RiistaDateTimeUtils addDays:speciesItem.beginDate2 daysToAdd:-daysTolerance]
                                                  andDate:[RiistaDateTimeUtils addDays:speciesItem.endDate2 daysToAdd:daysTolerance]];
    }

    return NO;
}

@end
