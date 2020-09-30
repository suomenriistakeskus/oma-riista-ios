#import "RiistaClubAreaMap.h"

@implementation RiistaClubAreaMap

- (id)initWithDict:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        _type = [dict objectForKey:@"type"];
        _huntingYear = [[dict objectForKey:@"huntingYear"] integerValue];
        _name = [dict objectForKey:@"name"];
        _club = [dict objectForKey:@"clubName"];
        _externalId = [dict objectForKey:@"externalId"];
        _modificationTime = [dict objectForKey:@"modificationTime"];
        _manuallyAdded = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        _type = [decoder decodeObjectForKey:@"type"];
        _huntingYear = [[decoder decodeObjectForKey:@"huntingYear"] integerValue];
        _name = [decoder decodeObjectForKey:@"name"];
        _club = [decoder decodeObjectForKey:@"clubName"];
        _externalId = [decoder decodeObjectForKey:@"externalId"];
        _modificationTime = [decoder decodeObjectForKey:@"modificationTime"];
        _manuallyAdded = [[decoder decodeObjectForKey:@"manuallyAdded"] boolValue];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:[NSNumber numberWithInteger:self.huntingYear] forKey:@"huntingYear"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.club forKey:@"clubName"];
    [encoder encodeObject:self.externalId forKey:@"externalId"];
    [encoder encodeObject:self.modificationTime forKey:@"modificationTime"];
    [encoder encodeObject:[NSNumber numberWithBool:self.manuallyAdded] forKey:@"manuallyAdded"];
}

@end
