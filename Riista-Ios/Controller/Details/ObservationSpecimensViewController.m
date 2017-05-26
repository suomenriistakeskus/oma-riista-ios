#import "ObservationEntry.h"
#import "ObservationSpecimen.h"
#import "ObservationContextSensitiveFieldSets.h"
#import "ObservationSpecimensViewController.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaLocalization.h"
#import "RiistaNavigationController.h"
#import "RiistaSettings.h"
#import "RiistaSpecies.h"
#import "RiistaSpecimen.h"
#import "RiistaUtils.h"
#import "RiistaValueListButton.h"
#import "UIColor+ApplicationColor.h"
#import "ValueListViewController.h"

@protocol ObservationSpecimenCellDelegate

- (void)showValueSelect:(NSString *)key delegate:(id<ValueSelectionDelegate>)delegate;
- (void)removeSpecimen:(ObservationSpecimen*)specimen;

@end

@interface ObservationSpecimenCell : UITableViewCell <UITextFieldDelegate, ValueSelectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSelect;
@property (weak, nonatomic) IBOutlet RiistaValueListButton *ageSelect;
@property (weak, nonatomic) IBOutlet RiistaValueListButton *stateSelect;
@property (weak, nonatomic) IBOutlet RiistaValueListButton *markingSelect;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *genderHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stateHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *markingHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonWidthConstraint;

@property (weak, nonatomic) id<ObservationSpecimenCellDelegate> delegate;
@property (weak, nonatomic) ObservationSpecimen *specimen;
@property (assign, nonatomic) NSInteger speciesId;

- (void)updateLocalizedTexts;
- (void)updateValueSelections;
- (void)updateItemTitle:(NSString*)titleText;
- (void)updateVisibleFields:(ObservationContextSensitiveFieldSets*)metadata;

@end

static NSString * const AGE_FIELD_KEY = @"AgeFieldKey";
static NSString * const STATE_FIELD_KEY = @"StateFieldKey";
static NSString * const MARKING_FIELD_KEY = @"MarkingFieldKey";

@interface ObservationSpecimensViewController () <ObservationSpecimenCellDelegate, KeyboardHandlerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;
@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;
@property (strong, nonatomic) UIBarButtonItem *addButton;

@property (strong, nonatomic) ObservationEntry *entry;

@end

@implementation ObservationSpecimensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;

    [self configureTableView];
    [self configureButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RiistaLanguageRefresh;

    [self updateTitle];
    [self configureButtons];
}

- (void)configureTableView
{
    self.tableView.estimatedRowHeight = 200.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)configureButtons
{
    UIImage *addImage = [UIImage imageNamed:@"ic_menu_add.png"];
    self.addButton = [[UIBarButtonItem alloc] initWithImage:addImage
                                    landscapeImagePhone:addImage
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(addSpecimen:)];
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController setRightBarItems:@[self.addButton]];

    [self.addButton setEnabled:self.editMode];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle: [NSString stringWithFormat:@"%@ (%@)",
                                 [RiistaUtils nameWithPreferredLanguage:self.species.name],
                                 self.entry.totalSpecimenAmount]];
}

- (void)addSpecimen:(id)sender
{
    if ([self.entry.specimens count] < DiaryEntrySpecimenDetailsMax) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ObservationSpecimen" inManagedObjectContext:self.editContext];
        ObservationSpecimen *newSpecimen = (ObservationSpecimen*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.editContext];

        [self.entry addSpecimensObject:newSpecimen];
        self.entry.totalSpecimenAmount = [NSNumber numberWithInteger:[self.entry.specimens count]];

        [self.tableView reloadData];
        [self goToTableBottom];
        [self updateTitle];
    }
}

- (void)goToTableBottom
{
    NSIndexPath *lastIndexPath = [self lastIndexPath];
    [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (NSIndexPath*)lastIndexPath
{
    NSInteger lastSectionIndex = MAX(0, [self.tableView numberOfSections] - 1);
    NSInteger lastRowIndex = MAX(0, [self.tableView numberOfRowsInSection:lastSectionIndex] - 1);

    return [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
}

- (void)configureCell:(ObservationSpecimenCell*)cell item:(ObservationSpecimen*)specimen index:(NSInteger)rowIndex
{
    cell.delegate = self;

    [cell updateLocalizedTexts];
    [cell setSpecimen:specimen];
    [cell setSpeciesId:self.species.speciesId];
    [cell updateValueSelections];

    NSString *titleText = [NSString stringWithFormat:@"%@ %ld", [RiistaUtils nameWithPreferredLanguage:self.species.name], (long)rowIndex + 1];
    [cell updateItemTitle:titleText];
    [cell updateVisibleFields:self.metadata];

    // Hide remove button when not editing
    cell.buttonWidthConstraint.constant = self.editMode ? 40.f : 0.f;
    [cell.removeButton setBackgroundImage:[RiistaUtils imageWithColor:[UIColor applicationColor:RiistaApplicationColorWhiteButtonHilight] width:1 height:1]
                                 forState:UIControlStateHighlighted];
    [cell.removeButton setEnabled:self.editMode];

    [cell.genderSelect setEnabled:self.editMode];
    [cell.ageSelect setEnabled:self.editMode];
    [cell.stateSelect setEnabled:self.editMode];
    [cell.markingSelect setEnabled:self.editMode];
}


- (void)setContent:(ObservationEntry *)entry
{
    self.entry = entry;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.entry.specimens count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    ObservationSpecimenCell *cell = (ObservationSpecimenCell*)[tableView dequeueReusableCellWithIdentifier:@"observationSpecimenCell"];
    ObservationSpecimen *specimen = self.entry.specimens[indexPath.row];

    [self configureCell:cell item:specimen index:indexPath.row];

    return cell;
}

#pragma mark - SpecimenCellDelegate

- (void)showValueSelect:(NSString *)key delegate:(id<ValueSelectionDelegate>)delegate;
{
    ValueListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"valueListController"];
    controller.delegate = delegate;
    controller.fieldKey = key;

    if ([key isEqualToString:AGE_FIELD_KEY]) {
        controller.titlePrompt = RiistaLocalizedString(@"SpecimenAgeTitle", nil);
        controller.values = self.metadata.allowedAges;

        if (self.species.speciesId == BearId) {
            // Bear age text override
            [controller setTextKeyOverride:SpecimenAge1To2Years overrideKey:SpecimenAgeEraus];
        }
    }
    else if ([key isEqualToString:STATE_FIELD_KEY]) {
        controller.titlePrompt = RiistaLocalizedString(@"ObservationDetailsState", nil);
        controller.values = self.metadata.allowedStates;
    }
    else if ([key isEqualToString:MARKING_FIELD_KEY]) {
        controller.titlePrompt = RiistaLocalizedString(@"ObservationDetailsMarked", nil);
        controller.values = self.metadata.allowedMarkings;
    }

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)removeSpecimen:(ObservationSpecimen*)specimen
{
    // Do not allow removing last specimen to avoid setting amount zero. Clear values instead.
    if ([self.entry.specimens count] == 1) {
        specimen.age = nil;
        specimen.gender = nil;
        specimen.marking = nil;
        specimen.remoteId = nil;
        specimen.rev = nil;
        specimen.state = nil;
    }
    else if ([self.entry.specimens count] > 1) {
        [self.entry removeSpecimensObject:specimen];
        [self.editContext deleteObject:specimen];

        self.entry.totalSpecimenAmount = [NSNumber numberWithInteger:[self.entry.specimens count]];

        [self.tableView reloadData];
        [self updateTitle];
    }
}

# pragma mark - KeyboardHandlerDelegate

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

@end

@implementation ObservationSpecimenCell

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.genderSelect addTarget:self action:@selector(genderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [self.ageSelect addTarget:self action:@selector(onAgeClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.stateSelect addTarget:self action:@selector(onStateClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.markingSelect addTarget:self action:@selector(onMarkingClick:) forControlEvents:UIControlEventTouchUpInside];

    [self.removeButton addTarget:self action:@selector(removeSpecimenItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.removeButton.layer setCornerRadius:5.0];
    [self.removeButton setClipsToBounds:YES];
}

- (void)updateLocalizedTexts
{
    self.ageSelect.titleText = RiistaLocalizedString(@"SpecimenAgeTitle", nil);
    self.stateSelect.titleText = RiistaLocalizedString(@"ObservationDetailsState", nil);
    self.markingSelect.titleText = RiistaLocalizedString(@"ObservationDetailsMarked", nil);
}

- (void)updateItemTitle:(NSString*)titleText
{
    [_itemTitle setText:titleText];
}

- (void)updateValueSelections
{
    // Selected gender
    if ([_specimen.gender isEqualToString:SpecimenGenderFemale]) {
        [_genderSelect setSelectedSegmentIndex:0];
    }
    else if ([_specimen.gender isEqualToString:SpecimenGenderMale]) {
        [_genderSelect setSelectedSegmentIndex:1];
    }
    else if ([_specimen.gender isEqualToString:SpecimenGenderUnknown]) {
        [self.genderSelect setSelectedSegmentIndex:2];
    }
    else {
        [_genderSelect setSelectedSegmentIndex:-1];
    }

    if (self.speciesId == BearId && [SpecimenAge1To2Years isEqualToString:self.specimen.age]) {
        // Bear age text override
        self.ageSelect.valueText = RiistaMappedValueString(SpecimenAgeEraus, nil);
    }
    else {
        self.ageSelect.valueText = RiistaMappedValueString(self.specimen.age, nil);
    }
    self.stateSelect.valueText = RiistaMappedValueString(self.specimen.state, nil);
    self.markingSelect.valueText = RiistaMappedValueString(self.specimen.marking, nil);
}

-(void)updateVisibleFields:(ObservationContextSensitiveFieldSets *)metadata
{
    if ([metadata hasFieldSet:metadata.specimenFields name:@"gender"]) {
        self.genderHeightConstraint.constant = 43;
        self.genderSelect.hidden = NO;
    }
    else {
        self.genderHeightConstraint.constant = 0;
        self.genderSelect.hidden = YES;
    }

    if ([metadata hasFieldSet:metadata.specimenFields name:@"age"]) {
        self.ageHeightConstraint.constant = 63;
        self.ageSelect.hidden = NO;
    }
    else {
        self.ageHeightConstraint.constant = 0;
        self.ageSelect.hidden = YES;
    }

    if ([metadata hasFieldSet:metadata.specimenFields name:@"state"]) {
        self.stateHeightConstraint.constant = 63;
        self.stateSelect.hidden = NO;
    }
    else {
        self.stateHeightConstraint.constant = 0;
        self.stateSelect.hidden = YES;
    }

    if ([metadata hasFieldSet:metadata.specimenFields name:@"marking"]) {
        self.markingHeightConstraint.constant = 63;
        self.markingSelect.hidden = NO;
    }
    else {
        self.markingHeightConstraint.constant = 0;
        self.markingSelect.hidden = YES;
    }

    [self layoutIfNeeded];
}

- (void)genderValueChanged:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == 0) {
        _specimen.gender = SpecimenGenderFemale;
    }
    else if (sender.selectedSegmentIndex == 1) {
        _specimen.gender = SpecimenGenderMale;
    }
    else if (sender.selectedSegmentIndex == 2) {
        _specimen.gender = SpecimenGenderUnknown;
    }
    else {
        _specimen.gender = nil;
    }
}

- (void)onAgeClick:(id)sender
{
    [self.delegate showValueSelect:AGE_FIELD_KEY delegate:self];
}

- (void)onStateClick:(id)sender
{
    [self.delegate showValueSelect:STATE_FIELD_KEY delegate:self];
}

- (void)onMarkingClick:(id)sender
{
    [self.delegate showValueSelect:MARKING_FIELD_KEY delegate:self];
}

- (void)valueSelectedForKey:(NSString *)key value:(NSString *)value
{
    if ([key isEqualToString:AGE_FIELD_KEY]) {
        self.specimen.age = value;
    }
    else if ([key isEqualToString:STATE_FIELD_KEY]) {
        self.specimen.state = value;
    }
    else if ([key isEqualToString:MARKING_FIELD_KEY]) {
        self.specimen.marking = value;
    }

    [self updateValueSelections];
}

- (void)removeSpecimenItem:(UIButton*)sender
{
    [_delegate removeSpecimen:_specimen];
}

@end
