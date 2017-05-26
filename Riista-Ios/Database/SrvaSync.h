#import <Foundation/Foundation.h>

@class SrvaEntry;

typedef void(^SrvaSynchronizationCompletion)();

@interface SrvaSync : NSObject

- (void)sync:(SrvaSynchronizationCompletion)completion;

- (SrvaEntry*)srvaEntryFromDict:(NSDictionary*)dict objectContext:(NSManagedObjectContext*)objectContext;
- (NSDictionary*)dictFromSrvaEntry:(SrvaEntry*)srvaEntry isNew:(BOOL)isNew;

@end
