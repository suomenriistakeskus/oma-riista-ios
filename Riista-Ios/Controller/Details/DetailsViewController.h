#include "RiistaUIViewController.h"

@class ObservationEntry, RiistaSpecies;

@interface DetailsViewController : RiistaUIViewController

@property (assign, nonatomic) NSManagedObjectID *observationId;
@property (assign, nonatomic) NSManagedObjectID *srvaId;
@property (strong, nonatomic) RiistaSpecies *species;

@property (assign, nonatomic) NSNumber *srvaNew;
@property (assign, nonatomic) NSString *srvaEventName;
@property (assign, nonatomic) NSString *srvaEventType;

@end
