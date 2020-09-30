#import <Foundation/Foundation.h>
#import "RiistaClubAreaMap.h"

typedef void(^RiistaClubAreaMapCallback)(void);

@interface RiistaClubAreaMapManager : NSObject

+(void)clearCache;

-(RiistaClubAreaMap*)findById:(NSString*)externalId;

-(void)fetchMaps:(RiistaClubAreaMapCallback)completion;

-(void)addManualMap:(RiistaClubAreaMap*)map;

-(void)removeManualMap:(NSString*)externalId;

-(NSArray*)getVisibleMaps;

@end
