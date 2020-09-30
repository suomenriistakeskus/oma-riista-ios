#import "Rhy.h"
#import "RiistaUtils.h"


NSString *const kRhyId = @"id";
NSString *const kRhyName = @"name";
NSString *const kRhyOfficialCode = @"officialCode";


@implementation Rhy

@synthesize rhyIdentifier = _rhyIdentifier;
@synthesize name = _name;
@synthesize officialCode = _officialCode;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];

    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
        self.rhyIdentifier = [[RiistaUtils objectOrNilForKey:kRhyId fromDictionary:dict] doubleValue];
        self.name = [RiistaUtils objectOrNilForKey:kRhyName fromDictionary:dict];
        self.officialCode = [RiistaUtils objectOrNilForKey:kRhyOfficialCode fromDictionary:dict];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[NSNumber numberWithDouble:self.rhyIdentifier] forKey:kRhyId];
    [mutableDict setValue:self.name forKey:kRhyName];
    [mutableDict setValue:self.officialCode forKey:kRhyOfficialCode];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.rhyIdentifier = [aDecoder decodeDoubleForKey:kRhyId];
    self.name = [aDecoder decodeObjectForKey:kRhyName];
    self.officialCode = [aDecoder decodeObjectForKey:kRhyOfficialCode];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeDouble:_rhyIdentifier forKey:kRhyId];
    [aCoder encodeObject:_name forKey:kRhyName];
    [aCoder encodeObject:_officialCode forKey:kRhyOfficialCode];
}

- (id)copyWithZone:(NSZone *)zone
{
    Rhy *copy = [[Rhy alloc] init];

    if (copy) {

        copy.rhyIdentifier = self.rhyIdentifier;
        copy.name = [self.name copyWithZone:zone];
        copy.officialCode = [self.officialCode copyWithZone:zone];
    }

    return copy;
}


@end
