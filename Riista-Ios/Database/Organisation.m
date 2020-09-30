#import "Organisation.h"
#import "RiistaUtils.h"


NSString *const kOrganisationId = @"id";
NSString *const kOrganisationName = @"name";
NSString *const kOrganisationOfficialCode = @"officialCode";


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
            self.organisationIdentifier = [RiistaUtils objectOrNilForKey:kOrganisationId fromDictionary:dict];
            self.name = [RiistaUtils objectOrNilForKey:kOrganisationName fromDictionary:dict];
            self.officialCode = [RiistaUtils objectOrNilForKey:kOrganisationOfficialCode fromDictionary:dict];

    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.organisationIdentifier forKey:kOrganisationId];
    [mutableDict setValue:self.name forKey:kOrganisationName];
    [mutableDict setValue:self.officialCode forKey:kOrganisationOfficialCode];

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

    self.organisationIdentifier = [aDecoder decodeObjectForKey:kOrganisationId];
    self.name = [aDecoder decodeObjectForKey:kOrganisationName];
    self.officialCode = [aDecoder decodeObjectForKey:kOrganisationOfficialCode];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_organisationIdentifier forKey:kOrganisationId];
    [aCoder encodeObject:_name forKey:kOrganisationName];
    [aCoder encodeObject:_officialCode forKey:kOrganisationOfficialCode];
}

- (id)copyWithZone:(NSZone *)zone
{
    Organisation *copy = [[Organisation alloc] init];

    if (copy) {

        copy.organisationIdentifier = [self.organisationIdentifier copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
        copy.officialCode = [self.officialCode copyWithZone:zone];
    }

    return copy;
}


@end
