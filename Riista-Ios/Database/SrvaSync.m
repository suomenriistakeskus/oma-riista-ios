#import "SrvaSync.h"
#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaAppDelegate.h"
#import "SrvaEntry.h"
#import "SrvaSpecimen.h"
#import "SrvaMethod.h"
#import "DiaryImage.h"
#import "GeoCoordinate.h"
#import "RiistaModelUtils.h"
#import "NSDateFormatter+Locale.h"

@implementation SrvaSync
{
    NSDateFormatter *dateFormatter;
    NSManagedObjectContext* context;
}

- (id)init
{
    self = [super init];
    if (self) {
        dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
        [dateFormatter setDateFormat:ISO_8601];
    }
    return self;
}

- (void)sync:(SrvaSynchronizationCompletion)completion;
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = delegate.managedObjectContext;

    NSMutableArray<SrvaEntry*> *deleted = [self fetchDeletedRemoteEvents];
    DDLog(@"Deleting: %lu", (unsigned long)deleted.count);
    [self deleteRemoteSrvaEvents:deleted completion:completion];
}

- (void)deleteRemoteSrvaEvents:(NSMutableArray<SrvaEntry*>*)events completion:(SrvaSynchronizationCompletion)completion
{
    if (events.count == 0) {
        [self sendUnsentEvents:completion];
        return;
    }
    SrvaEntry *entry = events[events.count - 1];
    [events removeObjectAtIndex:events.count - 1];

    [[RiistaGameDatabase sharedInstance] deleteSrvaEntry:entry completion:^(NSError *error) {
        if (error) {
            DLog(@"SRVA Delete Error: %@", [error localizedDescription]);
        }
        [self deleteRemoteSrvaEvents:events completion:completion];
    }];
}

- (void)sendUnsentEvents:(SrvaSynchronizationCompletion)completion
{
    NSMutableArray<SrvaEntry*> *unsent = [self fetchUnsentEvents];
    DLog(@"Sending: %lu", (unsigned long)unsent.count);
    [self sendSrvaEvents:unsent completion:completion];
}

- (void)sendSrvaEvents:(NSMutableArray<SrvaEntry*>*)events completion:(SrvaSynchronizationCompletion)completion
{
    if (events.count == 0) {
        [self downloadServerEvents:completion];
        return;
    }
    SrvaEntry *entry = events[events.count - 1];
    [events removeObjectAtIndex:events.count - 1];

    [[RiistaGameDatabase sharedInstance] editSrvaEntry:entry completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            DLog(@"SRVA send error: %@", [error localizedDescription]);
        }
        [self sendSrvaEvents:events completion:completion];
    }];
}

- (void)downloadServerEvents:(SrvaSynchronizationCompletion)completion
{
    [[RiistaNetworkManager sharedInstance] srvaEntries:^(NSArray *entries, NSError *error) {
        if (!error) {
            NSMutableArray<SrvaEntry*> *localEvents = [self fetchAllLocalRemoteEvents];
            NSDictionary* localsMap = [self createRemoteIdMap:localEvents];
            NSMutableDictionary* remotesMap = [NSMutableDictionary new];

            for (NSDictionary* dict in entries) {
                SrvaEntry* entry = [self srvaEntryFromDict:dict objectContext:self->context];
                SrvaEntry* old = [localsMap objectForKey:entry.remoteId];

                if ([self insertReceivedEvent:entry oldEntry:old]) {
                    if (old) {
                        [self->context deleteObject:old];
                    }
                    [self->context insertObject:entry];
                }
                else {
                    [self->context deleteObject:entry];
                }

                [remotesMap setObject:entry forKey:entry.remoteId];
            }

            for (NSNumber *remoteId in localsMap) {
                //If our local entry remoteId is missing from server entries, it was deleted
                SrvaEntry *remote = [remotesMap objectForKey:remoteId];
                if (remote == nil) {
                    SrvaEntry* local = [localsMap objectForKey:remoteId];
                    [self->context deleteObject:local];
                }
            }
        }
        [self syncFinished:completion];
    }];
}

- (BOOL)insertReceivedEvent:(SrvaEntry*)newEntry oldEntry:(SrvaEntry*)oldEntry
{
    if (!oldEntry
        || [newEntry.rev integerValue] > [oldEntry.rev integerValue]
        || [newEntry.srvaEventSpecVersion integerValue] > [oldEntry.srvaEventSpecVersion integerValue]
        || [newEntry.canEdit boolValue] != [oldEntry.canEdit boolValue]) {
        return YES;
    }
    return NO;
}

- (NSDictionary*)createRemoteIdMap:(NSArray<SrvaEntry*>*)entries
{
    NSMutableDictionary* result = [NSMutableDictionary new];
    for (SrvaEntry* entry in entries) {
        if (entry.remoteId != nil) {
            [result setObject:entry forKey:entry.remoteId];
        }
    }
    return result;
}

- (void)syncFinished:(SrvaSynchronizationCompletion)completion
{
    [RiistaModelUtils saveContexts:context];

    completion();
}

- (SrvaEntry*)srvaEntryFromDict:(NSDictionary*)dict objectContext:(NSManagedObjectContext*)objectContext
{
    GeoCoordinate *coordinates = [RiistaModelUtils coordinatesFromDict:dict context:objectContext];

    NSDate *date = [dateFormatter dateFromString:dict[@"pointOfTime"]];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SrvaEntry" inManagedObjectContext:objectContext];
    SrvaEntry* entry = [[SrvaEntry alloc] initWithEntity:entity insertIntoManagedObjectContext:objectContext];
    entry.remoteId = dict[@"id"];
    entry.rev = dict[@"rev"];
    entry.type = dict[@"type"];
    entry.pointOfTime = date;
    entry.gameSpeciesCode = [RiistaModelUtils checkNull:dict key:@"gameSpeciesCode"];
    entry.descriptionText = [RiistaModelUtils checkNull:dict key:@"description"];
    entry.canEdit = dict[@"canEdit"];
    entry.eventName = [RiistaModelUtils checkNull:dict key:@"eventName"];
    entry.eventType = [RiistaModelUtils checkNull:dict key:@"eventType"];
    entry.totalSpecimenAmount = [RiistaModelUtils checkNull:dict key:@"totalSpecimenAmount"];
    entry.otherMethodDescription = [RiistaModelUtils checkNull:dict key:@"otherMethodDescription"];
    entry.otherTypeDescription = [RiistaModelUtils checkNull:dict key:@"otherTypeDescription"];
    entry.methods = [RiistaModelUtils jsonFromObject:dict[@"methods"]];
    entry.personCount = [RiistaModelUtils checkNull:dict key:@"personCount"];
    entry.timeSpent = [RiistaModelUtils checkNull:dict key:@"timeSpent"];
    entry.eventResult = [RiistaModelUtils checkNull:dict key:@"eventResult"];
    entry.rhyId = dict[@"rhyId"];
    entry.state = dict[@"state"];
    entry.state = dict[@"state"];
    entry.otherSpeciesDescription = [RiistaModelUtils checkNull:dict key:@"otherSpeciesDescription"];
    entry.approverFirstName = [RiistaModelUtils checkNull:dict[@"approverInfo"] key:@"firstName"];
    entry.approverLastName = [RiistaModelUtils checkNull:dict[@"approverInfo"] key:@"lastName"];
    entry.mobileClientRefId = [RiistaModelUtils checkNull:dict key:@"mobileClientRefId"];
    entry.srvaEventSpecVersion = dict[@"srvaEventSpecVersion"];
    entry.sent = @(YES);
    entry.year = [NSNumber numberWithInteger:components.year];
    entry.authorId =  [RiistaModelUtils checkNull:dict[@"authorInfo"] key:@"id"];
    entry.authorRev =  [RiistaModelUtils checkNull:dict[@"authorInfo"] key:@"rev"];
    entry.authorByName =  [RiistaModelUtils checkNull:dict[@"authorInfo"] key:@"byName"];
    entry.authorLastName =  [RiistaModelUtils checkNull:dict[@"authorInfo"] key:@"lastName"];
    entry.month = [NSNumber numberWithInteger:components.month];
    entry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationNone];
    entry.coordinates = coordinates;

    //Images
    NSMutableArray *diaryImages = [NSMutableArray new];
    NSArray *serverImages = dict[@"imageIds"];
    NSEntityDescription *imageEntity = [NSEntityDescription entityForName:@"DiaryImage" inManagedObjectContext:objectContext];
    for (int i=0; i < serverImages.count; i++) {
        DiaryImage *image = (DiaryImage*)[[NSManagedObject alloc] initWithEntity:imageEntity insertIntoManagedObjectContext:objectContext];
        image.type = [NSNumber numberWithInteger:DiaryImageTypeRemote];
        image.imageid = serverImages[i];
        [diaryImages addObject:image];
    }
    [entry setDiaryImages:[NSOrderedSet orderedSetWithArray:[diaryImages copy]]];

    //Specimens
    NSMutableArray *specimens = [NSMutableArray new];
    NSArray *items = dict[@"specimens"];
    NSEntityDescription *specimenEntity = [NSEntityDescription entityForName:@"SrvaSpecimen" inManagedObjectContext:objectContext];
    if (items && ![items isEqual:[NSNull null]]) {
        for (NSDictionary *item in items) {
            SrvaSpecimen *specimen = (SrvaSpecimen*)[[NSManagedObject alloc] initWithEntity:specimenEntity insertIntoManagedObjectContext:objectContext];
            specimen.age = [RiistaModelUtils checkNull:item key:@"age"];
            specimen.gender = [RiistaModelUtils checkNull:item key:@"gender"];
            [specimens addObject:specimen];
        }
    }
    [entry setSpecimens:[NSOrderedSet orderedSetWithArray:[specimens copy]]];

    return entry;
}

- (NSDictionary*)dictFromSrvaEntry:(SrvaEntry*)srvaEntry isNew:(BOOL)isNew
{
    NSString *dateString = [dateFormatter stringFromDate:srvaEntry.pointOfTime];

    NSMutableDictionary *coordinates = [@{@"latitude":srvaEntry.coordinates.latitude,
                                          @"longitude":srvaEntry.coordinates.longitude,
                                          @"accuracy":srvaEntry.coordinates.accuracy,
                                          @"source":srvaEntry.coordinates.source
                                          } mutableCopy];

    NSMutableArray* specimens = [NSMutableArray new];
    for (SrvaSpecimen *specimen in srvaEntry.specimens) {
        NSDictionary *dict = @{@"gender":[RiistaModelUtils nullify:specimen.gender],
                               @"age":[RiistaModelUtils nullify:specimen.age]
                               };
        [specimens addObject:dict];
    }

    NSMutableArray *methods = [NSMutableArray new];
    for (SrvaMethod *method in [srvaEntry parseMethods]) {
        NSDictionary *dict = @{@"name":method.name,
                               @"isChecked":method.isChecked
                               };
        [methods addObject:dict];
    }

    NSMutableDictionary *dict = [@{ @"type":srvaEntry.type,
                                    @"geoLocation":coordinates,
                                    @"pointOfTime":dateString,
                                    @"description":[RiistaModelUtils nullify:srvaEntry.descriptionText],
                                    @"eventName":[RiistaModelUtils nullify:srvaEntry.eventName],
                                    @"eventType":[RiistaModelUtils nullify:srvaEntry.eventType],
                                    @"totalSpecimenAmount":[RiistaModelUtils nullify:srvaEntry.totalSpecimenAmount],
                                    @"otherMethodDescription":[RiistaModelUtils nullify:srvaEntry.otherMethodDescription],
                                    @"otherTypeDescription":[RiistaModelUtils nullify:srvaEntry.otherTypeDescription],
                                    @"methods":methods,
                                    @"personCount":[RiistaModelUtils nullify:srvaEntry.personCount],
                                    @"timeSpent":[RiistaModelUtils nullify:srvaEntry.timeSpent],
                                    @"eventResult":[RiistaModelUtils nullify:srvaEntry.eventResult],
                                    //authorInfo
                                    @"specimens": specimens,
                                    //rhyId
                                    //state
                                    @"otherSpeciesDescription":[RiistaModelUtils nullify:srvaEntry.otherSpeciesDescription],
                                    @"gameSpeciesCode":[RiistaModelUtils nullify:srvaEntry.gameSpeciesCode],
                                    //approverInfo
                                    @"srvaEventSpecVersion":srvaEntry.srvaEventSpecVersion
                                    } mutableCopy];

    if (isNew) {
        dict[@"mobileClientRefId"] = srvaEntry.mobileClientRefId;
    }
    else {
        dict[@"rev"] = srvaEntry.rev;
    }
    return [dict copy];
}

- (NSMutableArray<SrvaEntry*>*)fetchAllLocalRemoteEvents
{
    return [self query:@"remoteId != NULL" args:@[]];
}

- (NSMutableArray<SrvaEntry*>*)fetchDeletedRemoteEvents
{
    return [self query:@"remoteId != NULL AND pendingOperation = %d" args:@[@(DiaryEntryOperationDelete)]];
}

- (NSMutableArray<SrvaEntry*>*)fetchUnsentEvents
{
    return [self query:@"sent = NO AND pendingOperation != %d" args:@[@(DiaryEntryOperationDelete)]];
}

- (NSMutableArray<SrvaEntry*>*)query:(NSString*)query args:(NSArray*)args
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SrvaEntry"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:query argumentArray:args];
    [request setPredicate:predicate];

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error) {
        DLog(@"SRVA query error: %@", [error localizedDescription]);
        return nil;
    }
    else {
        return [results mutableCopy];
    }
}

@end
