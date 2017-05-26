#import "DiaryImage.h"
#import "GeoCoordinate.h"
#import "ObservationEntry.h"
#import "ObservationSpecimen.h"
#import "ObservationSync.h"
#import "RiistaAppDelegate.h"
#import "RiistaGameDatabase.h"
#import "RiistaModelUtils.h"
#import "RiistaNetworkManager.h"
#import "RiistaSettings.h"
#import "UserInfo.h"

@implementation ObservationSync
{
    NSDateFormatter *dateFormatter;
    NSManagedObjectContext* context;
}

- (id)init
{
    self = [super init];
    if (self) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:ISO_8601];
    }
    return self;
}

- (void)sync:(ObservationSynchronizationCompletion)completion
{
    RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = delegate.managedObjectContext;

    NSMutableArray<ObservationEntry*> *deleted = [self fetchDeletedRemoteEvents];
    DLog(@"Deleting: %ld", deleted.count);
    [self deleteRemoteObservationEvents:deleted completion:completion];
}

- (void)deleteRemoteObservationEvents:(NSMutableArray<ObservationEntry*>*)events completion:(ObservationSynchronizationCompletion)completion
{
    if (events.count == 0) {
        [self sendUnsentEvents:completion];
        return;
    }
    ObservationEntry *entry = events[events.count - 1];
    [events removeObjectAtIndex:events.count - 1];

    [[RiistaGameDatabase sharedInstance] deleteObservationEntry:entry completion:^(NSError *error) {
        if (error) {
            DLog(@"Observation delete error: %@", [error localizedDescription]);
        }
        [self deleteRemoteObservationEvents:events completion:completion];
    }];
}

- (void)sendUnsentEvents:(ObservationSynchronizationCompletion)completion
{
    NSMutableArray<ObservationEntry*> *unsent = [self fetchUnsentEvents];
    DLog(@"Sending: %ld", unsent.count);
    [self sendObservationEvents:unsent completion:completion];
}

- (void)sendObservationEvents:(NSMutableArray<ObservationEntry*>*)events completion:(ObservationSynchronizationCompletion)completion
{
    if (events.count == 0) {
        [self downloadServerEvents:completion];
        return;
    }
    ObservationEntry *entry = events[events.count - 1];
    [events removeObjectAtIndex:events.count - 1];

    [[RiistaGameDatabase sharedInstance] editObservationEntry:entry completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            DLog(@"Observation send error: %@", [error localizedDescription]);
        }
        [self sendObservationEvents:events completion:completion];
    }];
}

- (void)downloadServerEvents:(ObservationSynchronizationCompletion)completion
{
    NSArray *localYears = [[RiistaGameDatabase sharedInstance] observationYears];

    UserInfo *user = [RiistaSettings userInfo];
    NSArray *remoteYears = user.observationYears;

    // Delete entries from year which no longer contain any entries
    if (localYears) {
        for (int i=0; i<localYears.count; i++) {
            NSNumber *localYear = localYears[i];
            if (remoteYears.count == 0 || ![remoteYears containsObject:localYear]) {
                NSArray *entries = [self fetchAllLocalRemoteObservationsForYear:[localYear integerValue]];

                if (entries) {
                    for (ObservationEntry *item in entries) {
                        [context deleteObject:item];
                    }
                }
            }
        }
        [RiistaModelUtils saveContexts:context];
    }

    [self downloadServerEventsForYear:[remoteYears mutableCopy] completion:completion];
}

- (void)downloadServerEventsForYear:(NSMutableArray<NSNumber*>*)years completion:(ObservationSynchronizationCompletion)completion
{
    if (years.count == 0) {
        [self syncFinished:completion];
        return;
    }

    NSInteger year = [years[years.count - 1] integerValue];
    [years removeObjectAtIndex:years.count - 1];

    [[RiistaNetworkManager sharedInstance] diaryObservationsForYear:year completion:^(NSArray *entries, NSError *error) {
        if (!error) {
            NSMutableArray<ObservationEntry*> *localEvents = [self fetchAllLocalRemoteObservationsForYear:year];
            NSDictionary* localsMap = [self createRemoteIdMap:localEvents];
            NSMutableDictionary* remotesMap = [NSMutableDictionary new];

            for (NSDictionary* dict in entries) {
                ObservationEntry* entry = [self observationEntryFromDict:dict objectContext:context];
                ObservationEntry* old = [localsMap objectForKey:entry.remoteId];

                if ([self insertReceivedEvent:entry oldEntry:old]) {
                    if (old) {
                        [context deleteObject:old];
                    }
                    [context insertObject:entry];
                }
                else {
                    [context deleteObject:entry];
                }

                [remotesMap setObject:entry forKey:entry.remoteId];
            }

            for (NSNumber *remoteId in localsMap) {
                //If our local entry remoteId is missing from server entries, it was deleted
                ObservationEntry *remote = [remotesMap objectForKey:remoteId];
                if (remote == nil) {
                    ObservationEntry* local = [localsMap objectForKey:remoteId];
                    [context deleteObject:local];
                }
            }
        }
        [self downloadServerEventsForYear:years completion:completion];
    }];
}

- (BOOL)insertReceivedEvent:(ObservationEntry*)newEntry oldEntry:(ObservationEntry*)oldEntry
{
    if (!oldEntry
        || [newEntry.rev integerValue] > [oldEntry.rev integerValue]
        || (newEntry.observationSpecVersion > oldEntry.observationSpecVersion)
        || (newEntry.canEdit != oldEntry.canEdit)) {
        return YES;
    }

    return NO;
}

- (NSDictionary*)createRemoteIdMap:(NSArray<ObservationEntry*>*)entries
{
    NSMutableDictionary* result = [NSMutableDictionary new];
    for (ObservationEntry* entry in entries) {
        if (entry.remoteId != nil) {
            [result setObject:entry forKey:entry.remoteId];
        }
    }
    return result;
}

- (void)syncFinished:(ObservationSynchronizationCompletion)completion
{
    [RiistaModelUtils saveContexts:context];

    completion();
}

- (ObservationEntry*)observationEntryFromDict:(NSDictionary*)dict objectContext:(NSManagedObjectContext*)objectContext
{
    GeoCoordinate *coordinates = [RiistaModelUtils coordinatesFromDict:dict context:objectContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ObservationEntry" inManagedObjectContext:objectContext];
    ObservationEntry *entry = [[ObservationEntry alloc] initWithEntity:entity insertIntoManagedObjectContext:objectContext];

    NSDate *date = [dateFormatter dateFromString:dict[@"pointOfTime"]];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];

    entry.totalSpecimenAmount = [RiistaModelUtils checkNull:dict key:@"totalSpecimenAmount"];
    entry.diarydescription = [RiistaModelUtils checkNull:dict key:@"description"];
    entry.gameSpeciesCode = dict[@"gameSpeciesCode"];
    entry.linkedToGroupHuntingDay = dict[@"linkedToGroupHuntingDay"];
    entry.canEdit = dict[@"canEdit"];
    entry.month = [NSNumber numberWithInteger:components.month];
    entry.pointOfTime = date;
    entry.remote = [NSNumber numberWithBool:YES];
    entry.remoteId = dict[@"id"];
    entry.rev = dict[@"rev"];
    entry.sent = [NSNumber numberWithBool:YES];
    entry.type = dict[@"type"];
    entry.year = [NSNumber numberWithInteger:components.year];
    entry.mobileClientRefId = [RiistaModelUtils checkNull:dict key:@"mobileClientRefId"];
    entry.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationNone];
    entry.coordinates = coordinates;

    entry.observationSpecVersion = dict[@"observationSpecVersion"];
    entry.observationType = dict[@"observationType"];
    entry.withinMooseHunting = [RiistaModelUtils checkNull:dict key:@"withinMooseHunting"];

    entry.mooselikeFemale1CalfAmount = dict[@"mooselikeFemale1CalfAmount"];
    entry.mooselikeFemale2CalfsAmount = dict[@"mooselikeFemale2CalfsAmount"];
    entry.mooselikeFemale3CalfsAmount = dict[@"mooselikeFemale3CalfsAmount"];
    entry.mooselikeFemale4CalfsAmount = dict[@"mooselikeFemale4CalfsAmount"];
    entry.mooselikeFemaleAmount = dict[@"mooselikeFemaleAmount"];
    entry.mooselikeMaleAmount = dict[@"mooselikeMaleAmount"];
    entry.mooselikeUnknownSpecimenAmount = dict[@"mooselikeUnknownSpecimenAmount"];

    // Images
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

    // Specimens
    NSMutableArray *specimens = [NSMutableArray new];
    NSMutableArray *items = dict[@"specimens"];
    NSEntityDescription *specimenEntity = [NSEntityDescription entityForName:@"ObservationSpecimen" inManagedObjectContext:objectContext];
    if (items && ![items isEqual:[NSNull null]]) {
        for (NSDictionary *item in items) {
            ObservationSpecimen *specimen = (ObservationSpecimen*)[[NSManagedObject alloc] initWithEntity:specimenEntity insertIntoManagedObjectContext:objectContext];
            specimen.remoteId = item[@"id"];
            specimen.rev = item[@"rev"];
            specimen.age = [RiistaModelUtils checkNull:item key:@"age"];
            specimen.gender = [RiistaModelUtils checkNull:item key:@"gender"];
            specimen.marking = [RiistaModelUtils checkNull:item key:@"marking"];
            specimen.state = [RiistaModelUtils checkNull:item key:@"state"];
            [specimens addObject:specimen];
        }
    }
    [entry setSpecimens:[NSOrderedSet orderedSetWithArray:[specimens copy]]];

    return entry;
}

- (NSDictionary*)dictFromObservationEntry:(ObservationEntry*)observationEntry isNew:(BOOL)isNew
{
    [dateFormatter setDateFormat:ISO_8601];
    NSString *dateString = [dateFormatter stringFromDate:observationEntry.pointOfTime];

    NSMutableDictionary *coordinates = [@{@"latitude":observationEntry.coordinates.latitude,
                                          @"longitude":observationEntry.coordinates.longitude,
                                          @"accuracy":observationEntry.coordinates.accuracy,
                                          @"source":observationEntry.coordinates.source
                                          } mutableCopy];
    NSMutableArray *specimens = [self generateObservationSpecimenArray:observationEntry.specimens];

    // Assume that specimens is set null only when observation has no amount data.
    NSMutableDictionary *dict = [@{ @"description":observationEntry.diarydescription,
                                    @"gameSpeciesCode":observationEntry.gameSpeciesCode,
                                    @"pointOfTime":dateString,
                                    @"type":observationEntry.type,
                                    @"specimens":observationEntry.totalSpecimenAmount ? specimens : [NSNull null],
                                    @"geoLocation":coordinates,
                                    @"totalSpecimenAmount":[RiistaModelUtils nullify:observationEntry.totalSpecimenAmount],
                                    @"observationSpecVersion":observationEntry.observationSpecVersion,
                                    @"observationType":observationEntry.observationType,
                                    @"withinMooseHunting":[RiistaModelUtils nullify:observationEntry.withinMooseHunting],
                                    @"mooselikeFemale1CalfAmount":[RiistaModelUtils nullify:observationEntry.mooselikeFemale1CalfAmount],
                                    @"mooselikeFemale2CalfsAmount":[RiistaModelUtils nullify:observationEntry.mooselikeFemale2CalfsAmount],
                                    @"mooselikeFemale3CalfsAmount":[RiistaModelUtils nullify:observationEntry.mooselikeFemale3CalfsAmount],
                                    @"mooselikeFemale4CalfsAmount":[RiistaModelUtils nullify:observationEntry.mooselikeFemale4CalfsAmount],
                                    @"mooselikeFemaleAmount":[RiistaModelUtils nullify:observationEntry.mooselikeFemaleAmount],
                                    @"mooselikeMaleAmount":[RiistaModelUtils nullify:observationEntry.mooselikeMaleAmount],
                                    @"mooselikeUnknownSpecimenAmount":[RiistaModelUtils nullify:observationEntry.mooselikeUnknownSpecimenAmount]
                                    } mutableCopy];

    if (isNew) {
        dict[@"mobileClientRefId"] = observationEntry.mobileClientRefId;
    }
    else {
        dict[@"rev"] = observationEntry.rev;
    }

    return [dict copy];
}

- (NSMutableArray*)generateObservationSpecimenArray:(NSOrderedSet*)specimens
{
    NSMutableArray *result = [NSMutableArray new];
    for (ObservationSpecimen *specimen in specimens) {
        NSMutableDictionary *item =[@{@"age":[RiistaModelUtils nullify:specimen.age],
                                      @"gender":[RiistaModelUtils nullify:specimen.gender],
                                      @"marking":[RiistaModelUtils nullify:specimen.marking],
                                      @"state":[RiistaModelUtils nullify:specimen.state]
                                      } mutableCopy];

        if ([specimen.remoteId intValue] > 0) {
            [item setObject:specimen.remoteId forKey:@"id"];
            [item setObject:specimen.rev forKey:@"rev"];
        }

        [result addObject:item];
    }

    return result;
}

- (NSMutableArray<ObservationEntry*>*) fetchAllLocalRemoteObservationsForYear:(NSInteger)year
{
    NSNumber *startYear = [NSNumber numberWithInteger:year];
    NSNumber *endYear = [NSNumber numberWithInteger:year + 1];
    NSNumber *startMonth = [NSNumber numberWithInteger:RiistaCalendarStartMonth];

    return [self query:@"((year = %d AND month >= %d) OR (year = %d AND month < %d)) AND remoteId != NULL"
                  args:@[startYear, startMonth, endYear, startMonth]];
}

- (NSMutableArray<ObservationEntry*>*)fetchDeletedRemoteEvents
{
    return [self query:@"remoteId != NULL AND pendingOperation = %d" args:@[@(DiaryEntryOperationDelete)]];
}

- (NSMutableArray<ObservationEntry*>*)fetchUnsentEvents
{
    return [self query:@"sent = NO AND pendingOperation != %d" args:@[@(DiaryEntryOperationDelete)]];
}

- (NSMutableArray<ObservationEntry*>*)query:(NSString*)query args:(NSArray*)args
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ObservationEntry"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:query argumentArray:args];
    [request setPredicate:predicate];

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error) {
        DLog(@"Observation query error: %@", [error localizedDescription]);
        return nil;
    }
    else {
        return [results mutableCopy];
    }
}

@end
