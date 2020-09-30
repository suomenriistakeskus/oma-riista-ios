#import <Foundation/Foundation.h>

@class Rhy, Address, Occupation;

@interface UserInfo : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) Rhy *rhy;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSDate *birthDate;
@property (nonatomic, assign) BOOL huntingCardValidNow;
@property (nonatomic, strong) NSString *timestamp;
@property (nonatomic, strong) NSDate *hunterExamDate;
@property (nonatomic, strong) NSDate *huntingCardEnd;
@property (nonatomic, strong) NSDate *huntingBanStart;
@property (nonatomic, strong) NSString *hunterNumber;
@property (nonatomic, strong) Address *address;
@property (nonatomic, strong) NSDate *huntingCardStart;
@property (nonatomic, strong) NSDate *huntingBanEnd;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSArray *gameDiaryYears;
@property (nonatomic, strong) NSArray *occupations;
@property (nonatomic, assign) BOOL deerPilotUser;
@property (nonatomic, strong) NSDictionary *homeMunicipality;
@property (nonatomic, strong) NSArray *harvestYears;
@property (nonatomic, strong) NSArray *observationYears;
@property (nonatomic, strong) NSNumber *enableSrva;
@property (nonatomic, strong) NSNumber *enableShootingTests;
@property (nonatomic, strong) NSString *qrCode;
@property (nonatomic, strong) NSArray *shootingTests;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (BOOL)isCarnivoreAuthority;
- (BOOL)isShootingTestOfficial;
- (Occupation*)findOccupationOfType:(NSString*)occupationType forRhyId:(int)rhyId;

@end
