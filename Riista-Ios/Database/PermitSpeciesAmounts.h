#import <Foundation/Foundation.h>


@interface PermitSpeciesAmounts : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) int gameSpeciesCode;
@property (nonatomic, assign) double amount;
@property (nonatomic, strong) NSDate *beginDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSDate *beginDate2;
@property (nonatomic, strong) NSDate *endDate2;
@property (nonatomic, assign) BOOL genderRequired;
@property (nonatomic, assign) BOOL ageRequired;
@property (nonatomic, assign) BOOL weightRequired;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
