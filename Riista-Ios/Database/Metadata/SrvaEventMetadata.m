#import "SrvaEventMetadata.h"
#import "SrvaMethod.h"

@implementation SrvaEventMetadata

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _name = dict[@"name"];
        _types = dict[@"types"];
        _results = dict[@"results"];

        NSMutableArray* eventMethods = [NSMutableArray new];
        for (NSDictionary* method in dict[@"methods"]) {
            [eventMethods addObject:[[SrvaMethod alloc] initWithDictionary:method]];
        }
        _methods = eventMethods;
    }
    return self;
}

@end
