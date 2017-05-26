#import <Foundation/Foundation.h>

@class SrvaEntry;

@interface SrvaValidator : NSObject

+ (BOOL)validate:(SrvaEntry*)entry;

@end
