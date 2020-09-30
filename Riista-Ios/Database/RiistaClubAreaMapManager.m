#import "RiistaClubAreaMapManager.h"
#import "RiistaNetworkManager.h"
#import "RiistaUtils.h"

@implementation RiistaClubAreaMapManager
{
    NSMutableArray<RiistaClubAreaMap*> *allMaps;
}

-(id)init
{
    self = [super init];
    if (self) {
        allMaps = [NSMutableArray new];
    }
    return self;
}

+(void)clearCache
{
    NSString *path = [RiistaClubAreaMapManager getCacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL ok = [fileManager removeItemAtPath:path error:nil];
    if (!ok) {
        NSLog(@"Map cache clear failed!");
    }
}

+(NSString*)getCacheFilePath
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filename = [docsPath stringByAppendingPathComponent:@"clubAreaMaps2"];
    return filename;
}

-(void)saveMapsToFile
{
    BOOL ok = [NSKeyedArchiver archiveRootObject:allMaps toFile:[RiistaClubAreaMapManager getCacheFilePath]];
    if (!ok) {
        NSLog(@"Map saving failed!");
    }
}

-(void)loadMapsFromFile
{
    NSArray* maps = [NSKeyedUnarchiver unarchiveObjectWithFile:[RiistaClubAreaMapManager getCacheFilePath]];
    if (maps) {
        [allMaps removeAllObjects];
        [allMaps addObjectsFromArray:maps];
    }
}

-(RiistaClubAreaMap*)findById:(NSString*)externalId
{
    if (externalId != nil) {
        for (int i = 0; i < allMaps.count; i++) {
            RiistaClubAreaMap *map = [allMaps objectAtIndex:i];
            if ([map.externalId isEqualToString:externalId]) {
                return map;
            }
        }
    }
    return nil;
}

-(NSMutableArray<RiistaClubAreaMap*>*)getManuallyAdded
{
    NSMutableArray<RiistaClubAreaMap*> *results = [NSMutableArray new];

    for (int i = 0; i < allMaps.count; ++i) {
        RiistaClubAreaMap *map = [allMaps objectAtIndex:i];
        if (map.manuallyAdded) {
            [results addObject:map];
        }
    }
    return results;
}

-(NSMutableArray*)filterMaps:(NSArray*)maps
{
    NSMutableArray *results = [NSMutableArray new];
    for (int i = 0; i < maps.count; i++) {
        RiistaClubAreaMap *map = [maps objectAtIndex:i];
        if (map.externalId) {
            [results addObject:map];
        }
    }

    //Sort by name
    [results sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        RiistaClubAreaMap *a = obj1;
        RiistaClubAreaMap *b = obj2;
        return [[RiistaUtils getLocalizedString:a.name] caseInsensitiveCompare:[RiistaUtils getLocalizedString:b.name]];
    }];

    return results;
}

-(void)fetchMaps:(RiistaClubAreaMapCallback)completion
{
    [self loadMapsFromFile];

    completion(); //Cached maps, if any

    [[RiistaNetworkManager sharedInstance] clubAreaMaps:^(NSArray *items, NSError *error) {
        if (error) {
            completion();
        }
        else {
            NSMutableArray<RiistaClubAreaMap*> *remote = [NSMutableArray new];
            NSMutableArray<RiistaClubAreaMap*> *manuals = [self getManuallyAdded];

            for (int i = 0; i < items.count; i++) {
                NSDictionary *dict = [items objectAtIndex:i];
                if (dict) {
                    RiistaClubAreaMap *map = [[RiistaClubAreaMap alloc] initWithDict:dict];
                    if (map.externalId) {
                        [remote addObject:map];
                    }
                }
            }

            [self->allMaps removeAllObjects];
            [self->allMaps addObjectsFromArray:remote];
            [self->allMaps addObjectsFromArray:manuals];

            [self saveMapsToFile];

            completion();
        }
    }];
}

-(void)addManualMap:(RiistaClubAreaMap*)map
{
    if (map.manuallyAdded) {
        //Remove old if it exists
        [self removeManualMap:map.externalId];

        [allMaps addObject:map];

        [self saveMapsToFile];
    }
}

-(void)removeManualMap:(NSString*)externalId
{
    for (int i = 0; i < allMaps.count; i++) {
        RiistaClubAreaMap *map = [allMaps objectAtIndex:i];
        if (map.manuallyAdded && [map.externalId isEqualToString:externalId]) {
            [allMaps removeObjectAtIndex:i];
            break;
        }
    }

    [self saveMapsToFile];
}

-(NSArray*)getVisibleMaps
{
    return [self filterMaps:allMaps];
}

@end
