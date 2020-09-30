#ifndef ShootingTest_h
#define ShootingTest_h

#import <Foundation/Foundation.h>

@interface ShootingTest : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *rhyName;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *officialCode;
@property (nonatomic, strong) NSString *begin;
@property (nonatomic, strong) NSString *end;
@property (nonatomic, assign) BOOL expired;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end

#endif /* ShootingTest_h */
