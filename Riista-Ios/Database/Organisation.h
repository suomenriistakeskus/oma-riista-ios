#import <Foundation/Foundation.h>

@interface Organisation : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSNumber *organisationIdentifier;
@property (nonatomic, strong) NSDictionary *name;
@property (nonatomic, strong) NSString *officialCode;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
