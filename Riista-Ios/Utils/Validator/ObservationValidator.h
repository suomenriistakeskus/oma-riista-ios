#import "MetadataManager.h"

@class ObservationEntry;
@class ObservationSpecimenMetadata;
@class GeoCoordinate;

@interface ObservationValidator : NSObject

+ (BOOL)validate:(ObservationEntry*)entry metadataManager:(id<MetadataManager>)metadataManager;

+ (BOOL)validateSpeciesId:(NSInteger)value;
+ (BOOL)validateEntryType:(NSString*)value;
+ (BOOL)validatePosition:(GeoCoordinate*)value;
+ (BOOL)validateTimestamp:(NSDate*)value;

+ (BOOL)validateObservationType:(NSString*)value;

@end
