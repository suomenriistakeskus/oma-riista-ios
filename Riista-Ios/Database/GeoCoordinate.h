#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiaryEntry;

extern NSString *const DiaryEntryLocationGps;
extern NSString *const DiaryEntryLocationManual;

@interface GeoCoordinate : NSManagedObject

@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *accuracy;
@property (nonatomic, retain) NSNumber *altitude;
@property (nonatomic, retain) NSNumber *altitudeAccuracy;
@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) DiaryEntry *diaryEntry;

@end
