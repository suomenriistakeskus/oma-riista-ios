#import "SrvaMetadata.h"
#import "RiistaGameDatabase.h"
#import "SrvaEventMetadata.h"

@implementation SrvaMetadata

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _ages = dict[@"ages"];
        _genders = dict[@"genders"];

        NSMutableArray* srvaSpecies = [NSMutableArray new];
        for (NSDictionary* spec in dict[@"species"]) {
            NSInteger speciesId = [spec[@"code"] integerValue];
            RiistaSpecies* species = [[RiistaGameDatabase sharedInstance] speciesById:speciesId];
            [srvaSpecies addObject:species];
        }
        _species = srvaSpecies;

        NSMutableArray* srvaEvents = [NSMutableArray new];
        for (NSDictionary* event in dict[@"events"]) {
            [srvaEvents addObject:[[SrvaEventMetadata alloc] initWithDictionary:event]];
        }
        _events = srvaEvents;
    }

    return self;
}

@end
