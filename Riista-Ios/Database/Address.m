#import "Address.h"
#import "RiistaUtils.h"


NSString *const kAddressCity = @"city";
NSString *const kAddressEditable = @"editable";
NSString *const kAddressId = @"id";
NSString *const kAddressCountry = @"country";
NSString *const kAddressRev = @"rev";
NSString *const kAddressPostalCode = @"postalCode";
NSString *const kAddressStreetAddress = @"streetAddress";


@implementation Address

@synthesize city = _city;
@synthesize editable = _editable;
@synthesize addressIdentifier = _addressIdentifier;
@synthesize country = _country;
@synthesize rev = _rev;
@synthesize postalCode = _postalCode;
@synthesize streetAddress = _streetAddress;


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
            self.city = [RiistaUtils objectOrNilForKey:kAddressCity fromDictionary:dict];
            self.editable = [[RiistaUtils objectOrNilForKey:kAddressEditable fromDictionary:dict] boolValue];
            self.addressIdentifier = [[RiistaUtils objectOrNilForKey:kAddressId fromDictionary:dict] doubleValue];
            self.country = [RiistaUtils objectOrNilForKey:kAddressCountry fromDictionary:dict];
            self.rev = [[RiistaUtils objectOrNilForKey:kAddressRev fromDictionary:dict] doubleValue];
            self.postalCode = [RiistaUtils objectOrNilForKey:kAddressPostalCode fromDictionary:dict];
            self.streetAddress = [RiistaUtils objectOrNilForKey:kAddressStreetAddress fromDictionary:dict];

    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.city forKey:kAddressCity];
    [mutableDict setValue:[NSNumber numberWithBool:self.editable] forKey:kAddressEditable];
    [mutableDict setValue:[NSNumber numberWithDouble:self.addressIdentifier] forKey:kAddressId];
    [mutableDict setValue:self.country forKey:kAddressCountry];
    [mutableDict setValue:[NSNumber numberWithDouble:self.rev] forKey:kAddressRev];
    [mutableDict setValue:self.postalCode forKey:kAddressPostalCode];
    [mutableDict setValue:self.streetAddress forKey:kAddressStreetAddress];

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

    self.city = [aDecoder decodeObjectForKey:kAddressCity];
    self.editable = [aDecoder decodeBoolForKey:kAddressEditable];
    self.addressIdentifier = [aDecoder decodeDoubleForKey:kAddressId];
    self.country = [aDecoder decodeObjectForKey:kAddressCountry];
    self.rev = [aDecoder decodeDoubleForKey:kAddressRev];
    self.postalCode = [aDecoder decodeObjectForKey:kAddressPostalCode];
    self.streetAddress = [aDecoder decodeObjectForKey:kAddressStreetAddress];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_city forKey:kAddressCity];
    [aCoder encodeBool:_editable forKey:kAddressEditable];
    [aCoder encodeDouble:_addressIdentifier forKey:kAddressId];
    [aCoder encodeObject:_country forKey:kAddressCountry];
    [aCoder encodeDouble:_rev forKey:kAddressRev];
    [aCoder encodeObject:_postalCode forKey:kAddressPostalCode];
    [aCoder encodeObject:_streetAddress forKey:kAddressStreetAddress];
}

- (id)copyWithZone:(NSZone *)zone
{
    Address *copy = [[Address alloc] init];

    if (copy) {

        copy.city = [self.city copyWithZone:zone];
        copy.editable = self.editable;
        copy.addressIdentifier = self.addressIdentifier;
        copy.country = [self.country copyWithZone:zone];
        copy.rev = self.rev;
        copy.postalCode = [self.postalCode copyWithZone:zone];
        copy.streetAddress = [self.streetAddress copyWithZone:zone];
    }

    return copy;
}


@end
