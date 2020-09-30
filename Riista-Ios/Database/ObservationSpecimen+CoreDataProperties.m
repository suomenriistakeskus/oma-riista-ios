#import "ObservationSpecimen+CoreDataProperties.h"

@implementation ObservationSpecimen (CoreDataProperties)

+ (NSFetchRequest<ObservationSpecimen *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"ObservationSpecimen"];
}

@dynamic age;
@dynamic gender;
@dynamic lengthOfPaw;
@dynamic marking;
@dynamic remoteId;
@dynamic rev;
@dynamic state;
@dynamic widthOfPaw;
@dynamic observationEntry;

@end
