#import "Organisation.h"


NSString *const kOrganisationId = @"id";
NSString *const kOrganisationName = @"name";
NSString *const kOrganisationOfficialCode = @"officialCode";


@interface Organisation ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation Organisation

@synthesize organisationIdentifier = _organisationIdentifier;
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
            self.organisationIdentifier = [[self objectOrNilForKey:kOrganisationId fromDictionary:dict] doubleValue];
            self.name = [self objectOrNilForKey:kOrganisationName fromDictionary:dict];
            self.officialCode = [self objectOrNilForKey:kOrganisationOfficialCode fromDictionary:dict];

    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[NSNumber numberWithDouble:self.organisationIdentifier] forKey:kOrganisationId];
    [mutableDict setValue:self.name forKey:kOrganisationName];
    [mutableDict setValue:self.officialCode forKey:kOrganisationOfficialCode];

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


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.organisationIdentifier = [aDecoder decodeDoubleForKey:kOrganisationId];
    self.name = [aDecoder decodeObjectForKey:kOrganisationName];
    self.officialCode = [aDecoder decodeObjectForKey:kOrganisationOfficialCode];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeDouble:_organisationIdentifier forKey:kOrganisationId];
    [aCoder encodeObject:_name forKey:kOrganisationName];
    [aCoder encodeObject:_officialCode forKey:kOrganisationOfficialCode];
}

- (id)copyWithZone:(NSZone *)zone
{
    Organisation *copy = [[Organisation alloc] init];

    if (copy) {

        copy.organisationIdentifier = self.organisationIdentifier;
        copy.name = [self.name copyWithZone:zone];
        copy.officialCode = [self.officialCode copyWithZone:zone];
    }

    return copy;
}


@end
