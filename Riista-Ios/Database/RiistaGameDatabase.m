#import "RiistaGameDatabase.h"
#import "RiistaAppDelegate.h"
#import "RiistaSpeciesCategory.h"
#import "RiistaSpecies.h"
#import "RiistaSpecimen.h"
#import "RiistaSessionManager.h"
#import "UserInfo.h"
#import "AnnouncementsSync.h"
#import "NSDateformatter+Locale.h"
#import "Oma_riista-Swift.h"

#import <FirebaseCrashlytics/FirebaseCrashlytics.h>


NSString *const RIISTA_FETCH_TIMES = @"FetchTimes";
const CGFloat MIN_SYNC_INTERVAL_IN_SECONDS = 5.0;

@interface RiistaGameDatabase ()

@property (assign, atomic, readwrite) BOOL synchronizing;

@end

@implementation RiistaGameDatabase
{
    NSDateFormatter *dateFormatter;
    NSDate *lastSyncDate;
}

#pragma mark - public methods

NSString *const RiistaCalendarEntriesUpdatedKey = @"CalendarEntriesUpdated";
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
        self.synchronizing = NO;
        dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
        [dateFormatter setDateFormat:ISO_8601];
    }

    return self;
}

- (void)initUserSession
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.username = [[RiistaSessionManager sharedInstance] userCredentials].username;

    // todo: consider moving user session init + this line should somewhere else
    [AppSync.shared enableSyncPrecondition:SyncPreconditionCredentialsVerified];
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

- (void)synchronizeDiaryEntries:(RiistaCommonSynchronizationLevel * _Nonnull)synchronizationLevel
         synchronizationConfig:(RiistaCommonSynchronizationConfig * _Nonnull)synchronizationConfig
                    completion:(RiistaSynchronizationCompletion _Nullable)completion
{
    // Do not start multiple synchronization operations at once
    if (self.synchronizing) {
        if (completion) {
            completion();
        }
        return;
    }
    self.synchronizing = YES;

    [RiistaSDKHelper synchronizeWithSynchronizationLevel:synchronizationLevel
                                   synchronizationConfig:synchronizationConfig
                                              completion:^{
        [self synchronizeAnnouncementsAndPermits:^(void) {
            self.synchronizing = NO;
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)synchronizeAnnouncementsAndPermits:(RiistaSynchronizationCompletion)completion
{
    // Limit rate of user synchronization attempts
    if (lastSyncDate && [lastSyncDate timeIntervalSinceNow] > -MIN_SYNC_INTERVAL_IN_SECONDS) {
        if (completion) {
            completion();
        }
        return;
    }

    lastSyncDate = [NSDate date];

    [[NSNotificationCenter defaultCenter] postNotificationName:RiistaCalendarEntriesUpdatedKey object:nil userInfo:nil];

    [[AnnouncementsSync new] sync:^(NSArray *items, NSError *error) {
        [CrashlyticsHelper logWithMsg:@"Diary entry synchronization completed!"];

        if (completion) {
            completion();
        }
    }];
}


#pragma mark - Observations

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
