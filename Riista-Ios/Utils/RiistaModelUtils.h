#import <Foundation/Foundation.h>

@class GeoCoordinate, ObservationContextSensitiveFieldSets;

@interface RiistaModelUtils : NSObject

+ (id)nullify:(id)object;

+ (id)checkNull:(NSDictionary*)dict key:(NSString*)key;

+ (NSString*)jsonFromObject:(NSObject*)obj;

+ (GeoCoordinate*)coordinatesFromDict:(NSDictionary*)dict context:(NSManagedObjectContext*)context;

+ (void)saveContexts:(NSManagedObjectContext*)context;

+ (BOOL) isFieldCarnivoreAuthorityVoluntaryForUser:(ObservationContextSensitiveFieldSets*)fieldSet fieldName:(NSString*)fieldName;

@end
