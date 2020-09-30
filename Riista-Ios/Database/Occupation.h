#import <Foundation/Foundation.h>

@class Organisation;

@interface Occupation : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSNumber *occupationId;
@property (nonatomic, strong) Organisation *organisation;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSString *occupationType;
@property (nonatomic, strong) NSDictionary *name;
@property (nonatomic, strong) NSDate *beginDate;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (BOOL)isOccupationOfType:(NSString*)occupationType forRhyId:(int)rhyId;

@end
