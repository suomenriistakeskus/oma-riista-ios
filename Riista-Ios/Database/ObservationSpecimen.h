#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ObservationEntry;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SpecimenAge1To2Years;
extern NSString *const SpecimenAgeEraus;

@interface ObservationSpecimen : NSManagedObject

- (BOOL)isEqualToObservationSpecimen:(ObservationSpecimen*)otherSpecimen;
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END

#import "ObservationSpecimen+CoreDataProperties.h"
