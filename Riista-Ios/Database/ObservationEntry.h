#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "DiaryEntryBase.h"

@class DiaryImage, GeoCoordinate, ObservationSpecimen;

NS_ASSUME_NONNULL_BEGIN

@interface ObservationEntry : DiaryEntryBase

- (NSInteger)yearMonth;

- (NSInteger)getMooselikeSpecimenCount;

@end

NS_ASSUME_NONNULL_END

#import "ObservationEntry+CoreDataProperties.h"
