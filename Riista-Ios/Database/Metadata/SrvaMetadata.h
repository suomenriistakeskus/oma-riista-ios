#import <Foundation/Foundation.h>
#import "RiistaSpecies.h"

@class SrvaEventMetadata;

@interface SrvaMetadata : NSObject

@property (nonatomic, strong) NSArray<NSString*> *ages;
@property (nonatomic, strong) NSArray<NSString*> *genders;
@property (nonatomic, strong) NSArray<RiistaSpecies*> *species;
@property (nonatomic, strong) NSArray<SrvaEventMetadata*> *events;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
