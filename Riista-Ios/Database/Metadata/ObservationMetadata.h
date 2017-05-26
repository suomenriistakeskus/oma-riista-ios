#import <Foundation/Foundation.h>

@interface ObservationMetadata : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) NSInteger observationSpecVersion;
@property (nonatomic, strong) NSString *lastModified;
@property (nonatomic, strong) NSArray *speciesList;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
