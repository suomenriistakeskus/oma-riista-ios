#import "RiistaGameDatabase.h"
#import "DiaryEntry.h"
#import "ObservationEntry.h"
#import "ObservationSpecimen.h"
#import "ObservationSync.h"
#import "GeoCoordinate.h"
#import "DiaryImage.h"
#import "RiistaAppDelegate.h"
#import "RiistaSpeciesCategory.h"
#import "RiistaSpecies.h"
#import "RiistaSpecimen.h"
#import "RiistaDiaryEntryUpdate.h"
#import "RiistaUtils.h"
#import "RiistaModelUtils.h"
#import "RiistaNetworkManager.h"
#import "RiistaSessionManager.h"
#import "RiistaSettings.h"
#import "UserInfo.h"
#import "SrvaSync.h"
#import "SrvaEntry.h"
#import "AnnouncementsSync.h"
#import "NSDateformatter+Locale.h"
#import "Oma_riista-Swift.h"

#import <FirebaseCrashlytics/FirebaseCrashlytics.h>


NSString *const RIISTA_FETCH_TIMES = @"FetchTimes";
const CGFloat SYNC_INTERVAL_IN_MINUTES = 5.0;
const CGFloat MIN_SYNC_INTERVAL_IN_SECONDS = 5.0;

typedef void(^RiistaDiaryEntryLoadCompletion)(NSArray *updates, NSError *error);
typedef void(^RiistaDiaryEntryYearLoadCompletion)(NSArray *updates, NSError *error);

typedef void(^RiistaObservationEntryLoadCompletion)(NSArray *updates, NSError *error);
typedef void(^RiistaObservationEntryYearLoadCompletion)(NSArray *updates, NSError *error);

@interface RiistaGameDatabase ()

@property (strong, nonatomic) NSTimer *syncTimer;
@property (assign, atomic, readwrite) BOOL synchronizing;

@end

@implementation RiistaGameDatabase
{
    NSDateFormatter *dateFormatter;
    Reachability* reachability;
    NSDate *lastSyncDate;
}

#pragma mark - public methods

NSString *const RiistaCalendarEntriesUpdatedKey = @"CalendarEntriesUpdated";
NSString *const RiistaLanguageSelectionUpdatedKey = @"LanguageSelectionUpdated";
NSString *const RiistaSynchronizationStatusKey = @"SynchronizationStatus";
NSString *const ISO_8601 = @"yyyy-MM-dd'T'HH:mm:ss.SSS";

// Start from August
NSInteger const RiistaCalendarStartMonth = 8;

+ (RiistaGameDatabase*)sharedInstance
{
    static RiistaGameDatabase *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [RiistaGameDatabase new];
        [pInst loadSpeciesDB];
    });
    return pInst;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (self) {
        _autosync = NO;
        self.synchronizing = NO;
        dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
        [dateFormatter setDateFormat:ISO_8601];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    return self;
}

- (void)initUserSession
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.username = [[RiistaSessionManager sharedInstance] userCredentials].username;
    [self initSync];
}

- (NSArray*)allEvents
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        return results;
    }
    return [NSArray new];
}

- (DiaryEntry*)diaryEntryWithId:(NSInteger)remoteId context:(NSManagedObjectContext*)context excludeObject:(NSManagedObjectID*)objectId {

    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    
    NSPredicate *predicate = nil;
    if (objectId) {
        predicate = [NSPredicate predicateWithFormat:@"remoteId = %d AND self != %@", remoteId, objectId];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"remoteId = %d", remoteId];
    }
    [fetch setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetch error:&error];
    if(results && results.count > 0) {
        return results[0];
    }
    return nil;
}

- (DiaryEntry*)diaryEntryWithId:(NSInteger)remoteId
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [self diaryEntryWithId:remoteId context:delegate.managedObjectContext excludeObject:nil];
}

- (DiaryEntry*)diaryEntryWithObjectId:(NSManagedObjectID*)objectId context:(NSManagedObjectContext*)context
{
    NSError *error = nil;
    DiaryEntry *result = (DiaryEntry*)[context existingObjectWithID:objectId error:&error];
    return result;
}

- (void)addLocalEvent:(DiaryEntry*)diaryEntry
{
    NSManagedObjectContext *context = [diaryEntry managedObjectContext];
    NSError *error;
    if ([context save:&error]) {
        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.entry = diaryEntry;
        update.type = UpdateTypeInsert;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)editLocalEvent:(DiaryEntry*)diaryEntry newImages:(NSArray*)images
{
    [self editImagesForDiaryEntry:diaryEntry newImages:images];
    
    NSError *error = nil;
    if ([[diaryEntry managedObjectContext] save:&error]) {
        // Modifying child context. Save parent to persistent store
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            [delegate.managedObjectContext save:&mErr];
        }];

        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.entry = diaryEntry;
        update.type = UpdateTypeUpdate;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)deleteLocalEvent:(DiaryEntry*)diaryEntry
{
    diaryEntry.sent = @(NO);
    diaryEntry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationDelete];

    NSError *error = nil;
    if ([[diaryEntry managedObjectContext] save:&error]) {

        // Modifying child context. Save parent to persistent store
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            [delegate.managedObjectContext save:&mErr];
        }];

        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.entry = diaryEntry;
        update.type = UpdateTypeDelete;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (BOOL)insertReceivedEvent:(DiaryEntry*)diaryEntry context:(NSManagedObjectContext*)context
{
    // In main context the saves are not yet changed, use it to get the old values
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    DiaryEntry *existingEntry = [self diaryEntryWithId:[diaryEntry.remoteId integerValue] context:delegate.managedObjectContext excludeObject:nil];

    if (!existingEntry
        || [diaryEntry.rev integerValue] > [existingEntry.rev integerValue]
        || ([diaryEntry.rev integerValue] == [existingEntry.rev integerValue] && ([existingEntry.sent boolValue] || ![self sameReportInfoInEntry:existingEntry andNewEntry:diaryEntry]))
        || ([diaryEntry.harvestSpecVersion integerValue] > [existingEntry.harvestSpecVersion integerValue])
        ) {
        diaryEntry.remote = @(YES);
        diaryEntry.sent = @(YES);

        // If the entry doesn't have modifications, don't send update
        if (existingEntry && [existingEntry.rev integerValue] == [diaryEntry.rev integerValue]
            && [self sameImagesInEntry:existingEntry andNewEntry:diaryEntry]
            && [self sameReportInfoInEntry:existingEntry andNewEntry:diaryEntry]
            && [self sameSpecimenInfoInEntry:existingEntry andNewEntry:diaryEntry]
            ) {
            return NO;
        }
        return YES;
    }
    else if (existingEntry && ([diaryEntry.rev integerValue] == [existingEntry.rev integerValue] && ![existingEntry.sent boolValue])) {
        // in most cases we want to preserve local changes that have not yet been sent. There are, however, few
        // log entries in the backend logs that describe a situation where diary entries have same revision but
        // the backend has a newer specimen than what the client seems to have.
        // -> replace local diary entries in these cases
        if ([existingEntry shouldSpecimensBeUpdatedWithRemoteEntry:diaryEntry]) {
            return YES;
        }
        // Special case: existing event needs to preserved since it contains changes that have not yet been sent
        [[diaryEntry managedObjectContext] refreshObject:diaryEntry mergeChanges:NO];
    }

    return NO;
}

- (void)clearEvents
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        NSError *error;
        for (int i=0; i<results.count; i++) {
            [delegate.managedObjectContext deleteObject:results[i]];
        }
        [delegate.managedObjectContext save:&error];
    }
}

- (NSArray*)clearSentEventsFromYear:(NSInteger)year
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((year = %d AND month >= %d) OR (year = %d AND month < %d)) AND remote = %@", year, RiistaCalendarStartMonth, year+1, RiistaCalendarStartMonth, @(YES)];
    [fetch setPredicate:predicate];
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        NSMutableArray *updates = [NSMutableArray new];
        NSError *error;
        for (int i=0; i<results.count; i++) {
            RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
            update.entry = results[i];
            update.type = UpdateTypeDelete;
            [updates addObject:update];
            [delegate.managedObjectContext deleteObject:results[i]];
        }
        if ([delegate.managedObjectContext save:&error])
            return updates;
    }
    return nil;
}

- (NSArray*)eventYears:(NSString*)eventType
{
    NSString *entityName = nil;
    if ([eventType isEqualToString:DiaryEntryTypeHarvest]) {
        entityName = @"DiaryEntry";
    }
    else if ([eventType isEqualToString:DiaryEntryTypeObservation]) {
        entityName = @"ObservationEntry";
    }
    else if ([eventType isEqualToString:DiaryEntryTypeSrva]) {
        entityName = @"SrvaEntry";
    }

    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *ctx = delegate.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:ctx];
    NSDictionary *entityProperties = [entity propertiesByName];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [fetch setReturnsDistinctResults:YES];
    [fetch setPropertiesToFetch:@[[entityProperties objectForKey:@"month"], [entityProperties objectForKey:@"year"]]];

    NSSortDescriptor *yearDescriptor = [[NSSortDescriptor alloc] initWithKey:@"year" ascending:YES];
    NSSortDescriptor *monthDescriptor = [[NSSortDescriptor alloc] initWithKey:@"month" ascending:YES];

    [fetch setSortDescriptors:@[yearDescriptor, monthDescriptor]];
    NSArray *result = [ctx executeFetchRequest:fetch error:nil];
    if (result) {
        NSMutableArray *startYears = [NSMutableArray new];
        for (int i=0; i<result.count; i++) {
            NSNumber *year = 0;
            DiaryEntryBase *base = result[i];

            if ([base isKindOfClass:[DiaryEntry class]]) {
                DiaryEntry *entry = (DiaryEntry*)base;
                if ([entry.month integerValue] >= RiistaCalendarStartMonth) {
                    year = entry.year;
                }
                else {
                    year = @([entry.year integerValue]-1);
                }
            }
            else if ([base isKindOfClass:[ObservationEntry class]]) {
                ObservationEntry* observation = (ObservationEntry*)base;
                if ([observation.month integerValue] >= RiistaCalendarStartMonth) {
                    year = observation.year;
                }
                else {
                    year = @([observation.year integerValue]-1);
                }
            }
            else if ([base isKindOfClass:[SrvaEntry class]]) {
                SrvaEntry *srva = (SrvaEntry*)base;
                year = @([srva.year integerValue]-1);
            }

            if (![startYears containsObject:year]) {
                [startYears addObject:year];
            }
        }
        return startYears;
    }
    return [NSArray new];
}

- (SeasonStats *)statsForHarvestSeason:(NSInteger)startYear
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    // Ignore deleted harvests
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((year = %d AND month >= %d) OR (year = %d AND month < %d)) AND (pendingOperation != %d)",
                              startYear,
                              RiistaCalendarStartMonth,
                              startYear + 1,
                              RiistaCalendarStartMonth,
                              DiaryEntryOperationDelete];
    [fetch setPredicate:predicate];

    SeasonStats *season = [SeasonStats empty];
    season.startYear = startYear;

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];

    if(results) {
        NSMutableArray *monthAmounts = [season mutableMonthArray];

        for (int i = 0; i < results.count; i++) {
            DiaryEntry *harvest = results[i];

            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:harvest.pointOfTime];
            // Month range is 1-12
            NSInteger monthIndex = components.month - 1;

            monthAmounts[monthIndex] = [NSNumber numberWithInt:([monthAmounts[monthIndex] intValue] + [harvest.amount intValue])];

            RiistaSpecies *species = [self speciesById:[harvest.gameSpeciesCode integerValue]];

            if ([harvest.type isEqual:DiaryEntryTypeHarvest] && species) {
                NSNumber *prevValue = season.catValues[species.categoryId - 1];
                season.catValues[species.categoryId - 1] = [NSNumber numberWithInt: prevValue.intValue + [harvest.amount intValue]];
            }
            season.totalAmount += [harvest.amount integerValue];
        }

        season.monthAmounts = monthAmounts;
    }

    return season;
}

#pragma mark - Species

- (void)loadSpeciesDB
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"species" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

    NSMutableDictionary *categories = [NSMutableDictionary new];
    NSArray *categoryList = (NSArray*)json[@"categories"];
    for (int i=0; i<categoryList.count; i++) {
        RiistaSpeciesCategory *category = [RiistaSpeciesCategory new];
        category.categoryId = [categoryList[i][@"id"] integerValue];
        category.name = (NSDictionary*)categoryList[i][@"name"];
        categories[[NSNumber numberWithInteger:category.categoryId]] = category;
    }

    _categories = categories;
    
    NSMutableDictionary *speciesDict = [NSMutableDictionary new];
    NSArray *speciesList = (NSArray*)json[@"species"];
    for (int i=0; i<speciesList.count; i++) {
        RiistaSpecies *species = [RiistaSpecies new];
        species.speciesId = [speciesList[i][@"id"] integerValue];
        species.name = (NSDictionary*)speciesList[i][@"name"];
        species.categoryId = [speciesList[i][@"categoryId"] integerValue];
        if (speciesList[i][@"imageUrl"] && ![speciesList[i][@"imageUrl"] isEqual: [NSNull null]]) {
            species.imageUrl = [NSURL URLWithString:(NSString*)speciesList[i][@"imageUrl"]];
        }
        species.multipleSpecimenAllowedOnHarvests = [speciesList[i][@"multipleSpecimenAllowedOnHarvests"] boolValue];
        speciesDict[[NSNumber numberWithInteger:species.speciesId]] = species;
    }
    _species = speciesDict;
}

- (NSArray*)speciesListWithCategoryId:(NSInteger)categoryId;
{
    NSMutableArray *speciesList = [NSMutableArray new];
    id key;
    NSEnumerator *enumerator = [self.species keyEnumerator];
    while ((key = [enumerator nextObject])) {
        RiistaSpecies *species = (RiistaSpecies*)[self.species objectForKey:key];
        if (species.categoryId == categoryId) {
            [speciesList addObject:species];
        }
    }
    return speciesList;
}

- (RiistaSpecies*)speciesById:(NSInteger)speciesId
{
    if ([self.species objectForKey:[NSNumber numberWithInteger:speciesId]]) {
        return self.species[[NSNumber numberWithInteger:speciesId]];
    }
    return nil;
}

- (NSArray*)latestEventSpecies:(NSInteger)amount
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"pointOfTime" ascending:NO];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryEntry" inManagedObjectContext:delegate.managedObjectContext];
    fetch.entity = entity;
    [fetch setSortDescriptors:@[dateSort]];
    fetch.resultType = NSManagedObjectResultType;
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if (results && results.count > 0) {
        NSMutableArray *species = [NSMutableArray new];
        for (DiaryEntry *diaryEntry in results) {
            if (![species containsObject:diaryEntry.gameSpeciesCode] && [diaryEntry.pendingOperation integerValue] != DiaryEntryOperationDelete) {
                [species addObject:diaryEntry.gameSpeciesCode];
                if (species.count == amount)
                    break;
            }
        }
        return [species copy];
    }
    return nil;
}

- (void)doAutoSync
{
    [self synchronizeDiaryEntries:^(void) {
        // nop
    }];
}

- (void)synchronizeDiaryEntries:(RiistaSynchronizationCompletion)completion
{
    // Do not start multiple synchronization operations at once
    if (self.synchronizing) {
        if (completion) {
            completion();
        }
        return;
    }
    self.synchronizing = YES;

    [RiistaSDKHelper synchronizeWithCompletion:^{
        [self doSynchronizeDiaryEntries:^(void) {
            self.synchronizing = NO;
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)doSynchronizeDiaryEntries:(RiistaSynchronizationCompletion)completion
{
    // Limit rate of user synchronization attempts
    if (lastSyncDate && [lastSyncDate timeIntervalSinceNow] > -MIN_SYNC_INTERVAL_IN_SECONDS) {
        if (completion) {
            completion();
        }
        return;
    }

    lastSyncDate = [NSDate date];

    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaSynchronizationStatusKey object:nil userInfo:@{@"syncing": @YES}];
    [CrashlyticsHelper logWithMsg:@"Synchronizing diary entries.."];

    __weak RiistaGameDatabase *weakSelf = self;
    [self loadDiaryEntries:YES completion:^(NSArray *received, NSError* loadError) {
        [weakSelf sendUnsentDiaryEntries:NO completion:^(NSArray *sent, NSError* sendError) {
            NSArray *updates = (received != nil) ? received : @[];
            if (sent != nil && sent.count > 0 && !sendError) {
                updates = [received arrayByAddingObjectsFromArray:sent];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":updates}];

            SrvaSync *srvaSync = [[SrvaSync alloc] init];
            [srvaSync sync:^{
                ObservationSync *observationSync = [[ObservationSync alloc] init];
                [observationSync sync:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:nil];

                    [[AnnouncementsSync new] sync:^(NSArray *items, NSError *error) {
                        [MhPermitSync.shared syncWithCompletion:^(NSArray *items, NSError *error) {

                            [[NSNotificationCenter defaultCenter] postNotificationName:RiistaSynchronizationStatusKey object:nil userInfo:@{@"syncing": @NO}];
                            [CrashlyticsHelper logWithMsg:@"Diary entry synchronization completed!"];

                            if (completion) {
                                completion();
                            }
                        }];
                    }];
                }];
            }];
        }];
    }];
}

- (void)sendAndNotifyUnsentDiaryEntries:(RiistaDiaryEntryUploadCompletion)completion
{
    [self sendUnsentDiaryEntries:YES completion:^(NSArray *sent, NSError* error) {
        if (sent == nil) {
            sent = @[];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":sent}];
    }];
}

- (void)editDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryEditCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] sendDiaryEntry:diaryEntry completion:^(NSDictionary *response, NSError *error) {
        if (completion) {
            if (!error) {
                [self submitDiaryImagesFromEntry:diaryEntry completion:^(BOOL errors) {
                    // Mark successfully edited event as sent
                    NSError *err = nil;
                    diaryEntry.remoteId = response[@"id"];
                    diaryEntry.rev = response[@"rev"];
                    diaryEntry.harvestSpecVersion = response[@"harvestSpecVersion"];
                    diaryEntry.harvestReportDone = response[@"harvestReportDone"];
                    diaryEntry.harvestReportRequired = response[@"harvestReportRequired"];
                    if ([response objectForKey:@"harvestReportState"] && ![response[@"harvestReportState"] isEqual:[NSNull null]]) {
                        diaryEntry.harvestReportState = response[@"harvestReportState"];
                    }
                    else {
                        diaryEntry.harvestReportState = nil;
                    }
                    if ([response objectForKey:@"stateAcceptedToHarvestPermit"] && ![response[@"stateAcceptedToHarvestPermit"] isEqual:[NSNull null]]) {
                        diaryEntry.stateAcceptedToHarvestPermit = response[@"stateAcceptedToHarvestPermit"];
                    }
                    else {
                        diaryEntry.stateAcceptedToHarvestPermit = nil;
                    }
                    if ([response objectForKey:@"deerHuntingType"] && ![response[@"deerHuntingType"] isEqual:[NSNull null]]) {
                        diaryEntry.deerHuntingType = response[@"deerHuntingType"];
                    } else {
                        diaryEntry.deerHuntingType = nil;
                    }
                    if ([response objectForKey:@"deerHuntingOtherTypeDescription"] && ![response[@"deerHuntingOtherTypeDescription"] isEqual:[NSNull null]]) {
                        diaryEntry.deerHuntingTypeDescription = response[@"deerHuntingOtherTypeDescription"];
                    } else {
                        diaryEntry.deerHuntingTypeDescription = nil;
                    }
                    if ([response objectForKey:@"huntingMethod"] && ![response[@"huntingMethod"] isEqual:[NSNull null]]) {
                        diaryEntry.huntingMethod = response[@"huntingMethod"];
                    } else {
                        diaryEntry.huntingMethod = nil;
                    }
                    if ([response objectForKey:@"feedingPlace"] && ![response[@"feedingPlace"] isEqual:[NSNull null]]) {
                        diaryEntry.feedingPlace = response[@"feedingPlace"];
                    } else {
                        diaryEntry.feedingPlace = nil;
                    }
                    if ([response objectForKey:@"taigaBeanGoose"] && ![response[@"taigaBeanGoose"] isEqual:[NSNull null]]) {
                        diaryEntry.taigaBeanGoose = response[@"taigaBeanGoose"];
                    } else {
                        diaryEntry.taigaBeanGoose = nil;
                    }
                    diaryEntry.canEdit = response[@"canEdit"];
                    diaryEntry.remote = [NSNumber numberWithBool:YES];

                    NSArray *specimens = response[@"specimens"];
                    [self setSpecimensFromJson:diaryEntry specimenItems:specimens];

                    diaryEntry.sent = @(!errors);
                    if ([[diaryEntry managedObjectContext] save:&err]) {
                        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                        update.entry = diaryEntry;
                        update.type = UpdateTypeUpdate;
                        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
                    }
                    completion(response, nil);
                }];
            } else {
                completion(nil, error);
            }
        }
    }];
}

- (void)deleteDiaryEntry:(DiaryEntry*)diaryEntry completion:(RiistaDiaryEntryDeleteCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] sendDiaryEntry:diaryEntry completion:^(NSDictionary *response, NSError *error) {
        if (completion) {
            if (!error) {
                    // Mark successfully edited event as sent
                    NSError *err = nil;
                    diaryEntry.sent = [NSNumber numberWithBool:YES];
                    if ([[diaryEntry managedObjectContext] save:&err]) {
                        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                        update.entry = diaryEntry;
                        update.type = UpdateTypeDelete;
                        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
                    }
                    completion(nil);
            } else {
                completion(error);
            }
        }
    }];
}

- (void)submitDiaryImagesFromEntry:(DiaryEntry*)diaryEntry completion:(DiaryImageSubmitCompletion)completion
{
    if (diaryEntry.diaryImages.count == 0) {
        completion(NO);
        return;
    }

    __block BOOL errors = NO;
    __block NSInteger sentImages = 0;
    NSMutableArray *images = [[diaryEntry.diaryImages allObjects] mutableCopy];
    int originalCount = (int)images.count;

    for (int i=(int)images.count-1; i>=0; i--) {

        DiaryImage *image = images[i];

        [[RiistaNetworkManager sharedInstance] diaryEntryImageOperationForImage:image diaryEntry:diaryEntry completion:^(NSError* error) {
            if (!error) {
                if ([image.status integerValue] == DiaryImageStatusInsertion) {
                    image.type = [NSNumber numberWithInteger:DiaryImageTypeRemote];
                    image.status = 0;

                    NSError *err = nil;
                    [[image managedObjectContext] save:&err];
                } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
                    [images removeObject:image];
                }
            } else if ([image.status integerValue] == DiaryImageStatusDeletion && error.code == 404) {
                // Unsuccessful deletion of already deleted image can be ignored
                [images removeObject:image];
            } else {
                errors = YES;
            }
            sentImages++;
            if (sentImages == originalCount) {
                diaryEntry.diaryImages = [NSSet setWithArray:[images copy]];
                NSError *err = nil;
                [[diaryEntry managedObjectContext] save:&err];
                if (completion)
                    completion(errors);
            }
        }];
    }
}

- (void)editImagesForDiaryEntry:(DiaryEntry*)diaryEntry newImages:(NSArray*)images
{
    NSMutableArray *currentImages = [[diaryEntry.diaryImages allObjects] mutableCopy];
    NSMutableArray *addedImages = [images mutableCopy];
    
    NSInteger originalCount = currentImages.count;
    for (int i=(int)originalCount-1; i>=0; i--) {
        BOOL found = NO;
        NSUInteger foundImageIndex = 0;
        for (int i2=0; i2<addedImages.count; i2++) {
            if ([((DiaryImage*)currentImages[i]).imageid isEqual:((DiaryImage*)addedImages[i2]).imageid]) {
                foundImageIndex = i2;
                found = YES;
            }
        }
        if (found) {
            ((DiaryImage*)addedImages[foundImageIndex]).status = 0;
            [addedImages removeObjectAtIndex:foundImageIndex];
        } else {
            if ([((DiaryImage*)currentImages[i]).status integerValue] == DiaryImageStatusInsertion) {
                // Image hasn't been sent yet so it can be deleted
                [diaryEntry removeDiaryImagesObject:currentImages[i]];
            } else {
                // If a image isn't in the list of new images, it is marked as pending deletion
                // User doesn't supply images that are already pending deletion. Those images are marked as pending deletion again
                ((DiaryImage*)currentImages[i]).status = [NSNumber numberWithInteger:DiaryImageStatusDeletion];
            }
        }
    }
    // Insert images that did not already exist
    for (int i=0; i<addedImages.count; i++) {
        ((DiaryImage*)addedImages[i]).status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
        [diaryEntry addDiaryImagesObject:addedImages[i]];
    }
}

- (NSArray*)diaryEntriesFromDictValues:(NSArray*)dictValues context:(NSManagedObjectContext*)context
{
    NSMutableArray *entries = [NSMutableArray new];
    for (int i=0; i<dictValues.count; i++) {
        [entries addObject:[self diaryEntryFromDict:dictValues[i] context:context]];
    }
    return [entries copy];
}

- (void)setAutosync:(BOOL)enabled
{
    _autosync = enabled;
    if (enabled) {
        reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        [self doAutoSync];
        self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:SYNC_INTERVAL_IN_MINUTES*60 target:self selector:@selector(doAutoSync) userInfo:nil repeats:YES];
    } else {
        if (reachability) {
            [reachability stopNotifier];
        }
        if (self.syncTimer) {
            [self.syncTimer invalidate];
            self.syncTimer = nil;
        }
    }
}

- (void)userImagesWithCurrentImage:(DiaryImage*)image entryType:(NSString*)entryType completion:(RiistaUserImageLoadCompletion)completion;
{
    NSFetchRequest *fetch;
    if ([entryType isEqualToString:DiaryEntryTypeObservation]) {
        fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];
    }
    else if ([entryType isEqualToString:DiaryEntryTypeSrva]) {
        fetch = [NSFetchRequest fetchRequestWithEntityName:@"SrvaEntry"];
    }
    else if ([entryType isEqualToString:DiaryEntryTypeHarvest]) {
        fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    }

    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"pointOfTime" ascending:NO];
    [fetch setSortDescriptors:@[dateSort]];

    NSError *error = nil;
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if (results) {
        NSMutableArray *resultImages = [NSMutableArray new];
        for (int i=0; i<results.count; i++) {
            DiaryEntry *entry = results[i];
            for (DiaryImage *image in entry.diaryImages) {
                if ([image.status integerValue] != DiaryImageStatusDeletion)
                    [resultImages addObject:image];
            }
        }

        NSUInteger currentIndex = [resultImages indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([((DiaryImage*)obj).objectID isEqual:image.objectID]) {
                *stop = YES;
                return YES;
            }
                 return NO;
        }];

        completion(resultImages, currentIndex);
        return;
    }
    completion(nil, 0);
}

#pragma mark - private methods

- (void)loadDiaryEntries:(BOOL)retry completion:(RiistaDiaryEntryLoadCompletion)completion
{
    [CrashlyticsHelper logWithMsg:@"Loading diary entries.."];

    NSMutableArray *allLoadedEntries = [NSMutableArray new];
    __block NSInteger yearsLoaded = 0;
    __weak RiistaGameDatabase *weakSelf = self;
    RiistaNetworkManager *manager = [RiistaNetworkManager sharedInstance];
    
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = delegate.managedObjectContext;
    
    NSArray *localYears = [self eventYears:DiaryEntryTypeHarvest];

    [SynchronizationAnalytics sendLoadingHarvestsBegin];

    [manager diaryEntryYears:retry completion:^(NSArray *years, NSError *error) {

        // Clear data from years which do not have any events
        // This can happen if all events from certain year are deleted
        if (localYears) {
            for (int i=0; i<localYears.count; i++) {
                if (!error && (years.count == 0 || ![years containsObject:localYears[i]])) {
                    NSArray *deletedEvents = [self clearSentEventsFromYear:[localYears[i] integerValue]];
                    if (deletedEvents)
                        [allLoadedEntries addObjectsFromArray:deletedEvents];
                }
            }
        }

        if (error) {
            [SynchronizationAnalytics sendLoadingHarvestsFailed];

            if (completion) {
                [CrashlyticsHelper logWithMsg:@"Failed to load diary entry years!"];
                completion(nil, error);
            }
            return;
        }

        if (years.count == 0) {
            [SynchronizationAnalytics sendLoadingHarvestsCompletedWithUpdatedHarvestCount: 0
                                                                      removedHarvestCount: 0];

            if (completion) {
                [CrashlyticsHelper logWithMsg:@"No diary entry years -> nothing to load!"];
                completion([allLoadedEntries copy], nil);
            }
            return;
        }

        for (int i=0; i<years.count; i++) {
            NSInteger year = [years[i] integerValue];
            [weakSelf loadDiaryEntriesForYear:year context:temporaryContext completion:^(NSArray* loadedEntries, NSError* error) {
                // Update latest fetch date
                [weakSelf updateFetchDateForYear:year date:[NSDate date]];

                [allLoadedEntries addObjectsFromArray:loadedEntries];
                yearsLoaded++;
                if (yearsLoaded == years.count) {
                    [CrashlyticsHelper logWithMsg:@"Finished loading diary entries for all years"];

                    int updatedCount = 0;
                    int removedCount = 0;
                    RiistaDiaryEntryUpdate *current;
                    for (int entryIndex = 0; entryIndex < allLoadedEntries.count; entryIndex++) {
                        current = (RiistaDiaryEntryUpdate *)(allLoadedEntries[entryIndex]);
                        if (current) {
                            if (current.type == UpdateTypeInsert || current.type == UpdateTypeUpdate) {
                                updatedCount++;
                            } else if (current.type == UpdateTypeDelete) {
                                removedCount++;
                            }
                        }
                    }

                    [SynchronizationAnalytics sendLoadingHarvestsCompletedWithUpdatedHarvestCount: updatedCount
                                                                              removedHarvestCount: removedCount];

                    if (completion) {
                        completion(allLoadedEntries, nil);
                    }
                }
            }];
        }
    }];
}

- (void)loadDiaryEntriesForYear:(NSInteger)year context:(NSManagedObjectContext*)context completion:(RiistaDiaryEntryYearLoadCompletion)completion
{
    NSMutableArray *updates = [NSMutableArray new];
    NSMutableArray *currentEntries = [NSMutableArray new];

    __weak RiistaGameDatabase *weakSelf = self;
    RiistaNetworkManager *manager = [RiistaNetworkManager sharedInstance];
    [manager diaryEntriesForYear:(NSInteger)year context:context completion:^(NSArray *jsonArray, NSError *error) {

        if (error) {
            if (completion)
                completion(nil, error);
            return;
        }

        [context performBlock:^(void) {
        
            NSArray *entries = [self diaryEntriesFromDictValues:jsonArray context:context];
                
            for (int i=0; i<entries.count; i++) {
                [currentEntries addObject:((DiaryEntry*)entries[i]).objectID];
                if ([weakSelf insertReceivedEvent:entries[i] context:context]) {
                    RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                    update.entry = entries[i];
                    update.type = UpdateTypeInsert;
                    [updates addObject:update];
                }
            }
            
            // Delete entries that do not exist any more
            NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((year = %d AND month >= %d) OR (year = %d AND month < %d)) AND NOT (self IN %@) AND remote = %@", year, RiistaCalendarStartMonth, year+1, RiistaCalendarStartMonth, currentEntries, [NSNumber numberWithBool:YES]];
            [fetch setPredicate:predicate];
            NSError *fetchError = nil;
            NSArray *results = [context executeFetchRequest:fetch error:&fetchError];
            if (results) {
                for (int i=0; i<results.count; i++) {
                    RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                    update.entry = results[i];
                    update.type = UpdateTypeDelete;
                    [updates addObject:update];
                    [context deleteObject:results[i]];
                }
            }
            
            // Push changes to parent
            NSError *err = nil;
            if ([context save:&err]) {
                // Save changes
                RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
                [delegate.managedObjectContext performBlock:^(void) {
                    NSError *mErr = nil;
                    if ([delegate.managedObjectContext save:&mErr]) {
                        if (completion) {
                            completion(updates, nil);
                            return;
                        }
                    } else if (completion) {
                        completion(@[], nil);
                    }
                }];
            } else if (completion) {
                completion(@[], nil);
            }
        }];
    }];
}

- (NSArray*)unsentDiaryEntries
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sent = %@", [NSNumber numberWithBool:NO]];
    [fetch setPredicate:predicate];

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        return results;
    }
    return [NSArray new];
}

- (void)sendUnsentDiaryEntries:(BOOL)retry completion:(RiistaDiaryEntryUploadCompletion)completion
{
    __weak RiistaGameDatabase *weakSelf = self;
    __block NSInteger sentEntries = 0;
    __block NSInteger sendSuccessCount = 0;
    __block NSInteger sendFailureCount = 0;
    NSMutableArray *updates = [NSMutableArray new];
    NSArray *unsentEntries = [self unsentDiaryEntries];

    [SynchronizationAnalytics sendHarvestSendBeginWithUnsentHarvestCount: unsentEntries.count];
    if (unsentEntries.count == 0) {
        // counter-part for begin. Added so that it is possible to create funnels i.e. data is now skewed.
        [SynchronizationAnalytics sendHarvestSendCompletedWithSuccessCount: sendSuccessCount
                                                              failureCount: sendFailureCount];
        completion(updates, nil);
        return;
    }

    [[FIRCrashlytics crashlytics] logWithFormat:@"Synchronizing %lu unsent diary entries..", (unsigned long)unsentEntries.count];

    __block BOOL finished = NO;

    for (int i=0; i<unsentEntries.count; i++) {
        DiaryEntry *entry = unsentEntries[i];
        [[RiistaNetworkManager sharedInstance] sendDiaryEntry:entry completion:^(NSDictionary *response, NSError *error) {

            // When user doesn't have a session, it is pointless to continue sending events
            if (!finished && (error.code == 401 || error.code == 403)) {
                [[FIRCrashlytics crashlytics] logWithFormat:@"Failed to synchronize unsent diary entry at index %d (error code = %ld)", i, (long)error.code];
                [SynchronizationAnalytics sendHarvestSendFailedWithStatusCode: error.code];

                finished = YES;
                if (retry) {
                    RiistaCredentials *credentials = [[RiistaSessionManager sharedInstance] userCredentials];
                    if (credentials) {
                        [[RiistaNetworkManager sharedInstance] relogin:credentials.username password:credentials.password completion:^(NSError *error) {
                            if (!error) {
                                [weakSelf sendUnsentDiaryEntries:NO completion:completion];
                            } else {
                                completion(nil, error);
                            }
                        }];
                    } else {
                        // Credentials were not available
                        NSError *error = [NSError errorWithDomain:RiistaLoginDomain code:0 userInfo:nil];
                        completion(nil, error);
                    }
                } else if (completion) {
                    completion(nil, error);
                }
                return;
            }

            if (!error) {
                sendSuccessCount++;

                entry.remoteId = response[@"id"];
                entry.rev = response[@"rev"];
                entry.harvestSpecVersion = response[@"harvestSpecVersion"];
                entry.harvestReportDone = response[@"harvestReportDone"];
                entry.harvestReportRequired = response[@"harvestReportRequired"];
                if ([response objectForKey:@"harvestReportState"] && ![response[@"harvestReportState"] isEqual:[NSNull null]]) {
                    entry.harvestReportState = response[@"harvestReportState"];
                }
                else {
                    entry.harvestReportState = nil;
                }
                if ([response objectForKey:@"stateAcceptedToHarvestPermit"] && ![response[@"stateAcceptedToHarvestPermit"] isEqual:[NSNull null]]) {
                    entry.stateAcceptedToHarvestPermit = response[@"stateAcceptedToHarvestPermit"];
                }
                else {
                    entry.stateAcceptedToHarvestPermit = nil;
                }
                if ([response objectForKey:@"deerHuntingType"] && ![response[@"deerHuntingType"] isEqual:[NSNull null]]) {
                    entry.deerHuntingType = response[@"deerHuntingType"];
                } else {
                    entry.deerHuntingType = nil;
                }
                if ([response objectForKey:@"deerHuntingOtherTypeDescription"] && ![response[@"deerHuntingOtherTypeDescription"] isEqual:[NSNull null]]) {
                    entry.deerHuntingTypeDescription = response[@"deerHuntingOtherTypeDescription"];
                } else {
                    entry.deerHuntingTypeDescription = nil;
                }
                if ([response objectForKey:@"huntingMethod"] && ![response[@"huntingMethod"] isEqual:[NSNull null]]) {
                    entry.huntingMethod = response[@"huntingMethod"];
                } else {
                    entry.huntingMethod = nil;
                }
                if ([response objectForKey:@"feedingPlace"] && ![response[@"feedingPlace"] isEqual:[NSNull null]]) {
                    entry.feedingPlace = response[@"feedingPlace"];
                } else {
                    entry.feedingPlace = nil;
                }
                if ([response objectForKey:@"taigaBeanGoose"] && ![response[@"taigaBeanGoose"] isEqual:[NSNull null]]) {
                    entry.taigaBeanGoose = response[@"taigaBeanGoose"];
                } else {
                    entry.taigaBeanGoose = nil;
                }
                entry.canEdit = response[@"canEdit"];
                entry.remote = [NSNumber numberWithBool:YES];

                NSArray *specimens = response[@"specimens"];
                [self setSpecimensFromJson:entry specimenItems:specimens];

                [self submitDiaryImagesFromEntry:unsentEntries[i] completion:^(BOOL errors) {
                    entry.sent = @(!errors);
                    
                    NSError *err = nil;
                    if ([[entry managedObjectContext] save:&err]) {
                        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                        update.type = UpdateTypeUpdate;
                        update.entry = entry;
                        [updates addObject:update];
                    }
                    sentEntries++;
                    if (sentEntries == unsentEntries.count) {
                        [SynchronizationAnalytics sendHarvestSendCompletedWithSuccessCount: sendSuccessCount
                                                                              failureCount: sendFailureCount];

                        completion(updates, nil);
                    }
                }];
            } else {
                sendFailureCount++;

                entry.sent = [NSNumber numberWithBool:NO];
                NSError *err = nil;
                [[entry managedObjectContext] save:&err];
                sentEntries++;
                if (sentEntries == unsentEntries.count) {
                    [SynchronizationAnalytics sendHarvestSendCompletedWithSuccessCount: sendSuccessCount
                                                                          failureCount: sendFailureCount];
                    completion(updates, nil);
                }
            }
        }];
    }
}

- (DiaryEntry*)diaryEntryFromDict:(NSDictionary*)dict context:(NSManagedObjectContext*)context
{
    GeoCoordinate *coordinates = [RiistaModelUtils coordinatesFromDict:dict context:context];

    NSMutableArray *diaryImages = [NSMutableArray new];
    NSEntityDescription *imageEntity = [NSEntityDescription entityForName:@"DiaryImage" inManagedObjectContext:context];
    for (int i=0; i<((NSArray*)dict[@"imageIds"]).count; i++) {
        DiaryImage *image = (DiaryImage*)[[NSManagedObject alloc] initWithEntity:imageEntity insertIntoManagedObjectContext:context];
        image.type = [NSNumber numberWithInteger:DiaryImageTypeRemote];
        image.imageid = dict[@"imageIds"][i];
        [diaryImages addObject:image];
    }

    NSMutableArray *specimens = [NSMutableArray new];
    NSMutableArray *items = dict[@"specimens"];
    NSEntityDescription *specimenEntity = [NSEntityDescription entityForName:@"Specimen" inManagedObjectContext:context];

    if (items && ![items isEqual:[NSNull null]]) {
        for (NSDictionary *item in items) {
            RiistaSpecimen *specimen = (RiistaSpecimen*)[[NSManagedObject alloc] initWithEntity:specimenEntity insertIntoManagedObjectContext:context];
            specimen.remoteId = item[@"id"];
            specimen.rev = item[@"rev"];
            specimen.age = ![item[@"age"] isEqual:[NSNull null]] ? item[@"age"] : nil;
            specimen.gender = ![item[@"gender"] isEqual:[NSNull null]] ? item[@"gender"] : nil;
            specimen.weight = ![item[@"weight"] isEqual:[NSNull null]] ? item[@"weight"] : nil;
            specimen.weightEstimated = ![item[@"weightEstimated"] isEqual:[NSNull null]] ? item[@"weightEstimated"] : nil;
            specimen.weightMeasured = ![item[@"weightMeasured"] isEqual:[NSNull null]] ? item[@"weightMeasured"] : nil;
            specimen.fitnessClass = ![item[@"fitnessClass"] isEqual:[NSNull null]] ? item[@"fitnessClass"] : nil;
            specimen.antlersType = ![item[@"antlersType"] isEqual:[NSNull null]] ? item[@"antlersType"] : nil;
            specimen.antlersWidth = ![item[@"antlersWidth"] isEqual:[NSNull null]] ? item[@"antlersWidth"] : nil;
            specimen.antlerPointsLeft = ![item[@"antlerPointsLeft"] isEqual:[NSNull null]] ? item[@"antlerPointsLeft"] : nil;
            specimen.antlerPointsRight = ![item[@"antlerPointsRight"] isEqual:[NSNull null]] ? item[@"antlerPointsRight"] : nil;
            specimen.antlersLost = ![item[@"antlersLost"] isEqual:[NSNull null]] ? item[@"antlersLost"] : nil;
            specimen.antlersGirth = ![item[@"antlersGirth"] isEqual:[NSNull null]] ? item[@"antlersGirth"] : nil;
            specimen.antlersLength = ![item[@"antlersLength"] isEqual:[NSNull null]] ? item[@"antlersLength"] : nil;
            specimen.antlersInnerWidth = ![item[@"antlersInnerWidth"] isEqual:[NSNull null]] ? item[@"antlersInnerWidth"] : nil;
            // note different field in DTO / JSON
            specimen.antlersShaftWidth = ![item[@"antlerShaftWidth"] isEqual:[NSNull null]] ? item[@"antlerShaftWidth"] : nil;
            specimen.notEdible = ![item[@"notEdible"] isEqual:[NSNull null]] ? item[@"notEdible"] : nil;
            specimen.alone = ![item[@"alone"] isEqual:[NSNull null]] ? item[@"alone"] : nil;
            specimen.additionalInfo = ![item[@"additionalInfo"] isEqual:[NSNull null]] ? item[@"additionalInfo"] : nil;
            [specimens addObject:specimen];
        }
    }

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryEntry" inManagedObjectContext:context];
    DiaryEntry *diaryEntry;

    // Check if existing entry exists
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"DiaryEntry"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId = %d", [dict[@"id"] integerValue]];
    [fetch setPredicate:predicate];

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetch error:&error];

    if (results && results.count == 1) {
        // by default update the existing entry..
        diaryEntry = results[0];

        // but don't update if we have local modifications that can be sent to the backend
        if ([diaryEntry.rev integerValue] == [dict[@"rev"] integerValue] && ![diaryEntry.sent boolValue]) {
            // revisions are the same and thus the received diary entry probably contains the same data
            // as what we have locally in the database. In the backend logs, however, there are few entries
            // describing a situation where diary entry revisions are the same but the backend has newer
            // specimen data.
            // -> check if there's newer data in remote specimens. In that case we _need_ to update
            //    specimens as otherwise our local changes can never be sent to backend
            if (![diaryEntry shouldSpecimensBeUpdatedWithRemoteSpecimens:specimens]) {
                // specimens are same and thus we can consider this and remote diary entry as same.
                // Specifically this means that we can keep local changes and try send them later to the backend
                return diaryEntry;
            }
        }
    } else {
        diaryEntry = (DiaryEntry*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    }

    NSDate *date = [dateFormatter dateFromString:dict[@"pointOfTime"]];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    diaryEntry.amount = dict[@"amount"];
    diaryEntry.deerHuntingType = [RiistaUtils objectOrNilForKey:@"deerHuntingType" fromDictionary:dict];
    diaryEntry.deerHuntingTypeDescription = [RiistaUtils objectOrNilForKey:@"deerHuntingOtherTypeDescription" fromDictionary:dict];
    diaryEntry.diarydescription = ![dict[@"description"] isEqual:[NSNull null]] ? dict[@"description"] : @"";
    diaryEntry.gameSpeciesCode = dict[@"gameSpeciesCode"];
    diaryEntry.harvestReportRequired = dict[@"harvestReportRequired"];
    diaryEntry.harvestReportDone = dict[@"harvestReportDone"];
    diaryEntry.harvestReportState = ![dict[@"harvestReportState"] isEqual:[NSNull null]] ? dict[@"harvestReportState"] : nil;
    diaryEntry.stateAcceptedToHarvestPermit = ![dict[@"stateAcceptedToHarvestPermit"] isEqual:[NSNull null]] ? dict[@"stateAcceptedToHarvestPermit"] : nil;
    diaryEntry.canEdit = dict[@"canEdit"];
    diaryEntry.month = [NSNumber numberWithInteger:components.month];
    diaryEntry.pointOfTime = date;
    diaryEntry.remote = [NSNumber numberWithBool:YES];
    diaryEntry.remoteId = dict[@"id"];
    diaryEntry.rev = dict[@"rev"];
    diaryEntry.sent = [NSNumber numberWithBool:YES];
    diaryEntry.type = dict[@"type"];
    diaryEntry.year = [NSNumber numberWithInteger:components.year];
    diaryEntry.mobileClientRefId = ![dict[@"mobileClientRefId"] isEqual:[NSNull null]] ? dict[@"mobileClientRefId"] : nil;
    diaryEntry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationNone];
    diaryEntry.coordinates = coordinates;
    [diaryEntry setDiaryImages:[NSSet setWithArray:[diaryImages copy]]];
    [diaryEntry setSpecimens:[NSOrderedSet orderedSetWithArray:[specimens copy]]];
    diaryEntry.permitNumber = ![dict[@"permitNumber"] isEqual:[NSNull null]] ? dict[@"permitNumber"] : nil;
    diaryEntry.harvestSpecVersion = dict[@"harvestSpecVersion"];
    diaryEntry.huntingMethod = dict[@"huntingMethod"];
    diaryEntry.feedingPlace = dict[@"feedingPlace"];
    diaryEntry.taigaBeanGoose = dict[@"taigaBeanGoose"];

    return diaryEntry;
}

// returns nil if missing required data
- (NSDictionary*)dictFromDiaryEntry:(DiaryEntry*)diaryEntry isNew:(BOOL)isNew
{
    NSString *dateString = [dateFormatter stringFromDate:diaryEntry.pointOfTime];

    // Source added in 1.2.0, older data has value nil
    NSMutableDictionary *coordinates = [@{@"latitude":diaryEntry.coordinates.latitude,
                                          @"longitude":diaryEntry.coordinates.longitude,
                                          @"accuracy":diaryEntry.coordinates.accuracy,
                                          @"source":diaryEntry.coordinates.source != nil ? diaryEntry.coordinates.source : [NSNull null]
                                          } mutableCopy];
    NSMutableArray *specimens = [self generateSpecimenArray:diaryEntry.specimens];
    
    NSMutableDictionary *dict = [@{ @"description":diaryEntry.diarydescription,
                                    @"gameSpeciesCode":diaryEntry.gameSpeciesCode,
                                    @"pointOfTime":dateString,
                                    @"type":diaryEntry.type,
                                    @"amount":diaryEntry.amount,
                                    @"specimens":specimens,
                                    @"geoLocation":coordinates
                                    } mutableCopy];

    if (diaryEntry.harvestSpecVersion != nil) {
        dict[@"harvestSpecVersion"] = diaryEntry.harvestSpecVersion;
    } else {
        // missing harvestSpecVersion produces errors in the backend so don't even try sending
        // harvests with missing spec version.
        //
        // HarvestSpecVersion can be nil if user has locally stored harvests that have been made
        // with really old app version (probably around 1.3 or like). Those harvests were never
        // migrated to newer data model and thus they lack harvest spec version.
        return nil;
    }

    // Check for zero because in version <1.1 the value defaults to zeros
    if (isNew && diaryEntry.mobileClientRefId != nil && diaryEntry.mobileClientRefId != 0) {
        dict[@"mobileClientRefId"] = diaryEntry.mobileClientRefId;
    }
    else if (isNew) {
        // Version 1.0 did not generate client ref id.
        NSLog(@"Warning: No mobileClientRefId for new entry!");
    }
    else {
        dict[@"rev"] = diaryEntry.rev;
    }

    if (diaryEntry.deerHuntingType != nil && [diaryEntry.deerHuntingType length] > 0) {
        dict[@"deerHuntingType"] = diaryEntry.deerHuntingType;
    }
    if (diaryEntry.deerHuntingTypeDescription != nil && [diaryEntry.deerHuntingTypeDescription length] > 0) {
        dict[@"deerHuntingOtherTypeDescription"] = diaryEntry.deerHuntingTypeDescription;
    }

    if ([diaryEntry.permitNumber length] > 0) {
        dict[@"permitNumber"] = diaryEntry.permitNumber;
    }

    if (diaryEntry.huntingMethod != nil && [diaryEntry.huntingMethod length] > 0) {
        dict[@"huntingMethod"] = diaryEntry.huntingMethod;
    }
    if (diaryEntry.feedingPlace != nil) {
        dict[@"feedingPlace"] = diaryEntry.feedingPlace;
    }
    if (diaryEntry.taigaBeanGoose != nil) {
        dict[@"taigaBeanGoose"] = diaryEntry.taigaBeanGoose;
    }

    return [dict copy];
}

- (void)setSpecimensFromJson:(DiaryEntry*)diaryEntry specimenItems:(NSArray*)items
{
    NSMutableArray *specimens = [NSMutableArray new];
    NSEntityDescription *specimenEntity = [NSEntityDescription entityForName:@"Specimen" inManagedObjectContext:[diaryEntry managedObjectContext]];

    if (items && ![items isEqual:[NSNull null]]) {
        for (NSDictionary *item in items) {
            RiistaSpecimen *specimen = (RiistaSpecimen*)[[NSManagedObject alloc] initWithEntity:specimenEntity insertIntoManagedObjectContext:[diaryEntry managedObjectContext]];
            specimen.remoteId = item[@"id"];
            specimen.rev = item[@"rev"];
            specimen.age = ![item[@"age"] isEqual:[NSNull null]] ? item[@"age"] : nil;
            specimen.gender = ![item[@"gender"] isEqual:[NSNull null]] ? item[@"gender"] : nil;
            specimen.weight = ![item[@"weight"] isEqual:[NSNull null]] ? item[@"weight"] : nil;
            specimen.weightEstimated = ![item[@"weightEstimated"] isEqual:[NSNull null]] ? item[@"weightEstimated"] : nil;
            specimen.weightMeasured = ![item[@"weightMeasured"] isEqual:[NSNull null]] ? item[@"weightMeasured"] : nil;
            specimen.fitnessClass = ![item[@"fitnessClass"] isEqual:[NSNull null]] ? item[@"fitnessClass"] : nil;
            specimen.antlersType = ![item[@"antlersType"] isEqual:[NSNull null]] ? item[@"antlersType"] : nil;
            specimen.antlersWidth = ![item[@"antlersWidth"] isEqual:[NSNull null]] ? item[@"antlersWidth"] : nil;
            specimen.antlerPointsLeft = ![item[@"antlerPointsLeft"] isEqual:[NSNull null]] ? item[@"antlerPointsLeft"] : nil;
            specimen.antlerPointsRight = ![item[@"antlerPointsRight"] isEqual:[NSNull null]] ? item[@"antlerPointsRight"] : nil;
            specimen.antlersLost = ![item[@"antlersLost"] isEqual:[NSNull null]] ? item[@"antlersLost"] : nil;
            specimen.antlersGirth = ![item[@"antlersGirth"] isEqual:[NSNull null]] ? item[@"antlersGirth"] : nil;
            specimen.antlersLength = ![item[@"antlersLength"] isEqual:[NSNull null]] ? item[@"antlersLength"] : nil;
            specimen.antlersInnerWidth = ![item[@"antlersInnerWidth"] isEqual:[NSNull null]] ? item[@"antlersInnerWidth"] : nil;
            specimen.antlersShaftWidth = ![item[@"antlerShaftWidth"] isEqual:[NSNull null]] ? item[@"antlerShaftWidth"] : nil;
            specimen.notEdible = ![item[@"notEdible"] isEqual:[NSNull null]] ? item[@"notEdible"] : nil;
            specimen.alone = ![item[@"alone"] isEqual:[NSNull null]] ? item[@"alone"] : nil;
            specimen.additionalInfo = ![item[@"additionalInfo"] isEqual:[NSNull null]] ? item[@"additionalInfo"] : nil;

            [specimens addObject:specimen];
        }
    }

    NSOrderedSet *toBeRemoved = diaryEntry.specimens;
    for (RiistaSpecimen *toBeDeleteItem in toBeRemoved) {
        [diaryEntry.managedObjectContext deleteObject:toBeDeleteItem];
    }

    [diaryEntry removeSpecimens:diaryEntry.specimens];
    [diaryEntry addSpecimens:[NSOrderedSet orderedSetWithArray:[specimens copy]]];
}

- (NSMutableArray*)generateSpecimenArray:(NSOrderedSet*)specimens
{
    NSMutableArray *result = [NSMutableArray new];
    for (RiistaSpecimen *specimen in specimens) {
        if (specimen != nil) {
            NSMutableDictionary *item =[@{@"age":specimen.age != nil ? specimen.age : [NSNull null],
                                          @"gender":specimen.gender != nil ? specimen.gender : [NSNull null],
                                          @"weight":specimen.weight != nil ? specimen.weight : [NSNull null],
                                          @"weightEstimated":specimen.weightEstimated != nil ? specimen.weightEstimated : [NSNull null],
                                          @"weightMeasured":specimen.weightMeasured != nil ? specimen.weightMeasured : [NSNull null],
                                          @"fitnessClass":specimen.fitnessClass != nil ? specimen.fitnessClass : [NSNull null],
                                          @"antlersLost":specimen.antlersLost != nil ? specimen.antlersLost : [NSNull null],
                                          @"antlersType":specimen.antlersType != nil ? specimen.antlersType : [NSNull null],
                                          @"antlersWidth":specimen.antlersWidth != nil ? specimen.antlersWidth : [NSNull null],
                                          @"antlerPointsLeft":specimen.antlerPointsLeft != nil ? specimen.antlerPointsLeft : [NSNull null],
                                          @"antlerPointsRight":specimen.antlerPointsRight != nil ? specimen.antlerPointsRight : [NSNull null],
                                          @"antlersGirth":specimen.antlersGirth != nil ? specimen.antlersGirth : [NSNull null],
                                          @"antlersLength":specimen.antlersLength != nil ? specimen.antlersLength : [NSNull null],
                                          @"antlersInnerWidth":specimen.antlersInnerWidth != nil ? specimen.antlersInnerWidth : [NSNull null],
                                          // note different field name in json / DTO
                                          @"antlerShaftWidth":specimen.antlersShaftWidth != nil ? specimen.antlersShaftWidth : [NSNull null],
                                          @"notEdible":specimen.notEdible != nil ? specimen.notEdible : [NSNull null],
                                          @"alone":specimen.alone != nil ? specimen.alone : [NSNull null],
                                          @"additionalInfo":specimen.additionalInfo != nil ? specimen.additionalInfo : [NSNull null],
                                          } mutableCopy];

            if ([specimen.remoteId intValue] > 0) {
                [item setObject:specimen.remoteId forKey:@"id"];
                [item setObject:specimen.rev forKey:@"rev"];
            }

            [result addObject:item];
        }
    }

    return result;
}

- (void)initSync
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        self.autosync = YES;
    }
}

- (void)updateFetchDateForYear:(NSInteger)year date:(NSDate*)date
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (userDefaults) {
        NSMutableDictionary *fetchTimes = [NSMutableDictionary new];
        if ([userDefaults objectForKey:RIISTA_FETCH_TIMES]) {
            fetchTimes = [[userDefaults objectForKey:RIISTA_FETCH_TIMES] mutableCopy];
        }
        NSString *yearString = [NSString stringWithFormat:@"%ld", (long)year];
        fetchTimes[yearString] = date;
        [userDefaults setObject:[fetchTimes copy] forKey:RIISTA_FETCH_TIMES];
        [userDefaults synchronize];
    }
}

- (NSDate*)fetchDateForYear:(NSInteger)year
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (userDefaults) {
        NSDictionary *fetchTimes = [userDefaults objectForKey:RIISTA_FETCH_TIMES];
        NSString *yearString = [NSString stringWithFormat:@"%ld", (long)year];
        if (fetchTimes && [fetchTimes objectForKey:yearString]) {
            return fetchTimes[yearString];
        }
    }
    return nil;
}

- (void)handleNetworkChange:(NSNotification*)notice
{
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    if (self.autosync && remoteHostStatus != NotReachable) {
        [self doAutoSync];
    }
}

- (BOOL)sameImagesInEntry:(DiaryEntry*)existingEntry andNewEntry:(DiaryEntry*)newEntry
{
    NSMutableArray *existingUUIDs = [NSMutableArray new];
    NSMutableArray *newUUIDs = [NSMutableArray new];
    for (DiaryImage* image in existingEntry.diaryImages) {
        if ([image.status integerValue] == DiaryImageStatusInsertion || [image.status integerValue] == DiaryImageStatusDeletion) {
            return NO;
        }
        [existingUUIDs addObject:image.imageid];
    }
    for (DiaryImage* image in newEntry.diaryImages) {
        [newUUIDs addObject:image.imageid];
    }
    if ([[NSSet setWithArray:[existingUUIDs copy]] isEqualToSet:[NSSet setWithArray:[newUUIDs copy]]]) {
        return YES;
    }
    return NO;
}

- (BOOL)sameReportInfoInEntry:(DiaryEntry*)existingEntry andNewEntry:(DiaryEntry*)newEntry
{
    BOOL isPermitStateSame = (existingEntry.stateAcceptedToHarvestPermit == nil && newEntry.stateAcceptedToHarvestPermit == nil) || [existingEntry.stateAcceptedToHarvestPermit isEqual:newEntry.stateAcceptedToHarvestPermit];
    BOOL isCanEditSame = (existingEntry.canEdit == nil && newEntry.canEdit == nil) || [existingEntry.canEdit isEqual:newEntry.canEdit];

    return [existingEntry.harvestReportRequired isEqual:newEntry.harvestReportRequired] &&
           [existingEntry.harvestReportDone isEqual:newEntry.harvestReportDone] &&
           ((existingEntry.harvestReportState == nil && newEntry.harvestReportState == nil) ||
           [existingEntry.harvestReportState isEqual:newEntry.harvestReportState]) &&
           isPermitStateSame && isCanEditSame;
}

- (BOOL)sameSpecimenInfoInEntry:(DiaryEntry*)existingEntry andNewEntry:(DiaryEntry*)newEntry
{
    if (existingEntry == nil && newEntry == nil) {
        return YES;
    }
    else if (existingEntry == nil || newEntry == nil) {
        return NO;
    }
    else if ([existingEntry.specimens count] == [newEntry.specimens count]) {

        // Comparing items has to be done manually since isEqual may not be overridden for NSManagedObjects
        for (int i = 0; i < [existingEntry.specimens count]; i++) {
            if (![existingEntry.specimens[i] isEqualToRiistaSpecimen:newEntry.specimens[i]]) {
                return NO;
            }
        }

        return YES;
    }

    return NO;
}

- (void)appWillEnterForeground
{
    if (self.autosync) {
        [self doAutoSync];
    }
}

#pragma mark - Observations

- (NSArray*)allObservations
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        return results;
    }
    return [NSArray new];
}

- (ObservationEntry*)observationEntryWithId:(NSInteger)remoteId context:(NSManagedObjectContext*)context excludeObject:(NSManagedObjectID*)objectId {

    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];

    NSPredicate *predicate = nil;
    if (objectId) {
        predicate = [NSPredicate predicateWithFormat:@"remoteId = %d AND self != %@", remoteId, objectId];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"remoteId = %d", remoteId];
    }
    [fetch setPredicate:predicate];

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetch error:&error];
    if(results && results.count > 0) {
        return results[0];
    }
    return nil;
}

- (ObservationEntry*)observationEntryWithId:(NSInteger)remoteId
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [self observationEntryWithId:remoteId context:delegate.managedObjectContext excludeObject:nil];
}

- (ObservationEntry*)observationEntryWithObjectId:(NSManagedObjectID*)objectId context:(NSManagedObjectContext*)context
{
    NSError *error = nil;
    ObservationEntry *result = (ObservationEntry*)[context existingObjectWithID:objectId error:&error];
    return result;
}

- (void)addLocalObservation:(ObservationEntry*)observationEntry
{
    NSManagedObjectContext *context = [observationEntry managedObjectContext];
    if ([self saveContexts:context]) {
        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.observation = observationEntry;
        update.type = UpdateTypeInsert;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)editLocalObservation:(ObservationEntry*)observationEntry newImages:(NSArray*)images
{
    [self editImagesForObservationEntry:observationEntry newImages:images];
    [self editLocalObservation:observationEntry];
}

- (void)editLocalObservation:(ObservationEntry*)observationEntry
{
    NSError *error = nil;
    if ([[observationEntry managedObjectContext] save:&error]) {
        // Modifying child context. Save parent to persistent store
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            [delegate.managedObjectContext save:&mErr];
        }];

        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.observation = observationEntry;
        update.type = UpdateTypeUpdate;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)deleteLocalObservation:(ObservationEntry*)observationEntry
{
    observationEntry.sent = @(NO);
    observationEntry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationDelete];

    NSError *error = nil;
    if ([[observationEntry managedObjectContext] save:&error]) {

        // Modifying child context. Save parent to persistent store
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            [delegate.managedObjectContext save:&mErr];
        }];

        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.observation = observationEntry;
        update.type = UpdateTypeDelete;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)clearObservations
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        NSError *error;
        for (int i=0; i<results.count; i++) {
            [delegate.managedObjectContext deleteObject:results[i]];
        }
        [delegate.managedObjectContext save:&error];
    }
}

- (NSArray*)clearSentObservationsFromYear:(NSInteger)year
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((year = %d AND month >= %d) OR (year = %d AND month < %d)) AND remote = %@", year, RiistaCalendarStartMonth, year+1, RiistaCalendarStartMonth, @(YES)];
    [fetch setPredicate:predicate];
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if(results) {
        NSMutableArray *updates = [NSMutableArray new];
        NSError *error;
        for (int i=0; i<results.count; i++) {
            RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
            update.observation = results[i];
            update.type = UpdateTypeDelete;
            [updates addObject:update];
            [delegate.managedObjectContext deleteObject:results[i]];
        }
        if ([delegate.managedObjectContext save:&error])
            return updates;
    }
    return nil;
}

- (NSArray*)observationYears
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *ctx = delegate.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ObservationEntry" inManagedObjectContext:ctx];
    NSDictionary *entityProperties = [entity propertiesByName];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];
    [fetch setReturnsDistinctResults:YES];
    [fetch setPropertiesToFetch:@[[entityProperties objectForKey:@"month"], [entityProperties objectForKey:@"year"]]];

    NSSortDescriptor *yearDescriptor = [[NSSortDescriptor alloc] initWithKey:@"year" ascending:YES];
    NSSortDescriptor *monthDescriptor = [[NSSortDescriptor alloc] initWithKey:@"month" ascending:YES];

    [fetch setSortDescriptors:@[yearDescriptor, monthDescriptor]];
    NSArray *result = [ctx executeFetchRequest:fetch error:nil];
    if (result) {
        NSMutableArray *startYears = [NSMutableArray new];
        for (int i=0; i<result.count; i++) {
            NSNumber *year = 0;
            if ([((ObservationEntry*)result[i]).month integerValue] >= RiistaCalendarStartMonth) {
                year = ((ObservationEntry*)result[i]).year;
            } else {
                year = @([((ObservationEntry*)result[i]).year integerValue]-1);
            }
            if (![startYears containsObject:year]) {
                [startYears addObject:year];
            }
        }
        return startYears;
    }
    return [NSArray new];
}

- (SeasonStats *)statsForObservationSeason:(NSInteger)startYear
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];
    // Ignore deleted observations
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((year = %d AND month >= %d) OR (year = %d AND month < %d)) AND (pendingOperation != %d)",
                              startYear,
                              RiistaCalendarStartMonth,
                              startYear + 1,
                              RiistaCalendarStartMonth,
                              DiaryEntryOperationDelete];
    [fetch setPredicate:predicate];

    SeasonStats *season = [SeasonStats empty];
    season.startYear = startYear;

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];

    if(results) {
        NSMutableArray *monthAmounts = [season mutableMonthArray];

        for (int i = 0; i<results.count; i++) {
            ObservationEntry *observation = results[i];

            NSInteger amount = [observation.totalSpecimenAmount integerValue];
            if ([observation getMooselikeSpecimenCount] > 0) {
                amount = [observation getMooselikeSpecimenCount];
            }
            amount = MAX(amount, 1);

            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:observation.pointOfTime];
            // Month range is 1-12
            NSInteger monthIndex = components.month - 1;

            monthAmounts[monthIndex] = [NSNumber numberWithInteger:[monthAmounts[monthIndex] intValue] + amount];

            RiistaSpecies *species = [self speciesById:[observation.gameSpeciesCode integerValue]];

            if ([observation.type isEqual:DiaryEntryTypeObservation] && species) {
                NSNumber *prevValue = season.catValues[species.categoryId - 1];
                season.catValues[species.categoryId - 1] = [NSNumber numberWithLong: prevValue.intValue + amount];
            }

            season.totalAmount += amount;
        }

        season.monthAmounts = monthAmounts;
    }

    return season;
}

- (NSArray*)latestObservationSpecies:(NSInteger)amount
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"pointOfTime" ascending:NO];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ObservationEntry" inManagedObjectContext:delegate.managedObjectContext];
    fetch.entity = entity;
    [fetch setSortDescriptors:@[dateSort]];
    fetch.resultType = NSManagedObjectResultType;
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if (results && results.count > 0) {
        NSMutableArray *species = [NSMutableArray new];
        for (ObservationEntry *observationEntry in results) {
            if (![species containsObject:observationEntry.gameSpeciesCode] && [observationEntry.pendingOperation integerValue] != DiaryEntryOperationDelete) {
                [species addObject:observationEntry.gameSpeciesCode];
                if (species.count == amount)
                    break;
            }
        }
        return [species copy];
    }
    return nil;
}

- (void)synchronizeObservationEntry:(ObservationEntry *)observationEntry completion:(RiistaOperationCompletion)completion
{
    [self editObservationEntry:observationEntry completion:^(NSDictionary *response, NSError *error) {
        completion(error == nil);
    }];
}

- (void)editObservationEntry:(ObservationEntry*)observationEntry completion:(RiistaObservationEntryEditCompletion)completion
{
    NSManagedObjectContext* context = observationEntry.managedObjectContext; //Keep a strong reference during the operations

    [[RiistaNetworkManager sharedInstance] sendDiaryObservation:observationEntry completion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            if (response) {
                ObservationEntry *newEntry = [[ObservationSync new] observationEntryFromDict:response objectContext:context];

                [newEntry removeDiaryImages:newEntry.diaryImages];
                [newEntry addDiaryImages:observationEntry.diaryImages];

                [context deleteObject:observationEntry];
                [context insertObject:newEntry];

                [RiistaModelUtils saveContexts:context];

                [self submitObservationImagesFromEntry:newEntry context:context completion:^(BOOL errors) {
                    RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                    update.observation = newEntry;
                    update.type = UpdateTypeUpdate;
                    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];

                    if (completion) {
                        completion(nil, nil);
                    }
                }];
                return;
            }
        }
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)deleteObservationEntryCompat:(ObservationEntry *)observationEntry completion:(RiistaOperationCompletion)completion
{
    [self deleteObservationEntry:observationEntry completion:^(NSError *error) {
        completion(error == nil);
    }];
}

- (void)deleteObservationEntry:(ObservationEntry*)observationEntry completion:(RiistaObservationEntryDeleteCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] sendDiaryObservation:observationEntry completion:^(NSDictionary *response, NSError *error) {
        if (completion) {
            if (!error) {
                // Mark successfully edited event as sent
                NSError *err = nil;
                observationEntry.sent = [NSNumber numberWithBool:YES];
                if ([[observationEntry managedObjectContext] save:&err]) {
                    RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                    update.observation = observationEntry;
                    update.type = UpdateTypeDelete;
                    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
                }
                completion(nil);
            } else {
                completion(error);
            }
        }
    }];
}

- (void)submitObservationImagesFromEntry:(ObservationEntry*)observationEntry context:(NSManagedObjectContext*)context completion:(DiaryImageSubmitCompletion)completion
{
    if (observationEntry.diaryImages.count == 0) {
        completion(NO);
        return;
    }

    __block BOOL errors = NO;
    __block NSInteger sentImages = 0;
    NSMutableArray *images = [[observationEntry.diaryImages array] mutableCopy];
    int originalCount = (int)images.count;

    for (int i=(int)images.count-1; i>=0; i--) {

        DiaryImage *image = images[i];

        [[RiistaNetworkManager sharedInstance] diaryObservationImageOperationForImage:image observationEntry:observationEntry completion:^(NSError* error) {
            if (!error) {
                if ([image.status integerValue] == DiaryImageStatusInsertion) {
                    image.type = [NSNumber numberWithInteger:DiaryImageTypeRemote];
                    image.status = 0;
                    [RiistaModelUtils saveContexts:context];
                } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
                    [images removeObject:image];
                }
            } else if ([image.status integerValue] == DiaryImageStatusDeletion && error.code == 404) {
                // Unsuccessful deletion of already deleted image can be ignored
                [images removeObject:image];
            } else {
                errors = YES;
            }
            sentImages++;
            if (sentImages == originalCount) {
                observationEntry.diaryImages = [NSOrderedSet orderedSetWithArray:[images copy]];

                [RiistaModelUtils saveContexts:context];

                if (completion)
                    completion(errors);
            }
        }];
    }
}

- (void)editImagesForObservationEntry:(ObservationEntry*)observationEntry newImages:(NSArray*)images
{
    NSMutableArray *currentImages = [[observationEntry.diaryImages array] mutableCopy];
    NSMutableArray *addedImages = [images mutableCopy];

    NSInteger originalCount = currentImages.count;
    for (int i=(int)originalCount-1; i>=0; i--) {
        BOOL found = NO;
        NSUInteger foundImageIndex = 0;
        for (int i2=0; i2<addedImages.count; i2++) {
            if ([((DiaryImage*)currentImages[i]).imageid isEqual:((DiaryImage*)addedImages[i2]).imageid]) {
                foundImageIndex = i2;
                found = YES;
            }
        }
        if (found) {
            ((DiaryImage*)addedImages[foundImageIndex]).status = 0;
            [addedImages removeObjectAtIndex:foundImageIndex];
        } else {
            if ([((DiaryImage*)currentImages[i]).status integerValue] == DiaryImageStatusInsertion) {
                // Image hasn't been sent yet so it can be deleted
                [observationEntry removeDiaryImagesObject:currentImages[i]];
            } else {
                // If a image isn't in the list of new images, it is marked as pending deletion
                // User doesn't supply images that are already pending deletion. Those images are marked as pending deletion again
                ((DiaryImage*)currentImages[i]).status = [NSNumber numberWithInteger:DiaryImageStatusDeletion];
            }
        }
    }
    // Insert images that did not already exist
    for (int i=0; i<addedImages.count; i++) {
        ((DiaryImage*)addedImages[i]).status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
        [observationEntry addDiaryImagesObject:addedImages[i]];
    }
}

- (NSArray*)observationEntriesFromDictValues:(NSArray*)dictValues context:(NSManagedObjectContext*)context
{
    NSMutableArray *entries = [NSMutableArray new];
    for (int i=0; i<dictValues.count; i++) {
        [entries addObject:[[ObservationSync new] observationEntryFromDict:dictValues[i] objectContext:context]];
    }
    return [entries copy];
}

- (NSDictionary*)dictFromObservationEntry:(ObservationEntry*)observationEntry isNew:(BOOL)isNew
{
    return [[ObservationSync new] dictFromObservationEntry:observationEntry isNew:isNew];
}

- (SeasonStats *)statsForSrvaYear:(NSInteger)startYear
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"SrvaEntry"];
    // Ignore deleted srvas
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(year = %d) AND (pendingOperation != %d)",
                              (startYear + 1),
                              DiaryEntryOperationDelete];
    [fetch setPredicate:predicate];

    SeasonStats *season = [SeasonStats empty];
    season.startYear = startYear;

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];

    if (results) {
        NSMutableArray *monthData = [season mutableMonthArray];

        for (int i = 0; i < results.count; i++) {
            SrvaEntry *srva = results[i];

            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:srva.pointOfTime];
            // Month range is 1-12
            NSInteger monthIndex = components.month - 1;

            monthData[monthIndex] = [NSNumber numberWithInteger:[monthData[monthIndex] integerValue] + 1];
        }

        season.monthAmounts = [monthData copy];
        season.totalAmount = results.count;
    }

    return season;
}

- (NSArray*)latestSrvaSpecies:(NSInteger)amount
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"SrvaEntry"];
    fetch.resultType = NSManagedObjectResultType;

    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"pointOfTime" ascending:NO];
    [fetch setSortDescriptors:@[dateSort]];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SrvaEntry" inManagedObjectContext:delegate.managedObjectContext];
    fetch.entity = entity;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventType != 'OTHER' AND gameSpeciesCode != NULL AND pendingOperation != %d",  DiaryEntryOperationDelete];
    [fetch setPredicate:predicate];

    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetch error:&error];
    if (results && results.count > 0) {
        NSMutableArray *events = [NSMutableArray new];

        NSInteger lastGameSpeciesCode = [((SrvaEntry*)results[0]).gameSpeciesCode integerValue];
        [events addObject:results[0]];

        for (NSInteger i = 1; i < results.count; ++i) {
            SrvaEntry *srva = results[i];
            if ([srva.gameSpeciesCode integerValue] != lastGameSpeciesCode) {
                lastGameSpeciesCode = [srva.gameSpeciesCode integerValue];

                [events addObject:srva];
                if (events.count == amount) {
                    break;
                }
            }
        }
        return events;
    }
    return nil;
}

- (SrvaEntry*)srvaEntryWithObjectId:(NSManagedObjectID*)objectId context:(NSManagedObjectContext*)context
{
    NSError *error = nil;
    SrvaEntry *result = (SrvaEntry*)[context existingObjectWithID:objectId error:&error];
    return result;
}

- (void)addLocalSrva:(SrvaEntry*)srvaEntry
{
    NSManagedObjectContext *context = [srvaEntry managedObjectContext];
    if ([self saveContexts:context]) {
        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.srva = srvaEntry;
        update.type = UpdateTypeInsert;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)editLocalSrva:(SrvaEntry*)srvaEntry newImages:(NSArray*)images
{
    [self editImagesForSrvaEntry:srvaEntry newImages:images];

    NSError *error = nil;
    if ([[srvaEntry managedObjectContext] save:&error]) {

        // Modifying child context. Save parent to persistent store
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            [delegate.managedObjectContext save:&mErr];
        }];

        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.srva = srvaEntry;
        update.type = UpdateTypeUpdate;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)editSrvaEntry:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryEditCompletion)completion
{
    NSManagedObjectContext* context = srvaEntry.managedObjectContext; //Keep a strong reference during the operations

    [[RiistaNetworkManager sharedInstance] sendDiarySrva:srvaEntry completion:^(NSDictionary *response, NSError *error) {
        if (!error) {
            if (response) {
                SrvaEntry *newEntry = [[SrvaSync new] srvaEntryFromDict:response objectContext:context];

                [newEntry removeDiaryImages:newEntry.diaryImages];
                [newEntry addDiaryImages:srvaEntry.diaryImages];

                [context deleteObject:srvaEntry];
                [context insertObject:newEntry];

                [RiistaModelUtils saveContexts:newEntry.managedObjectContext];

                [self submitSrvaImagesFromEntry:newEntry context:context completion:^(BOOL errors) {
                    RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                    update.srva = newEntry;
                    update.type = UpdateTypeUpdate;
                    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];

                    if (completion) {
                        completion(nil, nil);
                    }
                }];
                return;
            }
        }

        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)editImagesForSrvaEntry:(SrvaEntry*)srvaEntry newImages:(NSArray*)images
{
    NSMutableArray *currentImages = [[srvaEntry.diaryImages array] mutableCopy];
    NSMutableArray *addedImages = [images mutableCopy];

    NSInteger originalCount = currentImages.count;
    for (int i=(int)originalCount-1; i>=0; i--) {
        BOOL found = NO;
        NSUInteger foundImageIndex = 0;
        for (int i2=0; i2<addedImages.count; i2++) {
            if ([((DiaryImage*)currentImages[i]).imageid isEqual:((DiaryImage*)addedImages[i2]).imageid]) {
                foundImageIndex = i2;
                found = YES;
            }
        }
        if (found) {
            ((DiaryImage*)addedImages[foundImageIndex]).status = 0;
            [addedImages removeObjectAtIndex:foundImageIndex];
        } else {
            if ([((DiaryImage*)currentImages[i]).status integerValue] == DiaryImageStatusInsertion) {
                // Image hasn't been sent yet so it can be deleted
                [srvaEntry removeDiaryImagesObject:currentImages[i]];
            } else {
                // If a image isn't in the list of new images, it is marked as pending deletion
                // User doesn't supply images that are already pending deletion. Those images are marked as pending deletion again
                ((DiaryImage*)currentImages[i]).status = [NSNumber numberWithInteger:DiaryImageStatusDeletion];
            }
        }
    }
    // Insert images that did not already exist
    for (int i=0; i<addedImages.count; i++) {
        ((DiaryImage*)addedImages[i]).status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
        [srvaEntry addDiaryImagesObject:addedImages[i]];
    }
}

- (void)submitSrvaImagesFromEntry:(SrvaEntry*)srvaEntry context:(NSManagedObjectContext*)context completion:(DiaryImageSubmitCompletion)completion
{
    if (srvaEntry.diaryImages.count == 0) {
        completion(NO);
        return;
    }

    __block BOOL errors = NO;
    __block NSInteger sentImages = 0;
    NSMutableArray *images = [[srvaEntry.diaryImages array] mutableCopy];
    int originalCount = (int)images.count;

    for (int i=(int)images.count-1; i>=0; i--) {

        DiaryImage *image = images[i];

        [[RiistaNetworkManager sharedInstance] diarySrvaImageOperationForImage:image srvaEntry:srvaEntry completion:^(NSError* error) {
            if (!error) {
                if ([image.status integerValue] == DiaryImageStatusInsertion) {
                    image.type = [NSNumber numberWithInteger:DiaryImageTypeRemote];
                    image.status = 0;
                    [RiistaModelUtils saveContexts:context];
                } else if ([image.status integerValue] == DiaryImageStatusDeletion) {
                    [images removeObject:image];
                }
            } else if ([image.status integerValue] == DiaryImageStatusDeletion && error.code == 404) {
                // Unsuccessful deletion of already deleted image can be ignored
                [images removeObject:image];
            } else {
                errors = YES;
            }
            sentImages++;
            if (sentImages == originalCount) {
                srvaEntry.diaryImages = [NSOrderedSet orderedSetWithArray:[images copy]];

                [RiistaModelUtils saveContexts:context];

                if (completion)
                    completion(errors);
            }
        }];
    }
}

- (void)deleteLocalSrva:(SrvaEntry*)srvaEntry
{
    srvaEntry.sent = @(NO);
    srvaEntry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationDelete];

    NSError *error = nil;
    if ([[srvaEntry managedObjectContext] save:&error]) {

        // Modifying child context. Save parent to persistent store
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            [delegate.managedObjectContext save:&mErr];
        }];

        RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
        update.srva = srvaEntry;
        update.type = UpdateTypeDelete;
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
    }
}

- (void)deleteSrvaEntry:(SrvaEntry*)srvaEntry completion:(RiistaDiaryEntryDeleteCompletion)completion
{
    srvaEntry.sent = @(NO);
    srvaEntry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationDelete];

    [[RiistaNetworkManager sharedInstance] sendDiarySrva:srvaEntry completion:^(NSDictionary *response, NSError *error) {
        if (completion) {
            if (!error) {
                [srvaEntry.managedObjectContext deleteObject:srvaEntry];
                if ([self saveContexts:srvaEntry.managedObjectContext]) {
                    RiistaDiaryEntryUpdate *update = [RiistaDiaryEntryUpdate new];
                    update.srva = srvaEntry;
                    update.type = UpdateTypeDelete;
                    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:@{@"entries":@[update]}];
                }
                completion(nil);
            } else {
                completion(error);
            }
        }
    }];
}

- (NSDictionary*)dictFromSrvaEntry:(SrvaEntry*)srvaEntry isNew:(BOOL)isNew
{
    return [[SrvaSync new] dictFromSrvaEntry:srvaEntry isNew:isNew];
}

- (BOOL)saveContexts:(NSManagedObjectContext*)context
{
    //Save the context and all it's parent context in order.
    while (context != nil) {
        NSError *error;
        if (![context save:&error]) {
            DDLog(@"Context save failed: %@", [error localizedDescription]);
            return NO;
        }
        context = context.parentContext;
    }
    return YES;
}

@end
