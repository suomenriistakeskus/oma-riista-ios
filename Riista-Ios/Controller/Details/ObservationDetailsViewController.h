#import "DetailsViewControllerBase.h"

@class RiistaSpecies;
@class DetailsViewController;
@class ObservationDetailsViewController;

@protocol ObservationDetailsDelegate
@required

- (void)navigateToSpecimens;
- (void)valuesUpdated:(DetailsViewControllerBase*)sender;

@end


@interface ObservationDetailsViewController : DetailsViewControllerBase

@property (strong, nonatomic) NSNumber *selectedSpeciesCode;
@property (strong, nonatomic) NSString *selectedObservationType;

// Nullable bool
@property (strong, nonatomic) NSNumber *selectedWithinMooseHunting;

@property (strong, nonatomic) NSNumber *selectedMooselikeMaleAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemaleAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale1CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale2CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale3CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale4CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeUnknownAmount;

@property (strong, nonatomic) ObservationEntry *entry;

@property (weak, nonatomic) id <ObservationDetailsDelegate> delegate;
@property (strong, nonatomic) NSManagedObjectContext *editContext;

- (CGFloat)refreshViews;
- (void)saveValuesTo:(ObservationEntry*)entry cleanSpecimens:(BOOL)cleanSpecimens;

@end
