#import <Foundation/Foundation.h>

@interface SrvaMethod : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *isChecked;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary*)toDict;

@end
