#import "ShootingTest.h"
#import "RiistaUtils.h"

NSString *const kRhyNameField = @"rhyName";
NSString *const kType = @"type";
NSString *const kOfficialCode = @"officialCode";
NSString *const kBegin = @"begin";
NSString *const kEnd = @"end";
NSString *const kExpired = @"expired";


@implementation ShootingTest

@synthesize rhyName = _rhyName;
@synthesize type = _type;
@synthesize officialCode = _officialCode;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize expired = _expired;

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
        self.rhyName = [RiistaUtils objectOrNilForKey:kRhyNameField fromDictionary:dict];
        self.type = [RiistaUtils objectOrNilForKey:kType fromDictionary:dict];
        self.officialCode = [RiistaUtils objectOrNilForKey:kOfficialCode fromDictionary:dict];
        self.begin = [RiistaUtils objectOrNilForKey:kBegin fromDictionary:dict];
        self.end = [RiistaUtils objectOrNilForKey:kEnd fromDictionary:dict];
        self.expired = [[RiistaUtils objectOrNilForKey:kExpired fromDictionary:dict] boolValue];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.rhyName forKey:kRhyNameField];
    [mutableDict setValue:self.type forKey:kType];
    [mutableDict setValue:self.officialCode forKey:kOfficialCode];
    [mutableDict setValue:self.begin forKey:kBegin];
    [mutableDict setValue:self.end forKey:kEnd];
    [mutableDict setValue:[NSNumber numberWithBool:self.expired] forKey:kExpired];

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

    self.rhyName = [aDecoder decodeObjectForKey:kRhyNameField];
    self.type = [aDecoder decodeObjectForKey:kType];
    self.officialCode = [aDecoder decodeObjectForKey:kOfficialCode];
    self.begin = [aDecoder decodeObjectForKey:kBegin];
    self.end = [aDecoder decodeObjectForKey:kEnd];
    self.expired = [aDecoder decodeBoolForKey:kExpired];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_rhyName forKey:kRhyNameField];
    [aCoder encodeObject:_type forKey:kType];
    [aCoder encodeObject:_officialCode forKey:kOfficialCode];
    [aCoder encodeObject:_begin forKey:kBegin];
    [aCoder encodeObject:_end forKey:kEnd];
    [aCoder encodeBool:_expired forKey:kExpired];
}

- (id)copyWithZone:(NSZone *)zone
{
    ShootingTest *copy = [[ShootingTest alloc] init];

    if (copy) {
        copy.rhyName = [self.rhyName copyWithZone:zone];
        copy.type = [self.type copyWithZone:zone];
        copy.officialCode = [self.officialCode copyWithZone:zone];
        copy.begin = [self.begin copyWithZone:zone];
        copy.end = [self.end copyWithZone:zone];
        copy.expired = self.expired;
    }

    return copy;
}

@end
