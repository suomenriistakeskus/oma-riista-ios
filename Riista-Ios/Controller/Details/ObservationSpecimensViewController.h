#import <UIKit/UIKit.h>

@class RiistaSpecies;
@class ObservationSpecimenMetadata;
@class ObservationContextSensitiveFieldSets;

@interface ObservationSpecimensViewController : UITableViewController

@property (strong, nonatomic) NSManagedObjectContext *editContext;
@property (assign, nonatomic) BOOL editMode;

@property (assign, nonatomic) RiistaSpecies *species;
@property (assign, nonatomic) ObservationSpecimenMetadata *specimenMeta;
@property (assign, nonatomic) ObservationContextSensitiveFieldSets *metadata;

- (void)setContent:(ObservationEntry*)entry;

@end
