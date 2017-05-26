#import <UIKit/UIKit.h>

@class RiistaSpecies, RiistaSpecimen;

@protocol SpecimensUpdatedDelegate

- (void)didAddSpecimen:(RiistaSpecimen*)specimen;
- (void)didRemoveSpecimen:(RiistaSpecimen*)specimen;

@end

@interface RiistaSpecimenListViewController : UITableViewController

@property (weak, nonatomic) id<SpecimensUpdatedDelegate> delegate;
@property (strong, nonatomic) NSManagedObjectContext *editContext;

@property (assign, nonatomic) BOOL editMode;
@property (assign, nonatomic) RiistaSpecies *species;

- (void)setContent:(NSMutableOrderedSet*)specimens;
- (void)setRequiredFields:(BOOL)genderRequired ageREquired:(BOOL)ageRequired weightRequired:(BOOL)weightRequired;

@end
