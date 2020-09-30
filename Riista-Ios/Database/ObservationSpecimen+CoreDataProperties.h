#import "ObservationSpecimen.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationSpecimen (CoreDataProperties)

+ (NSFetchRequest<ObservationSpecimen *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *age;
@property (nullable, nonatomic, copy) NSString *gender;
@property (nullable, nonatomic, copy) NSDecimalNumber *lengthOfPaw;
@property (nullable, nonatomic, copy) NSString *marking;
@property (nullable, nonatomic, copy) NSNumber *remoteId;
@property (nullable, nonatomic, copy) NSNumber *rev;
@property (nullable, nonatomic, copy) NSString *state;
@property (nullable, nonatomic, copy) NSDecimalNumber *widthOfPaw;
@property (nullable, nonatomic, retain) ObservationEntry *observationEntry;

@end

NS_ASSUME_NONNULL_END
