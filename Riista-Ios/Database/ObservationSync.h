#import <Foundation/Foundation.h>

@class ObservationEntry;

typedef void(^ObservationSynchronizationCompletion)(void);

@interface ObservationSync : NSObject

- (void)sync:(ObservationSynchronizationCompletion)completion;

- (ObservationEntry*)observationEntryFromDict:(NSDictionary*)dict objectContext:(NSManagedObjectContext*)objectContext;
- (NSDictionary*)dictFromObservationEntry:(ObservationEntry*)observationEntry isNew:(BOOL)isNew;

@end
