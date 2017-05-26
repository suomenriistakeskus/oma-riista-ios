//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ObservationSpecimen.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationSpecimen (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *age;
@property (nullable, nonatomic, retain) NSString *gender;
@property (nullable, nonatomic, retain) NSString *marking;
@property (nullable, nonatomic, retain) NSNumber *remoteId;
@property (nullable, nonatomic, retain) NSNumber *rev;
@property (nullable, nonatomic, retain) NSString *state;
@property (nullable, nonatomic, retain) ObservationEntry *observationEntry;

@end

NS_ASSUME_NONNULL_END
