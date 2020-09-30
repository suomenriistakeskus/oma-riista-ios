#import "DetailsViewControllerBase.h"

@class RiistaSpecies;
@class DetailsViewController;
@class ObservationDetailsViewController;

typedef NS_ENUM(NSInteger, ObservationCategory);
typedef NS_ENUM(NSInteger, DeerHuntingType);

@protocol ObservationDetailsDelegate
@required

- (void)showDateTimePicker;
- (void)navigateToSpecimens;
- (void)valuesUpdated:(DetailsViewControllerBase*)sender;

@end


@interface ObservationDetailsViewController : DetailsViewControllerBase

@property (strong, nonatomic) NSNumber *selectedSpeciesCode;
@property (strong, nonatomic) NSString *selectedObservationType;
@property (nonatomic, assign) ObservationCategory selectedObservationCategory;
@property (nonatomic, assign) DeerHuntingType selectedDeerHuntingType;
@property (strong, nonatomic) NSString *selectedDeerHuntingTypeDescription;
@property (strong, nonatomic) NSNumber *selectedMooselikeMaleAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemaleAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale1CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale2CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale3CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeFemale4CalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeCalfAmount;
@property (strong, nonatomic) NSNumber *selectedMooselikeUnknownAmount;

@property (strong, nonatomic) NSString *selectedObserverName;
@property (strong, nonatomic) NSString *selectedObserverPhoneNumber;
@property (strong, nonatomic) NSString *selectedOfficialAdditionalInfo;
@property (strong, nonatomic) NSNumber *selectedVerifiedByCarnivoreAuthority;
@property (strong, nonatomic) NSNumber *selectedInYardsDistanceFromResidence;;
@property (strong, nonatomic) NSNumber *selectedPack;
@property (strong, nonatomic) NSNumber *selectedLitter;

@property (strong, nonatomic) DiaryImage *diaryImage;

@property (strong, nonatomic) ObservationEntry *entry;

@property (weak, nonatomic) id <ObservationDetailsDelegate> delegate;
@property (strong, nonatomic) NSManagedObjectContext *editContext;

- (CGFloat)refreshViews;
- (void)saveValuesTo:(ObservationEntry*)entry cleanSpecimens:(BOOL)cleanSpecimens;

@end
