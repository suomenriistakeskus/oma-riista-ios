#import "GeoCoordinate.h"

NSString *const DiaryEntryLocationGps = @"GPS_DEVICE";
NSString *const DiaryEntryLocationManual = @"MANUAL";

@implementation GeoCoordinate

@dynamic longitude;
@dynamic latitude;
@dynamic accuracy;
@dynamic altitude;
@dynamic altitudeAccuracy;
@dynamic source;
@dynamic diaryEntry;

@end
