#import "GeoCoordinate.h"
#import "RiistaModelUtils.h"
#import "RiistaAppDelegate.h"
#import "RiistaSettings.h"
#import "UserInfo.h"
#import "ObservationContextSensitiveFieldSets.h"

@implementation RiistaModelUtils

+ (id)nullify:(id)object
{
    if (object == nil) {
        return [NSNull null];
    }
    return object;
}

+ (id)checkNull:(NSDictionary*)dict key:(NSString*)key
{
    if (dict != nil && ![dict isEqual:[NSNull null]]) {
        return ![dict[key] isEqual:[NSNull null]] ? dict[key] : nil;
    }
    return nil;
}

+ (NSString*)jsonFromObject:(NSObject*)obj
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
    if (!jsonData) {
        NSLog(@"JSON error: %@", [error localizedDescription]);
        return nil;
    }
    else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (GeoCoordinate*)coordinatesFromDict:(NSDictionary*)dict context:(NSManagedObjectContext*)context
{
    NSEntityDescription *coordinatesEntity = [NSEntityDescription entityForName:@"GeoCoordinate" inManagedObjectContext:context];
    GeoCoordinate *coordinates = (GeoCoordinate*)[[NSManagedObject alloc] initWithEntity:coordinatesEntity insertIntoManagedObjectContext:context];
    coordinates.latitude = dict[@"geoLocation"][@"latitude"];
    coordinates.longitude = dict[@"geoLocation"][@"longitude"];
    coordinates.source = dict[@"geoLocation"][@"source"];
    if ([dict[@"geoLocation"] objectForKey:@"accuracy"] && ![dict[@"geoLocation"][@"accuracy"] isEqual:[NSNull null]]) {
        coordinates.accuracy = dict[@"geoLocation"][@"accuracy"];
    }
    else {
        coordinates.accuracy = @(0);
    }

    return coordinates;
}

+ (void)saveContexts:(NSManagedObjectContext*)context
{
    NSError *error = nil;
    if ([context save:&error]) {
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate.managedObjectContext performBlock:^(void) {
            NSError *mErr;
            if ([delegate.managedObjectContext save:&mErr] == NO) {
                NSLog(@"Delegate context save error: %@", [mErr localizedDescription]);
            }
        }];
    }
    else {
        NSLog(@"Context save error: %@", [error localizedDescription]);
    }
}

+ (BOOL) isFieldCarnivoreAuthorityVoluntaryForUser:(ObservationContextSensitiveFieldSets*)fieldSet fieldName:(NSString*)fieldName
{
    return [[RiistaSettings userInfo] isCarnivoreAuthority] && [fieldSet hasFieldCarnivoreAuthorityVoluntary:fieldSet.baseFields name:fieldName];
}

@end
