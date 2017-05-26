#import <Foundation/Foundation.h>

@interface Rhy : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) double rhyIdentifier;
@property (nonatomic, strong) NSDictionary *name;
@property (nonatomic, strong) NSString *officialCode;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
