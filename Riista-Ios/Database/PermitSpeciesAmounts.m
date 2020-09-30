#import "PermitSpeciesAmounts.h"
#import "NSDateformatter+Locale.h"
#import "RiistaUtils.h"

NSString *const kPermitSpeciesAmountsGameSpeciesCode = @"gameSpeciesCode";
NSString *const kPermitSpeciesAmountsAmount = @"amount";
NSString *const kPermitSpeciesAmountsBeginDate = @"beginDate";
NSString *const kPermitSpeciesAmountsEndDate = @"endDate";
NSString *const kPermitSpeciesAmountsBeginDate2 = @"beginDate2";
NSString *const kPermitSpeciesAmountsEndDate2 = @"endDate2";
NSString *const kPermitSpeciesAmountsGenderRequired = @"genderRequired";
NSString *const kPermitSpeciesAmountsAgeRequired = @"ageRequired";
NSString *const kPermitSpeciesAmountsWeightRequired = @"weightRequired";

static NSString *const DATE_FORMAT_NO_TIME = @"yyyy-MM-dd";

@interface PermitSpeciesAmounts ()

- (NSDate *)dateOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation PermitSpeciesAmounts
{
    NSDateFormatter *dateFormatter;
}

@synthesize gameSpeciesCode = _gameSpeciesCode;
@synthesize amount = _amount;
@synthesize beginDate = _beginDate;
@synthesize endDate = _endDate;
@synthesize beginDate2 = _beginDate2;
@synthesize endDate2 = _endDate2;
@synthesize genderRequired = _genderRequired;
@synthesize ageRequired = _ageRequired;
@synthesize weightRequired = _weightRequired;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];

    dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
    [dateFormatter setDateFormat:DATE_FORMAT_NO_TIME];

    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
            self.amount = [[RiistaUtils objectOrNilForKey:kPermitSpeciesAmountsAmount fromDictionary:dict] doubleValue];
            self.endDate = [self dateOrNilForKey:kPermitSpeciesAmountsEndDate fromDictionary:dict];
            self.beginDate2 = [self dateOrNilForKey:kPermitSpeciesAmountsBeginDate2 fromDictionary:dict];
            self.genderRequired = [[RiistaUtils objectOrNilForKey:kPermitSpeciesAmountsGenderRequired fromDictionary:dict] boolValue];
            self.beginDate = [self dateOrNilForKey:kPermitSpeciesAmountsBeginDate fromDictionary:dict];
            self.endDate2 = [self dateOrNilForKey:kPermitSpeciesAmountsEndDate2 fromDictionary:dict];
            self.gameSpeciesCode = [[RiistaUtils objectOrNilForKey:kPermitSpeciesAmountsGameSpeciesCode fromDictionary:dict] doubleValue];
            self.ageRequired = [[RiistaUtils objectOrNilForKey:kPermitSpeciesAmountsAgeRequired fromDictionary:dict] boolValue];
            self.weightRequired = [[RiistaUtils objectOrNilForKey:kPermitSpeciesAmountsWeightRequired fromDictionary:dict] boolValue];
    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[NSNumber numberWithDouble:self.amount] forKey:kPermitSpeciesAmountsAmount];
    [mutableDict setValue:[dateFormatter stringFromDate:self.endDate] forKey:kPermitSpeciesAmountsEndDate];
    [mutableDict setValue:[dateFormatter stringFromDate:self.beginDate2] forKey:kPermitSpeciesAmountsBeginDate2];
    [mutableDict setValue:[NSNumber numberWithBool:self.genderRequired] forKey:kPermitSpeciesAmountsGenderRequired];
    [mutableDict setValue:[dateFormatter stringFromDate:self.beginDate] forKey:kPermitSpeciesAmountsBeginDate];
    [mutableDict setValue:[dateFormatter stringFromDate:self.endDate2] forKey:kPermitSpeciesAmountsEndDate2];
    [mutableDict setValue:[NSNumber numberWithDouble:self.gameSpeciesCode] forKey:kPermitSpeciesAmountsGameSpeciesCode];
    [mutableDict setValue:[NSNumber numberWithBool:self.ageRequired] forKey:kPermitSpeciesAmountsAgeRequired];
    [mutableDict setValue:[NSNumber numberWithBool:self.weightRequired] forKey:kPermitSpeciesAmountsWeightRequired];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method

- (NSDate *)dateOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [RiistaUtils objectOrNilForKey:aKey fromDictionary:dict];
    return [dateFormatter dateFromString:object];
}

#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.amount = [aDecoder decodeDoubleForKey:kPermitSpeciesAmountsAmount];
    self.endDate = [aDecoder decodeObjectForKey:kPermitSpeciesAmountsEndDate];
    self.beginDate2 = [aDecoder decodeObjectForKey:kPermitSpeciesAmountsBeginDate2];
    self.genderRequired = [aDecoder decodeBoolForKey:kPermitSpeciesAmountsGenderRequired];
    self.beginDate = [aDecoder decodeObjectForKey:kPermitSpeciesAmountsBeginDate];
    self.endDate2 = [aDecoder decodeObjectForKey:kPermitSpeciesAmountsEndDate2];
    self.gameSpeciesCode = [aDecoder decodeDoubleForKey:kPermitSpeciesAmountsGameSpeciesCode];
    self.ageRequired = [aDecoder decodeBoolForKey:kPermitSpeciesAmountsAgeRequired];
    self.weightRequired = [aDecoder decodeBoolForKey:kPermitSpeciesAmountsWeightRequired];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeDouble:_amount forKey:kPermitSpeciesAmountsAmount];
    [aCoder encodeObject:_endDate forKey:kPermitSpeciesAmountsEndDate];
    [aCoder encodeObject:_beginDate2 forKey:kPermitSpeciesAmountsBeginDate2];
    [aCoder encodeBool:_genderRequired forKey:kPermitSpeciesAmountsGenderRequired];
    [aCoder encodeObject:_beginDate forKey:kPermitSpeciesAmountsBeginDate];
    [aCoder encodeObject:_endDate2 forKey:kPermitSpeciesAmountsEndDate2];
    [aCoder encodeDouble:_gameSpeciesCode forKey:kPermitSpeciesAmountsGameSpeciesCode];
    [aCoder encodeBool:_ageRequired forKey:kPermitSpeciesAmountsAgeRequired];
    [aCoder encodeBool:_weightRequired forKey:kPermitSpeciesAmountsWeightRequired];
}

- (id)copyWithZone:(NSZone *)zone
{
    PermitSpeciesAmounts *copy = [[PermitSpeciesAmounts alloc] init];
    
    if (copy) {

        copy.amount = self.amount;
        copy.endDate = [self.endDate copyWithZone:zone];
        copy.beginDate2 = [self.beginDate2 copyWithZone:zone];
        copy.genderRequired = self.genderRequired;
        copy.beginDate = [self.beginDate copyWithZone:zone];
        copy.endDate2 = [self.endDate2 copyWithZone:zone];
        copy.gameSpeciesCode = self.gameSpeciesCode;
        copy.ageRequired = self.ageRequired;
        copy.weightRequired = self.weightRequired;
    }
    
    return copy;
}


@end
