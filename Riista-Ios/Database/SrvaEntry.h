#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "DiaryEntryBase.h"

@class DiaryImage, GeoCoordinate, SrvaSpecimen, SrvaMethod;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SrvaStateUnfinished;
extern NSString *const SrvaStateApproved;
extern NSString *const SrvaStateRejected;

@interface SrvaEntry : DiaryEntryBase

- (NSInteger)yearMonth;
- (NSMutableArray<SrvaMethod*>*)parseMethods;
- (void)putMethods:(NSArray<SrvaMethod*>*)methods;

@end

NS_ASSUME_NONNULL_END

#import "SrvaEntry+CoreDataProperties.h"
