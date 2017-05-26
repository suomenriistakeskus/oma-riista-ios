#import <Foundation/Foundation.h>


@interface Address : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *city;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, assign) double addressIdentifier;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, assign) double rev;
@property (nonatomic, strong) NSString *postalCode;
@property (nonatomic, strong) NSString *streetAddress;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
