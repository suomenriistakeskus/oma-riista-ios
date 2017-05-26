#import <Foundation/Foundation.h>


@interface Permit : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) NSInteger permitIdentifier;
@property (nonatomic, assign) NSInteger rev;
@property (nonatomic, strong) NSString *permitNumber;
@property (nonatomic, strong) NSString *permitType;
@property (nonatomic, strong) NSArray *speciesAmounts;
@property (nonatomic, assign) BOOL unavailable;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
