//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SrvaSpecimen.h"

NS_ASSUME_NONNULL_BEGIN

@interface SrvaSpecimen (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *gender;
@property (nullable, nonatomic, retain) NSString *age;
@property (nullable, nonatomic, retain) NSManagedObject *srvaEntry;

@end

NS_ASSUME_NONNULL_END
