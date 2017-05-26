#import <Foundation/Foundation.h>

@class SrvaMethod;

@interface SrvaEventMetadata : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<NSString*> *types;
@property (nonatomic, strong) NSArray<NSString*> *results;
@property (nonatomic, strong) NSArray<SrvaMethod*> *methods;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
