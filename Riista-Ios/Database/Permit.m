#import "Permit.h"
#import "PermitSpeciesAmounts.h"
#import "RiistaUtils.h"


NSString *const kPermitBaseClassId = @"id";
NSString *const kPermitBaseClassRev = @"rev";
NSString *const kPermitBaseClassPermitNumber = @"permitNumber";
NSString *const kPermitBaseClassPermitType = @"permitType";
NSString *const kPermitBaseClassSpeciesAmounts = @"speciesAmounts";
NSString *const kPermitBaseClassUnavailable = @"unavailable";


@implementation Permit

@synthesize permitIdentifier = _permitIdentifier;
@synthesize rev = _rev;
@synthesize permitNumber = _permitNumber;
@synthesize permitType = _permitType;
@synthesize unavailable = _unavailable;
@synthesize speciesAmounts = _speciesAmounts;


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
            self.permitNumber = [RiistaUtils objectOrNilForKey:kPermitBaseClassPermitNumber fromDictionary:dict];
            self.permitIdentifier = [[RiistaUtils objectOrNilForKey:kPermitBaseClassId fromDictionary:dict] integerValue];
            self.rev = [[RiistaUtils objectOrNilForKey:kPermitBaseClassRev fromDictionary:dict] integerValue];
            self.permitType = [RiistaUtils objectOrNilForKey:kPermitBaseClassPermitType fromDictionary:dict];
            self.unavailable = [[RiistaUtils objectOrNilForKey:kPermitBaseClassUnavailable fromDictionary:dict] boolValue];
    NSObject *receivedPermitSpeciesAmounts = [dict objectForKey:kPermitBaseClassSpeciesAmounts];
    NSMutableArray *parsedPermitSpeciesAmounts = [NSMutableArray array];
    if ([receivedPermitSpeciesAmounts isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in (NSArray *)receivedPermitSpeciesAmounts) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                [parsedPermitSpeciesAmounts addObject:[PermitSpeciesAmounts modelObjectWithDictionary:item]];
            }
       }
    } else if ([receivedPermitSpeciesAmounts isKindOfClass:[NSDictionary class]]) {
       [parsedPermitSpeciesAmounts addObject:[PermitSpeciesAmounts modelObjectWithDictionary:(NSDictionary *)receivedPermitSpeciesAmounts]];
    }

    self.speciesAmounts = [NSArray arrayWithArray:parsedPermitSpeciesAmounts];

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.permitNumber forKey:kPermitBaseClassPermitNumber];
    [mutableDict setValue:[NSNumber numberWithInteger:self.permitIdentifier] forKey:kPermitBaseClassId];
    [mutableDict setValue:[NSNumber numberWithInteger:self.rev] forKey:kPermitBaseClassRev];
    [mutableDict setValue:self.permitType forKey:kPermitBaseClassPermitType];
    [mutableDict setValue:[NSNumber numberWithBool:self.unavailable] forKey:kPermitBaseClassUnavailable];
    NSMutableArray *tempArrayForSpeciesAmounts = [NSMutableArray array];
    for (NSObject *subArrayObject in self.speciesAmounts) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForSpeciesAmounts addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForSpeciesAmounts addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSpeciesAmounts] forKey:kPermitBaseClassSpeciesAmounts];

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

    self.permitNumber = [aDecoder decodeObjectForKey:kPermitBaseClassPermitNumber];
    self.permitIdentifier = [aDecoder decodeIntegerForKey:kPermitBaseClassId];
    self.rev = [aDecoder decodeIntegerForKey:kPermitBaseClassRev];
    self.permitType = [aDecoder decodeObjectForKey:kPermitBaseClassPermitType];
    self.unavailable = [aDecoder decodeBoolForKey:kPermitBaseClassUnavailable];
    self.speciesAmounts = [aDecoder decodeObjectForKey:kPermitBaseClassSpeciesAmounts];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_permitNumber forKey:kPermitBaseClassPermitNumber];
    [aCoder encodeInteger:_permitIdentifier forKey:kPermitBaseClassId];
    [aCoder encodeInteger:_rev forKey:kPermitBaseClassRev];
    [aCoder encodeObject:_permitType forKey:kPermitBaseClassPermitType];
    [aCoder encodeBool:_unavailable forKey:kPermitBaseClassUnavailable];
    [aCoder encodeObject:_speciesAmounts forKey:kPermitBaseClassSpeciesAmounts];
}

- (id)copyWithZone:(NSZone *)zone
{
    Permit *copy = [[Permit alloc] init];
    
    if (copy) {

        copy.permitNumber = [self.permitNumber copyWithZone:zone];
        copy.permitIdentifier = self.permitIdentifier;
        copy.rev = self.rev;
        copy.permitType = [self.permitType copyWithZone:zone];
        copy.unavailable = self.unavailable;
        copy.speciesAmounts = [self.speciesAmounts copyWithZone:zone];
    }
    
    return copy;
}


@end
