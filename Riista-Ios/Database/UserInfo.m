#import "UserInfo.h"
#import "Rhy.h"
#import "Address.h"
#import "Occupation.h"
#import "ShootingTest.h"
#import "NSDateformatter+Locale.h"
#import "RiistaUtils.h"

NSString *const kUserInfoRhy = @"rhy";
NSString *const kUserInfoLastName = @"lastName";
NSString *const kUserInfoFirstName = @"firstName";
NSString *const kUserInfoBirthDate = @"birthDate";
NSString *const kUserInfoHuntingCardValidNow = @"huntingCardValidNow";
NSString *const kUserInfoTimestamp = @"timestamp";
NSString *const kUserInfoHunterExamDate = @"hunterExamDate";
NSString *const kUserInfoHuntingCardEnd = @"huntingCardEnd";
NSString *const kUserInfoHuntingBanStart = @"huntingBanStart";
NSString *const kUserInfoHunterNumber = @"hunterNumber";
NSString *const kUserInfoAddress = @"address";
NSString *const kUserInfoHuntingCardStart = @"huntingCardStart";
NSString *const kUserInfoHuntingBanEnd = @"huntingBanEnd";
NSString *const kUserInfoUsername = @"username";
NSString *const kUserInfoGameDiaryYears = @"gameDiaryYears";
NSString *const kUserInfoOccupations = @"occupations";
NSString *const kUserInfoDeerPilotUser = @"deerPilotUser";
NSString *const kUserInfoHomeMunicipality = @"homeMunicipality";
NSString *const kUserInfoHarvestYears = @"harvestYears";
NSString *const kUserInfoObservationYears = @"observationYears";
NSString *const kUserInfoEnableSrva = @"enableSrva";
NSString *const kUserInfoEnableShootingTests = @"enableShootingTests";
NSString *const kUserInfoQrCode = @"qrCode";
NSString *const kUserInfoShootingTests = @"shootingTests";

// ISO 8601 date times
static NSString *const DATE_FORMAT_NO_TIME = @"yyyy-MM-dd";
static NSString *const DATE_FORMAT_FULL = @"yyyy-MM-dd'T'HH:mm:ss.SSS";

@interface UserInfo ()

- (NSDate *)dateOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation UserInfo
{
    NSDateFormatter *dateFormatter;
}

@synthesize rhy = _rhy;
@synthesize lastName = _lastName;
@synthesize firstName = _firstName;
@synthesize birthDate = _birthDate;
@synthesize huntingCardValidNow = _huntingCardValidNow;
@synthesize timestamp = _timestamp;
@synthesize hunterExamDate = _hunterExamDate;
@synthesize huntingCardEnd = _huntingCardEnd;
@synthesize huntingBanStart = _huntingBanStart;
@synthesize hunterNumber = _hunterNumber;
@synthesize address = _address;
@synthesize huntingCardStart = _huntingCardStart;
@synthesize huntingBanEnd = _huntingBanEnd;
@synthesize username = _username;
@synthesize gameDiaryYears = _gameDiaryYears;
@synthesize occupations = _occupations;
@synthesize deerPilotUser = _deerPilotUser;
@synthesize homeMunicipality = _homeMunicipality;
@synthesize harvestYears = _harvestYears;
@synthesize observationYears = _observationYears;
@synthesize enableSrva = _enableSrva;
@synthesize enableShootingTests = _enableShootingTests;
@synthesize qrCode = _qrCode;
@synthesize shootingTests = _shootingTests;

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
        NSObject *rhyDict = [dict objectForKey:kUserInfoRhy];
        if (rhyDict != nil && [rhyDict isKindOfClass:[NSDictionary class]]) {
            self.rhy = [Rhy modelObjectWithDictionary:(NSDictionary *)rhyDict];
        } else {
            self.rhy = nil;
        }
        self.lastName = [RiistaUtils objectOrNilForKey:kUserInfoLastName fromDictionary:dict];
        self.firstName = [RiistaUtils objectOrNilForKey:kUserInfoFirstName fromDictionary:dict];
        self.birthDate = [self dateOrNilForKey:kUserInfoBirthDate fromDictionary:dict];
        self.huntingCardValidNow = [[RiistaUtils objectOrNilForKey:kUserInfoHuntingCardValidNow fromDictionary:dict] boolValue];
        self.timestamp = [RiistaUtils objectOrNilForKey:kUserInfoTimestamp fromDictionary:dict];
        self.hunterExamDate = [self dateOrNilForKey:kUserInfoHunterExamDate fromDictionary:dict];
        self.huntingCardEnd = [self dateOrNilForKey:kUserInfoHuntingCardEnd fromDictionary:dict];
        self.huntingBanStart = [self dateOrNilForKey:kUserInfoHuntingBanStart fromDictionary:dict];
        self.hunterNumber = [RiistaUtils objectOrNilForKey:kUserInfoHunterNumber fromDictionary:dict];
        self.address = [Address modelObjectWithDictionary:[dict objectForKey:kUserInfoAddress]];
        self.huntingCardStart = [self dateOrNilForKey:kUserInfoHuntingCardStart fromDictionary:dict];
        self.huntingBanEnd = [self dateOrNilForKey:kUserInfoHuntingBanEnd fromDictionary:dict];
        self.username = [RiistaUtils objectOrNilForKey:kUserInfoUsername fromDictionary:dict];
        self.gameDiaryYears = [RiistaUtils objectOrNilForKey:kUserInfoGameDiaryYears fromDictionary:dict];
        self.homeMunicipality = [RiistaUtils objectOrNilForKey:kUserInfoHomeMunicipality fromDictionary:dict];
        self.harvestYears = [RiistaUtils objectOrNilForKey:kUserInfoHarvestYears fromDictionary:dict];
        self.observationYears = [RiistaUtils objectOrNilForKey:kUserInfoObservationYears fromDictionary:dict];
        self.enableSrva = [RiistaUtils objectOrNilForKey:kUserInfoEnableSrva fromDictionary:dict];
        self.enableShootingTests = [RiistaUtils objectOrNilForKey:kUserInfoEnableShootingTests fromDictionary:dict];
        self.qrCode = [RiistaUtils objectOrNilForKey:kUserInfoQrCode fromDictionary:dict];
        self.deerPilotUser = [[RiistaUtils objectOrNilForKey:kUserInfoDeerPilotUser fromDictionary:dict] boolValue];

        NSObject *receivedOccupations = [dict objectForKey:kUserInfoOccupations];
        NSMutableArray *parsedOccupations = [NSMutableArray array];
        if ([receivedOccupations isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in (NSArray *)receivedOccupations) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [parsedOccupations addObject:[Occupation modelObjectWithDictionary:item]];
                }
            }
        } else if ([receivedOccupations isKindOfClass:[NSDictionary class]]) {
            [parsedOccupations addObject:[Occupation modelObjectWithDictionary:(NSDictionary *)receivedOccupations]];
        }

        self.occupations = [NSArray arrayWithArray:parsedOccupations];

        NSObject *receivedShootingTests = [dict objectForKey:kUserInfoShootingTests];
        NSMutableArray *parsedShootingTests = [NSMutableArray array];
        if ([receivedShootingTests isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in (NSArray *)receivedShootingTests) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [parsedShootingTests addObject:[ShootingTest modelObjectWithDictionary:item]];
                }
            }
        }
        self.shootingTests = [NSArray arrayWithArray:parsedShootingTests];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[self.rhy dictionaryRepresentation] forKey:kUserInfoRhy];
    [mutableDict setValue:self.lastName forKey:kUserInfoLastName];
    [mutableDict setValue:self.firstName forKey:kUserInfoFirstName];
    [mutableDict setValue:self.birthDate forKey:kUserInfoBirthDate];
    [mutableDict setValue:[NSNumber numberWithBool:self.huntingCardValidNow] forKey:kUserInfoHuntingCardValidNow];
    [mutableDict setValue:self.timestamp forKey:kUserInfoTimestamp];
    [mutableDict setValue:self.hunterExamDate forKey:kUserInfoHunterExamDate];
    [mutableDict setValue:self.huntingCardEnd forKey:kUserInfoHuntingCardEnd];
    [mutableDict setValue:self.huntingBanStart forKey:kUserInfoHuntingBanStart];
    [mutableDict setValue:self.hunterNumber forKey:kUserInfoHunterNumber];
    [mutableDict setValue:[self.address dictionaryRepresentation] forKey:kUserInfoAddress];
    [mutableDict setValue:self.huntingCardStart forKey:kUserInfoHuntingCardStart];
    [mutableDict setValue:self.huntingBanEnd forKey:kUserInfoHuntingBanEnd];
    [mutableDict setValue:self.username forKey:kUserInfoUsername];
    [mutableDict setValue:self.homeMunicipality forKey:kUserInfoHomeMunicipality];
    [mutableDict setValue:self.enableSrva forKey:kUserInfoEnableSrva];
    [mutableDict setValue:self.enableShootingTests forKey:kUserInfoEnableShootingTests];
    [mutableDict setValue:self.qrCode forKey:kUserInfoQrCode];
    [mutableDict setValue:[NSNumber numberWithBool:self.deerPilotUser] forKey:kUserInfoDeerPilotUser];

    NSMutableArray *tempArrayForHarvestYears = [NSMutableArray array];
    for (NSObject *subArrayObject in self.harvestYears) {
        if ([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            [tempArrayForHarvestYears addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            [tempArrayForHarvestYears addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForHarvestYears] forKey:kUserInfoHarvestYears];

    NSMutableArray *tempArrayForObservationYears = [NSMutableArray array];
    for (NSObject *subArrayObject in self.observationYears) {
        if ([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            [tempArrayForObservationYears addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            [tempArrayForObservationYears addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForObservationYears] forKey:kUserInfoObservationYears];

    NSMutableArray *tempArrayForGameDiaryYears = [NSMutableArray array];
    for (NSObject *subArrayObject in self.gameDiaryYears) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForGameDiaryYears addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForGameDiaryYears addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForGameDiaryYears] forKey:kUserInfoGameDiaryYears];

    NSMutableArray *tempArrayForOccupations = [NSMutableArray array];
    for (NSObject *subArrayObject in self.occupations) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForOccupations addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForOccupations addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForOccupations] forKey:kUserInfoOccupations];

    NSMutableArray *tempArrayForShootingTests = [NSMutableArray array];
    for (NSObject *subArrayObject in self.shootingTests) {
        if ([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            [tempArrayForShootingTests addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        }
        else {
            [tempArrayForShootingTests addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForShootingTests] forKey:kUserInfoShootingTests];

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

    self.rhy = [aDecoder decodeObjectForKey:kUserInfoRhy];
    self.lastName = [aDecoder decodeObjectForKey:kUserInfoLastName];
    self.firstName = [aDecoder decodeObjectForKey:kUserInfoFirstName];
    self.birthDate = [aDecoder decodeObjectForKey:kUserInfoBirthDate];
    self.huntingCardValidNow = [aDecoder decodeBoolForKey:kUserInfoHuntingCardValidNow];
    self.timestamp = [aDecoder decodeObjectForKey:kUserInfoTimestamp];
    self.hunterExamDate = [aDecoder decodeObjectForKey:kUserInfoHunterExamDate];
    self.huntingCardEnd = [aDecoder decodeObjectForKey:kUserInfoHuntingCardEnd];
    self.huntingBanStart = [aDecoder decodeObjectForKey:kUserInfoHuntingBanStart];
    self.hunterNumber = [aDecoder decodeObjectForKey:kUserInfoHunterNumber];
    self.address = [aDecoder decodeObjectForKey:kUserInfoAddress];
    self.huntingCardStart = [aDecoder decodeObjectForKey:kUserInfoHuntingCardStart];
    self.huntingBanEnd = [aDecoder decodeObjectForKey:kUserInfoHuntingBanEnd];
    self.username = [aDecoder decodeObjectForKey:kUserInfoUsername];
    self.gameDiaryYears = [aDecoder decodeObjectForKey:kUserInfoGameDiaryYears];
    self.occupations = [aDecoder decodeObjectForKey:kUserInfoOccupations];
    self.deerPilotUser = [aDecoder decodeBoolForKey:kUserInfoDeerPilotUser];
    self.homeMunicipality = [aDecoder decodeObjectForKey:kUserInfoHomeMunicipality];
    self.harvestYears = [aDecoder decodeObjectForKey:kUserInfoHarvestYears];
    self.observationYears = [aDecoder decodeObjectForKey:kUserInfoObservationYears];
    self.enableSrva = [aDecoder decodeObjectForKey:kUserInfoEnableSrva];
    self.enableShootingTests = [aDecoder decodeObjectForKey:kUserInfoEnableShootingTests];
    self.qrCode = [aDecoder decodeObjectForKey:kUserInfoQrCode];
    self.shootingTests = [aDecoder decodeObjectForKey:kUserInfoShootingTests];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_rhy forKey:kUserInfoRhy];
    [aCoder encodeObject:_lastName forKey:kUserInfoLastName];
    [aCoder encodeObject:_firstName forKey:kUserInfoFirstName];
    [aCoder encodeObject:_birthDate forKey:kUserInfoBirthDate];
    [aCoder encodeBool:_huntingCardValidNow forKey:kUserInfoHuntingCardValidNow];
    [aCoder encodeObject:_timestamp forKey:kUserInfoTimestamp];
    [aCoder encodeObject:_hunterExamDate forKey:kUserInfoHunterExamDate];
    [aCoder encodeObject:_huntingCardEnd forKey:kUserInfoHuntingCardEnd];
    [aCoder encodeObject:_huntingBanStart forKey:kUserInfoHuntingBanStart];
    [aCoder encodeObject:_hunterNumber forKey:kUserInfoHunterNumber];
    [aCoder encodeObject:_address forKey:kUserInfoAddress];
    [aCoder encodeObject:_huntingCardStart forKey:kUserInfoHuntingCardStart];
    [aCoder encodeObject:_huntingBanEnd forKey:kUserInfoHuntingBanEnd];
    [aCoder encodeObject:_username forKey:kUserInfoUsername];
    [aCoder encodeObject:_gameDiaryYears forKey:kUserInfoGameDiaryYears];
    [aCoder encodeObject:_occupations forKey:kUserInfoOccupations];
    [aCoder encodeBool:_deerPilotUser forKey:kUserInfoDeerPilotUser];
    [aCoder encodeObject:_homeMunicipality forKey:kUserInfoHomeMunicipality];
    [aCoder encodeObject:_harvestYears forKey:kUserInfoHarvestYears];
    [aCoder encodeObject:_observationYears forKey:kUserInfoObservationYears];
    [aCoder encodeObject:_enableSrva forKey:kUserInfoEnableSrva];
    [aCoder encodeObject:_enableShootingTests forKey:kUserInfoEnableShootingTests];
    [aCoder encodeObject:_qrCode forKey:kUserInfoQrCode];
    [aCoder encodeObject:_shootingTests forKey:kUserInfoShootingTests];
}

- (id)copyWithZone:(NSZone *)zone
{
    UserInfo *copy = [[UserInfo alloc] init];

    if (copy) {
        copy.rhy = [self.rhy copyWithZone:zone];
        copy.lastName = [self.lastName copyWithZone:zone];
        copy.firstName = [self.firstName copyWithZone:zone];
        copy.birthDate = [self.birthDate copyWithZone:zone];
        copy.huntingCardValidNow = self.huntingCardValidNow;
        copy.timestamp = [self.timestamp copyWithZone:zone];
        copy.hunterExamDate = [self.hunterExamDate copyWithZone:zone];
        copy.huntingCardEnd = [self.huntingCardEnd copyWithZone:zone];
        copy.huntingBanStart = [self.huntingBanStart copyWithZone:zone];
        copy.hunterNumber = [self.hunterNumber copyWithZone:zone];
        copy.address = [self.address copyWithZone:zone];
        copy.huntingCardStart = [self.huntingCardStart copyWithZone:zone];
        copy.huntingBanEnd = [self.huntingBanEnd copyWithZone:zone];
        copy.username = [self.username copyWithZone:zone];
        copy.gameDiaryYears = [self.gameDiaryYears copyWithZone:zone];
        copy.occupations = [self.occupations copyWithZone:zone];
        copy.deerPilotUser = self.deerPilotUser;
        copy.homeMunicipality = [self.homeMunicipality copyWithZone:zone];
        copy.harvestYears = [self.harvestYears copyWithZone:zone];
        copy.observationYears = [self.observationYears copyWithZone:zone];
        copy.enableSrva = [self.enableSrva copyWithZone:zone];
        copy.enableShootingTests = [self.enableShootingTests copyWithZone:zone];
        copy.qrCode = [self.qrCode copyWithZone:zone];
        copy.shootingTests = [self.shootingTests copyWithZone:zone];
    }

    return copy;
}

- (BOOL)isCarnivoreAuthority
{
    for (Occupation *occupation in self.occupations) {
        if ([@"PETOYHDYSHENKILO" isEqualToString:occupation.occupationType]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isShootingTestOfficial
{
    return [self.enableShootingTests boolValue];
}

- (Occupation*)findOccupationOfType:(NSString*)occupationType forRhyId:(int)rhyId
{
    for (Occupation *occupation in self.occupations) {
        if ([occupation isOccupationOfType:occupationType forRhyId:rhyId]) {
            return occupation;
        }
    }

    return nil;
}

@end
