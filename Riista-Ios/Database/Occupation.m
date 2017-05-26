#import "Occupation.h"
#import "Organisation.h"


NSString *const kOccupationsOrganisation = @"organisation";
NSString *const kOccupationsEndDate = @"endDate";
NSString *const kOccupationsOccupationType = @"occupationType";
NSString *const kOccupationsName = @"name";
NSString *const kOccupationsBeginDate = @"beginDate";

static NSString *const DATE_FORMAT_NO_TIME = @"yyyy-MM-dd";

@interface Occupation ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;
- (NSDate *)dateOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation Occupation
{
    NSDateFormatter *dateFormatter;
}

@synthesize organisation = _organisation;
@synthesize endDate = _endDate;
@synthesize occupationType = _occupationType;
@synthesize name = _name;
@synthesize beginDate = _beginDate;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];

    dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:DATE_FORMAT_NO_TIME];

    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
        self.organisation = [Organisation modelObjectWithDictionary:[dict objectForKey:kOccupationsOrganisation]];
        self.endDate = [self dateOrNilForKey:kOccupationsEndDate fromDictionary:dict];
        self.occupationType = [self objectOrNilForKey:kOccupationsOccupationType fromDictionary:dict];
        self.name = [self objectOrNilForKey:kOccupationsName fromDictionary:dict];
        self.beginDate = [self dateOrNilForKey:kOccupationsBeginDate fromDictionary:dict];

    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[self.organisation dictionaryRepresentation] forKey:kOccupationsOrganisation];
    [mutableDict setValue:self.endDate forKey:kOccupationsEndDate];
    [mutableDict setValue:self.occupationType forKey:kOccupationsOccupationType];
    [mutableDict setValue:self.name forKey:kOccupationsName];
    [mutableDict setValue:self.beginDate forKey:kOccupationsBeginDate];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}

- (NSDate *)dateOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [self objectOrNilForKey:aKey fromDictionary:dict];
    return [dateFormatter dateFromString:object];
}

#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.organisation = [aDecoder decodeObjectForKey:kOccupationsOrganisation];
    self.endDate = [aDecoder decodeObjectForKey:kOccupationsEndDate];
    self.occupationType = [aDecoder decodeObjectForKey:kOccupationsOccupationType];
    self.name = [aDecoder decodeObjectForKey:kOccupationsName];
    self.beginDate = [aDecoder decodeObjectForKey:kOccupationsBeginDate];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_organisation forKey:kOccupationsOrganisation];
    [aCoder encodeObject:_endDate forKey:kOccupationsEndDate];
    [aCoder encodeObject:_occupationType forKey:kOccupationsOccupationType];
    [aCoder encodeObject:_name forKey:kOccupationsName];
    [aCoder encodeObject:_beginDate forKey:kOccupationsBeginDate];
}

- (id)copyWithZone:(NSZone *)zone
{
    Occupation *copy = [[Occupation alloc] init];

    if (copy) {

        copy.organisation = [self.organisation copyWithZone:zone];
        copy.endDate = [self.endDate copyWithZone:zone];
        copy.occupationType = [self.occupationType copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
        copy.beginDate = [self.beginDate copyWithZone:zone];
    }

    return copy;
}


@end
