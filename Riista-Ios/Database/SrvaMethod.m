#import "SrvaMethod.h"

@implementation SrvaMethod

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _name = dict[@"name"];
        _isChecked = dict[@"isChecked"];
    }
    return self;
}

- (NSDictionary*)toDict
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.name, @"name",
            self.isChecked, @"isChecked",
            nil];
}

@end
