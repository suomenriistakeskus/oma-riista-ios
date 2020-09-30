#import "ObservationEntry.h"
#import "ObservationSpecimen.h"
#import "ObservationDetailsViewController.h"
#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"
#import "RiistaGameDatabase.h"
#import "RiistaLocalization.h"
#import "RiistaMetadataManager.h"
#import "RiistaSpecies.h"
#import "RiistaSpeciesCategory.h"
#import "RiistaSpeciesSelectViewController.h"
#import "RiistaUtils.h"
#import "RiistaValueListButton.h"
#import "RiistaValueListTextField.h"
#import "RiistaValueListReadonlyText.h"
#import "RiistaViewUtils.h"
#import "RiistaSettings.h"
#import "RiistaModelUtils.h"
#import "RiistaKeyboardHandler.h"
#import "UserInfo.h"
#import "UIColor+ApplicationColor.h"
#import "ValueListViewController.h"
#import "M13Checkbox.h"
#import "KeyboardToolbarView.h"
#import "UIImage+Resize.h"

#import "Oma_riista-Swift.h"

@interface ObservationDetailsViewController () <SpeciesSelectionDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, ValueSelectionDelegate>

@property (weak, nonatomic) IBOutlet MDCButton *speciesButton;
@property (weak, nonatomic) IBOutlet MDCButton *imagesButton;

@property (weak, nonatomic) IBOutlet MDCButton *dateButton;

@property (weak, nonatomic) IBOutlet UIView *specimensView;
@property (weak, nonatomic) IBOutlet MDCButton *specimensButton;

@property (weak, nonatomic) IBOutlet UIStackView *variableContentContainer;
@property (weak, nonatomic) IBOutlet UIStackView *variableContentContainer2;

@property (strong, nonatomic) NSMutableArray<RiistaSpeciesCategory*> *categoryList;

@property (strong, nonatomic) UITapGestureRecognizer *speciesTapRecognizer;
@property (strong, nonatomic) MDCDialogTransitionController *dialogTransitionController;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;

@end

static CGFloat const FIELD_HEIGHT_SMALL = 43.0;

static CGFloat const VERTICAL_SPACING = 8.0;
static CGFloat const LEFT_MARGIN = 12.0;
static CGFloat const RIGHT_MARGIN = 12.0;

static NSString * const OBSERVATION_TYPE_KEY = @"ObservationTypeKey";
static NSString * const DEER_HUNTING_TYPE_KEY = @"DeerHuntingTypeKey";
static NSInteger const SPECIMEN_AMOUNT_TAG = 201;
static NSInteger const MOOSE_AMOUNT_MALE_TAG = 202;
static NSInteger const MOOSE_AMOUNT_FEMALE_TAG = 203;
static NSInteger const MOOSE_AMOUNT_FEMALE1_TAG = 204;
static NSInteger const MOOSE_AMOUNT_FEMALE2_TAG = 205;
static NSInteger const MOOSE_AMOUNT_FEMALE3_TAG = 206;
static NSInteger const MOOSE_AMOUNT_FEMALE4_TAG = 207;
static NSInteger const MOOSE_AMOUNT_UNKNOWN_TAG = 208;
static NSInteger const MOOSE_AMOUNT_CALF_TAG = 209;
static NSInteger const OBSERVATION_DEER_HUNTING_TYPE_DESCRIPTION_TAG = 210;

static NSInteger const OBSERVER_NAME_TAG = 221;
static NSInteger const OBSERVER_PHONE_TAG = 222;
static NSInteger const OFFICIAL_ADDITIONAL_INFO_TAG = 223;




@implementation ObservationDetailsViewController
{
    ImageEditUtil *imageUtil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _categoryList = [NSMutableArray new];
        NSDictionary *categories = [RiistaGameDatabase sharedInstance].categories;
        NSArray *categoryKeys = [categories allKeys];
        NSSortDescriptor *categorySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        NSArray *sortedCategoryKeys = [categoryKeys sortedArrayUsingDescriptors:@[categorySortDescriptor]];
        for (int i=0; i<categories.count; i++) {
            [_categoryList addObject:categories[sortedCategoryKeys[i]]];
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    imageUtil = [[ImageEditUtil alloc] initWithParentController:self];

    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    [AppTheme.shared setupSpeciesButtonThemeWithButton:self.speciesButton];
    [AppTheme.shared setupImagesButtonThemeWithButton:self.imagesButton];
    [AppTheme.shared setupPrimaryButtonThemeWithButton:self.specimensButton];

    [AppTheme.shared setupTextButtonThemeWithButton:self.dateButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refreshLocalizedTexts];
    [self selectedValuesChanged];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public interface

- (CGFloat)refreshViews
{
    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.selectedSpeciesCode integerValue]];
    if (!species) {
        [self.speciesButton setTitle:RiistaLocalizedString(@"ChooseSpecies", nil) forState:UIControlStateNormal];
        [self.speciesButton setImage:[[UIImage imageNamed:@"observation_white"] resizedImageToFitInSize:CGSizeMake(20.0f, 20.0f) scaleIfSmaller:NO]
                            forState:UIControlStateNormal];
    }
    else {
        [self.speciesButton setTitle:[RiistaUtils nameWithPreferredLanguage:species.name] forState:UIControlStateNormal];
        [self.speciesButton setImage:[RiistaUtils loadSpeciesImage:species.speciesId
                                                              size:CGSizeMake(42.0f, 42.0f)] forState:UIControlStateNormal];
    }
    [self updateSpeciesButtonForSpecies:species];

    [self refreshImage];

    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance]
                                             getObservationMetadataForSpecies:species.speciesId];

    [self resetObservationViews:metadata];

    [self.view setNeedsLayout];

    return 0.0;
}

- (void)refreshImage
{
    if (self.diaryImage != nil) {
        [RiistaUtils loadDiaryImage:self.diaryImage size:CGSizeMake(50.0f, 50.0f) completion:^(UIImage *image) {
            [self.imagesButton setBackgroundImage:[image scaleImageToSize:CGSizeMake(50.0f, 50.0f)]
                                         forState:UIControlStateNormal];
            [self.imagesButton setImage:nil forState:UIControlStateNormal];
            [self.imagesButton setBorderWidth:0 forState:UIControlStateNormal];
        }];
    }
}

- (void)updateSpeciesButtonForSpecies:(RiistaSpecies *)species
{
    self.speciesButton.imageEdgeInsets = UIEdgeInsetsMake(self.speciesButton.imageEdgeInsets.top,
                                                          species != nil ? -12 : 0,
                                                          self.speciesButton.imageEdgeInsets.bottom,
                                                          self.speciesButton.imageEdgeInsets.right);
    self.speciesButton.titleEdgeInsets = UIEdgeInsetsMake(self.speciesButton.titleEdgeInsets.top,
                                                          species != nil ? 0 : 16,
                                                          self.speciesButton.titleEdgeInsets.bottom,
                                                          self.speciesButton.titleEdgeInsets.right);
    self.speciesButton.imageView.layer.cornerRadius = 3;
}

- (void)refreshDateTime:(NSString *)dateTimeString
{
    [self.dateButton setTitle:dateTimeString forState:UIControlStateNormal];
}

#pragma mark -

// Clear existing specimens and replace with empty
- (void)resetSpecimensToAmount:(NSInteger)amount
{
    if (!self.editMode) {
        DDLog(@"Tried to reset specimens while not editing");
        return;
    }

    NSOrderedSet *toBeRemoved = [self.entry.specimens copy];
    [self.entry removeSpecimens:toBeRemoved];
    for (ObservationSpecimen *item in toBeRemoved) {
        [self.editContext deleteObject:item];
    }

    if (amount > 0) {
        [self.entry setSpecimens:[NSOrderedSet new]];
        [self generateEmptySpecimensToAmount:amount];
    }
    else {
        [self.entry setSpecimens:nil];
    }
}

- (void)generateEmptySpecimensToAmount:(NSInteger)amount
{
    if (!self.editMode) {
        DDLog(@"Tried to generate specimens while not editing");
        return;
    }

    if (amount > DiaryEntrySpecimenDetailsMax) {
        DDLog(@"Trying to generate specimens to %ld", (long)amount);
        return;
    }

    for (NSInteger i = [self.entry.specimens count]; i < amount; ++i) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"ObservationSpecimen" inManagedObjectContext:self.editContext];
        ObservationSpecimen *newSpecimen = (ObservationSpecimen*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.editContext];
        [self.entry addSpecimensObject:newSpecimen];
    }
}

- (void)removeExtraSpecimens:(NSInteger)amount purgeEmpty:(BOOL)purgeEmpty
{
    if (!self.editMode && !purgeEmpty) {
        DDLog(@"Tried to remove specimens while not editing");
        return;
    }

    while ([self.entry.specimens count] > amount) {
        ObservationSpecimen *toBeRemovedSpecimen = [self.entry.specimens lastObject];
        [self.entry removeSpecimensObject:toBeRemovedSpecimen];
        [self.editContext deleteObject:toBeRemovedSpecimen];
    }

    if (purgeEmpty) {
        NSMutableArray *toBeRemovedSpecimens = [NSMutableArray new];

        for (ObservationSpecimen *item in self.entry.specimens) {
            if ([item isEmpty]) {
                [toBeRemovedSpecimens addObject:item];
            }
        }

        [self.entry removeSpecimens:[NSOrderedSet orderedSetWithArray:toBeRemovedSpecimens]];
        for (ObservationSpecimen *item in toBeRemovedSpecimens) {
            [self.editContext deleteObject:item];
        }
    }
}

- (void)selectSingleObservationTypeOrClearSelection
{
    // single observation type can be selected if there's only one observation type for the current
    // preconditions: species and observation category. This is e.g. the case for white tailed deer which
    // has been observed within deer hunting
    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:[self.selectedSpeciesCode integerValue]];
    if (metadata == nil) {
        [self changeObservationType:nil];
        return;
    }

    NSArray* observationTypes = [metadata getObservationTypes:self.selectedObservationCategory];
    if (observationTypes.count == 1) {
        [self changeObservationType:[observationTypes objectAtIndex:0] forceRefresh:YES];
    } else {
        [self changeObservationType:nil];
    }
}

- (void)changeObservationType:(NSString*)type
{
    [self changeObservationType:type forceRefresh:NO];
}

- (void)changeObservationType:(NSString*)type forceRefresh:(BOOL)forceRefresh
{
    // there's nothing to do if selecting previous type
    if ([self.selectedObservationType isEqualToString:type] && !forceRefresh) {
        DDLog(@"Doing nothing, user selected same observation type as before");
        return;
    }
    self.selectedObservationType = type;

    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:[self.selectedSpeciesCode integerValue]];

    ObservationContextSensitiveFieldSets *field = [metadata findFieldSetByType:type observationCategory:self.selectedObservationCategory];
    if (field != nil && ([field hasFieldSet:field.baseFields name:@"amount"]
        || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:field fieldName:@"amount"])) {
        self.entry.totalSpecimenAmount = [NSNumber numberWithInt:1];
    }
    else {
        self.entry.totalSpecimenAmount = nil;
    }

    self.selectedMooselikeMaleAmount = nil;
    self.selectedMooselikeFemaleAmount = nil;
    self.selectedMooselikeFemale1CalfAmount = nil;
    self.selectedMooselikeFemale2CalfAmount = nil;
    self.selectedMooselikeFemale3CalfAmount = nil;
    self.selectedMooselikeFemale4CalfAmount = nil;
    self.selectedMooselikeCalfAmount = nil;
    self.selectedMooselikeUnknownAmount = nil;

    self.selectedObserverName = nil;
    self.selectedObserverPhoneNumber = nil;
    self.selectedOfficialAdditionalInfo = nil;
    self.selectedVerifiedByCarnivoreAuthority = nil;

    self.selectedInYardsDistanceFromResidence = nil;
    self.selectedPack = nil;
    self.selectedLitter = nil;

    [self resetSpecimensToAmount:[self.entry.totalSpecimenAmount integerValue]];
    [self selectedValuesChanged];
}

- (void)changeDeerHuntingType:(NSString*)deerHuntingTypeAsString
{
    DeerHuntingType deerHuntingType = [DeerHuntingTypeHelper parseWithHuntingTypeString:deerHuntingTypeAsString
                                                                               fallback:DeerHuntingTypeNone];
    if (deerHuntingType == DeerHuntingTypeNone || self.selectedDeerHuntingType == deerHuntingType) {
        DDLog(@"Doing nothing, same deer hunting type selected as before (or parsing failed)");
        return;
    }

    self.selectedDeerHuntingType = deerHuntingType;

    [self selectedValuesChanged];
}

- (void)changeSpecimenAmount:(NSInteger)amount
{
    if (amount > 0) {
        if (self.entry.specimens == nil) {
            [self.entry setSpecimens:[NSOrderedSet new]];
        }

        if (amount > DiaryEntrySpecimenDetailsMax) {
            [self resetSpecimensToAmount:0];
        }
        else {
            [self generateEmptySpecimensToAmount:amount];
            [self removeExtraSpecimens:amount purgeEmpty:NO];
        }

        self.entry.totalSpecimenAmount = [NSNumber numberWithInteger:amount];
    }
    else {
        [self resetSpecimensToAmount:0];
        self.entry.totalSpecimenAmount = nil;
    }

    [self selectedValuesChanged];
}

- (void)selectedValuesChanged
{
    [self.delegate valuesUpdated:self];
}

- (void)resetObservationViews:(ObservationSpecimenMetadata*)metadata
{
    [self.variableContentContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.variableContentContainer2.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.specimensView.hidden = YES;

    if (self.editMode) {
        [self createObservationViewsForEdit:metadata];
    } else {
        [self createObservationViewsReadOnly:metadata];
    }
}

- (void)createObservationViewsReadOnly:(ObservationSpecimenMetadata*)metadata
{
    if (metadata) {
        if (self.selectedObservationCategory == ObservationCategoryMooseHunting) {
            [self createMooseHuntingChoice];
        } else if (self.selectedObservationCategory == ObservationCategoryDeerHunting) {
            [self createDeerHuntingChoice];
        }

        [self createObservationTypeChoiceView:metadata];

        if (self.selectedObservationCategory == ObservationCategoryNormal) {
            if ([self.entry.totalSpecimenAmount integerValue] > 0) {
                [self createAmountChoiceView:metadata];
            }
        } else {
            if (self.selectedDeerHuntingType != DeerHuntingTypeNone) {
                [self createDeerHuntingChoiceView:metadata];
                if (self.selectedDeerHuntingTypeDescription != nil) {
                    [self createDeerHuntingTypeDescription:metadata];
                }
            }

            [self createMooselikeChoiceViewsReadOnly];
        }

        if ([[RiistaSettings userInfo] isCarnivoreAuthority]) {
            [self createCarnivoreAuthorityFields:metadata];
        }
        [self createCalculatedFields];

        ObservationContextSensitiveFieldSets *field = [metadata findFieldSetByType:self.selectedObservationType observationCategory:self.selectedObservationCategory];

        // Hack to hide for mooselike species
        if (![field requiresMooselikeAmounts:field.baseFields] &&
            [self.entry.totalSpecimenAmount integerValue] > 0 &&
            [self.entry.totalSpecimenAmount integerValue] <= DiaryEntrySpecimenDetailsMax &&
            [field.specimenFields count] > 0)
        {
            self.specimensView.hidden = NO;
        }
    }

    [self.specimensView setNeedsLayout];
    [self.specimensView layoutIfNeeded];
}

- (void)createObservationViewsForEdit:(ObservationSpecimenMetadata*)metadata
{
    if (metadata) {
        [self resetDeprecatedObservationCategoryForEdit:metadata];

        ObservationWithinHuntingCapability mooseHuntingCapability = [metadata getMooseHuntingCapability];
        if (mooseHuntingCapability == ObservationWithinHuntingCapabilityYes) {
            [self createMooseHuntingChoice];
        }

        ObservationWithinHuntingCapability deerHuntingCapability = [metadata getDeerHuntingCapability];
        BOOL isDeerPilot = [[RiistaSettings userInfo] deerPilotUser] && deerHuntingCapability == ObservationWithinHuntingCapabilityDeerPilot;
        if (deerHuntingCapability == ObservationWithinHuntingCapabilityYes || isDeerPilot) {
            [self createDeerHuntingChoice];
        }

        [self createObservationTypeChoiceView:metadata];
        if (self.selectedObservationCategory == ObservationCategoryDeerHunting) {
            [self createDeerHuntingChoiceView:metadata];
            if (self.selectedDeerHuntingType == DeerHuntingTypeOther) {
                [self createDeerHuntingTypeDescription:metadata];
            }
        }

        [self createAmountChoiceView:metadata];
        [self createMooselikeChoiceViews:metadata];
        if ([[RiistaSettings userInfo] isCarnivoreAuthority]) {
            [self createCarnivoreAuthorityFields:metadata];
        }
        [self createCalculatedFields];

        ObservationContextSensitiveFieldSets *field = [metadata findFieldSetByType:self.selectedObservationType observationCategory:self.selectedObservationCategory];

        // Hack to hide for mooselike species
        if (![field requiresMooselikeAmounts:field.baseFields] &&
            [self.entry.totalSpecimenAmount integerValue] > 0 &&
            [self.entry.totalSpecimenAmount integerValue] <= DiaryEntrySpecimenDetailsMax &&
            [field.specimenFields count] > 0)
        {
            self.specimensView.hidden = NO;
        }
    }

    [self.specimensView setNeedsLayout];
    [self.specimensView layoutIfNeeded];
}

- (void)createMooseHuntingChoice
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, VERTICAL_SPACING, self.variableContentContainer.frame.size.width, FIELD_HEIGHT_SMALL)];
    container.backgroundColor = [UIColor whiteColor];

    M13Checkbox *checkbox = [[M13Checkbox alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0.0, container.frame.size.width - LEFT_MARGIN - RIGHT_MARGIN, FIELD_HEIGHT_SMALL)
                                                         title:RiistaLocalizedString(@"ObservationDetailsWithinMooseHunting", nil)
                                                   checkHeight:20.0f];
    [checkbox setStrokeColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [checkbox setCheckColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground]];

    checkbox.titleLabel.font = [UIFont fontWithName:AppFont.Name size:AppFont.LabelMedium];
    checkbox.checkState = self.selectedObservationCategory == ObservationCategoryMooseHunting ?
        M13CheckboxStateChecked : M13CheckboxStateUnchecked;

    [checkbox addTarget:self action:@selector(mooseHuntingCheckboxDidChange:) forControlEvents:UIControlEventValueChanged];

    [container addSubview:checkbox];

    container.translatesAutoresizingMaskIntoConstraints = NO;
    [container.heightAnchor constraintEqualToConstant:container.frame.size.height].active = YES;
    [container.widthAnchor constraintEqualToConstant:container.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:container];
}

- (void)createDeerHuntingChoice
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, VERTICAL_SPACING, self.variableContentContainer.frame.size.width, FIELD_HEIGHT_SMALL)];
    container.backgroundColor = [UIColor whiteColor];

    M13Checkbox *checkbox = [[M13Checkbox alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0.0, container.frame.size.width - LEFT_MARGIN - RIGHT_MARGIN, FIELD_HEIGHT_SMALL)
                                                         title:RiistaLocalizedString(@"ObservationDetailsWithinDeerHunting", nil)
                                                   checkHeight:20.0f];
    [checkbox setStrokeColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [checkbox setCheckColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground]];

    checkbox.titleLabel.font = [UIFont fontWithName:AppFont.Name size:AppFont.LabelMedium];
    checkbox.checkState = self.selectedObservationCategory == ObservationCategoryDeerHunting ?
        M13CheckboxStateChecked : M13CheckboxStateUnchecked;

    [checkbox addTarget:self action:@selector(deerHuntingCheckboxDidChange:) forControlEvents:UIControlEventValueChanged];

    [container addSubview:checkbox];

    container.translatesAutoresizingMaskIntoConstraints = NO;
    [container.heightAnchor constraintEqualToConstant:container.frame.size.height].active = YES;
    [container.widthAnchor constraintEqualToConstant:container.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:container];
}

- (void)mooseHuntingCheckboxDidChange:(M13Checkbox*)sender
{
    if (sender.checkState == M13CheckboxStateChecked) {
        self.selectedObservationCategory = ObservationCategoryMooseHunting;
    }
    else {
        self.selectedObservationCategory = ObservationCategoryNormal;
    }

    [self selectSingleObservationTypeOrClearSelection];
}

- (void)deerHuntingCheckboxDidChange:(M13Checkbox*)sender
{
    if (sender.checkState == M13CheckboxStateChecked) {
        self.selectedObservationCategory = ObservationCategoryDeerHunting;
    }
    else {
        self.selectedObservationCategory = ObservationCategoryNormal;
    }

    [self selectSingleObservationTypeOrClearSelection];
}

- (void)resetDeprecatedObservationCategoryForEdit:(ObservationSpecimenMetadata*)metadata
{
    // Observation category needs to be reset to default one if no observation types are found.
    // This may happen when observation category is deprecated for the selected species in the
    // current metadata.
    //
    // Example: previously white tailed deer observations could be made within moose hunting.
    // When observation metadata was bumped to 4, the white tailed deer observations could
    // only be made within _deer_ hunting and no longer within moose hunting. It is possible that
    // there are deer observation that have been made within moose hunting and in order to edit
    // those observations we need to reset the observation category if no observation types
    // are available for the selected observation category.
    ObservationCategory defaultObservationCategory = ObservationCategoryNormal;
    NSArray *observationTypes = [metadata getObservationTypes:self.selectedObservationCategory];
    if (self.selectedObservationCategory != defaultObservationCategory &&
        (!observationTypes || observationTypes.count == 0)) {
        self.selectedObservationCategory = defaultObservationCategory;
    }
}

- (void)createObservationTypeChoiceView:(ObservationSpecimenMetadata *)metadata
{
    NSMutableArray<NSString*> *types = [NSMutableArray new];
    for (ObservationContextSensitiveFieldSets *field in metadata.contextSensitiveFieldSets) {
        if (field.category == self.selectedObservationCategory) {
            [types addObject:field.type];
        }
    }

    RiistaValueListButton *control = [[RiistaValueListButton alloc]
                                      initWithFrame:CGRectMake(0, 0, self.variableContentContainer.frame.size.width,
                                                               RiistaDefaultValueElementHeight)];
    control.backgroundColor = [UIColor applicationColor:ViewBackground];
    control.titleText = RiistaLocalizedString(@"ObservationDetailsType", nil);
    control.valueText = RiistaMappedValueString(self.selectedObservationType, nil);

    [control addTarget:self action:@selector(onObservationTypeClick) forControlEvents:UIControlEventTouchUpInside];

    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control.heightAnchor constraintEqualToConstant:control.frame.size.height].active = YES;
    [control.widthAnchor constraintEqualToConstant:control.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:control];
}

- (void)createDeerHuntingChoiceView:(ObservationSpecimenMetadata *)metadata
{
    RiistaValueListButton *control = [[RiistaValueListButton alloc]
                                      initWithFrame:CGRectMake(0, 0, self.variableContentContainer.frame.size.width,
                                                               RiistaDefaultValueElementHeight)];
    control.backgroundColor = [UIColor applicationColor:ViewBackground];
    control.titleText = RiistaLocalizedString(@"DeerHuntingType", nil);
    control.valueText = RiistaMappedValueString([DeerHuntingTypeHelper stringForDeerHuntingType:self.selectedDeerHuntingType], nil);

    [control addTarget:self action:@selector(onDeerHuntingTypeClick) forControlEvents:UIControlEventTouchUpInside];

    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control.heightAnchor constraintEqualToConstant:control.frame.size.height].active = YES;
    [control.widthAnchor constraintEqualToConstant:control.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:control];
}

- (void)createDeerHuntingTypeDescription:(ObservationSpecimenMetadata *)metadata
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"DeerHuntingTypeDescription", nil)
                                                          value:self.selectedDeerHuntingTypeDescription
                                                           grow:0];
    item.maxTextLength = [NSNumber numberWithInteger:255];
    item.textField.keyboardType = UIKeyboardTypeDefault;
    item.textField.returnKeyType = UIReturnKeyDone;
    item.textField.tag = OBSERVATION_DEER_HUNTING_TYPE_DESCRIPTION_TAG;
    item.textField.delegate = self;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:item];
}

- (void)createAmountChoiceView:(ObservationSpecimenMetadata *)metadata
{
    ObservationContextSensitiveFieldSets *fields = [metadata findFieldSetByType:self.selectedObservationType observationCategory:self.selectedObservationCategory];
    if (fields != nil) {
        if ([fields hasFieldSet:fields.baseFields name:@"amount"] || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:fields fieldName:@"amount"]) {
            NSInteger amount = 0;
            if (self.entry.totalSpecimenAmount) {
                amount = [self.entry.totalSpecimenAmount integerValue];
            }

            amount = MAX(amount, 1);

            self.entry.totalSpecimenAmount = [NSNumber numberWithInteger:amount];

            RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"Amount", nil)
                                                                  value:[self.entry.totalSpecimenAmount stringValue]
                                                                   grow:0];
            item.minNumberValue = [NSNumber numberWithInteger:1];
            item.maxNumberValue = [NSNumber numberWithInteger:AppConstants.ObservationMaxAmount];
            item.nonNegativeIntNumberOnly = YES;
            item.textField.tag = SPECIMEN_AMOUNT_TAG;
            item.textField.keyboardType = UIKeyboardTypeNumberPad;
            item.textField.delegate = self;

            item.translatesAutoresizingMaskIntoConstraints = NO;
            [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
            [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
            [self.variableContentContainer addArrangedSubview:item];
        }
        else {

        }
    }
}

- (void)createCarnivoreAuthorityFields:(ObservationSpecimenMetadata *)metadata
{
    ObservationContextSensitiveFieldSets *fields = [metadata findFieldSetByType:self.selectedObservationType observationCategory:self.selectedObservationCategory];
    if (fields == nil) {
        return;
    }

    // Populate first container

    if ([fields hasFieldSet:fields.baseFields name:@"verifiedByCarnivoreAuthority"]
        || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:fields fieldName:@"verifiedByCarnivoreAuthority"]) {
        [self createVerifiedByCarnivoreAuthorityChoice:RiistaLocalizedString(@"TassuVerifiedByCarnivoreAuthority", nil) value:self.selectedVerifiedByCarnivoreAuthority];
    }

    if ([fields hasFieldSet:fields.baseFields name:@"observerName"]
        || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:fields fieldName:@"observerName"]) {
        if (self.selectedObserverName == nil) {
            self.selectedObserverName = @"";
        }

        RiistaValueListTextField *view = [self createMooseTextField:RiistaLocalizedString(@"TassuObserverName", nil) value:self.selectedObserverName grow:0];

        view.textField.tag = OBSERVER_NAME_TAG;
        view.maxTextLength = [NSNumber numberWithInt:255];
        view.delegate = self;

        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
        [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
        [self.variableContentContainer addArrangedSubview:view];
    }

    if ([fields hasFieldSet:fields.baseFields name:@"observerPhoneNumber"]
        || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:fields fieldName:@"observerPhoneNumber"]) {
        if (self.selectedObserverPhoneNumber == nil) {
            self.selectedObserverPhoneNumber = @"";
        }

        RiistaValueListTextField *view = [self createMooseTextField:RiistaLocalizedString(@"TassuObserverPhoneNumber", nil) value:self.selectedObserverPhoneNumber grow:0];

        view.textField.tag = OBSERVER_PHONE_TAG;
        view.maxTextLength = [NSNumber numberWithInt:255];
        view.delegate = self;

        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
        [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
        [self.variableContentContainer addArrangedSubview:view];
    }

    if ([fields hasFieldSet:fields.baseFields name:@"officialAdditionalInfo"]
        || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:fields fieldName:@"officialAdditionalInfo"]) {
        if (self.selectedObserverName == nil) {
            self.selectedObserverName = @"";
        }

        RiistaValueListTextField *view = [self createMooseTextField:RiistaLocalizedString(@"TassuOfficialAdditionalInfo", nil) value:self.selectedOfficialAdditionalInfo grow:0];

        view.textField.tag = OFFICIAL_ADDITIONAL_INFO_TAG;
        view.maxTextLength = [NSNumber numberWithInt:255];
        view.delegate = self;

        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
        [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
        [self.variableContentContainer addArrangedSubview:view];
    }

    if (self.selectedInYardsDistanceFromResidence != nil) {
        NSString *value = [[self.selectedInYardsDistanceFromResidence stringValue] stringByAppendingString:@" m"];

        RiistaValueListReadonlyText *view = [self createReadonlyTextField:RiistaLocalizedString(@"TassuDistanceToResidence", nil) value:value];

        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
        [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
        [self.variableContentContainer addArrangedSubview:view];
    }
}

- (void)createCalculatedFields
{
    // Populate second container

    if (self.selectedPack != nil && [self.selectedPack boolValue]) {
        NSString *value = [self.selectedPack boolValue] ? RiistaLocalizedString(@"Yes", nil) : RiistaLocalizedString(@"No", nil);

        RiistaValueListReadonlyText *view = [self createReadonlyTextField:RiistaLocalizedString(@"TassuPack", nil) value:value];

        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
        [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
        [self.variableContentContainer2 addArrangedSubview:view];
    }

    if (self.selectedLitter != nil && [self.selectedLitter boolValue]) {
        NSString *value = [self.selectedLitter boolValue] ? RiistaLocalizedString(@"Yes", nil) : RiistaLocalizedString(@"No", nil);

        RiistaValueListReadonlyText *view = [self createReadonlyTextField:RiistaLocalizedString(@"TassuLitter", nil) value:value];

        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
        [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
        [self.variableContentContainer2 addArrangedSubview:view];
    }
}

- (void)createVerifiedByCarnivoreAuthorityChoice:(NSString*)name value:(NSNumber*)value
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0, self.variableContentContainer.frame.size.width, FIELD_HEIGHT_SMALL)];
    container.backgroundColor = [UIColor whiteColor];

    M13Checkbox *checkbox = [[M13Checkbox alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0.0, container.frame.size.width - LEFT_MARGIN - RIGHT_MARGIN, FIELD_HEIGHT_SMALL)
                                                         title:name
                                                   checkHeight:20.0f];
    [checkbox setStrokeColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [checkbox setCheckColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground]];

    checkbox.titleLabel.font = [UIFont fontWithName:AppFont.Name size:AppFont.LabelMedium];
    checkbox.checkState = [value boolValue] ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;

    [checkbox addTarget:self action:@selector(verifiedByCarnivoreAuthorityCheckboxDidChange:) forControlEvents:UIControlEventValueChanged];

    [container addSubview:checkbox];

    container.translatesAutoresizingMaskIntoConstraints = NO;
    [container.heightAnchor constraintEqualToConstant:container.frame.size.height].active = YES;
    [container.widthAnchor constraintEqualToConstant:container.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:container];
}

- (void)verifiedByCarnivoreAuthorityCheckboxDidChange:(M13Checkbox*)sender
{
    if (sender.checkState == M13CheckboxStateChecked) {
        self.selectedVerifiedByCarnivoreAuthority = [NSNumber numberWithBool:YES];
    }
    else {
        self.selectedVerifiedByCarnivoreAuthority = [NSNumber numberWithBool:NO];
    }
}

- (RiistaValueListReadonlyText*)createReadonlyTextField:(NSString*)name value:(NSString*)value
{
    RiistaValueListReadonlyText *control = [[RiistaValueListReadonlyText alloc]
                                            initWithFrame:CGRectMake(0, 0, self.variableContentContainer.frame.size.width,
                                                                     RiistaDefaultValueElementHeight)];
    control.backgroundColor = [UIColor whiteColor];
    control.titleTextLabel.text = name;
    if (value == nil) {
        control.valueTextLabel.text = @"";
    }
    else {
        control.valueTextLabel.text = value;
    }
    return control;
}

- (void)createMooselikeChoiceViews:(ObservationSpecimenMetadata *)metadata
{
    ObservationContextSensitiveFieldSets *fields = [metadata findFieldSetByType:self.selectedObservationType observationCategory:self.selectedObservationCategory];
    if (fields == nil) {
        return;
    }

    [self createMooseLikeMaleAmountChoiceViewIfRequired:fields];
    [self createMooseLikeFemaleAmountChoiceViewIfRequired:fields];
    [self createMooseLikeFemale1CalfAmountChoiceViewIfRequired:fields];
    [self createMooseLikeFemale2CalvesAmountChoiceViewIfRequired:fields];
    [self createMooseLikeFemale3CalvesAmountChoiceViewIfRequired:fields];
    [self createMooseLikeFemale4CalvesAmountChoiceViewIfRequired:fields];
    [self createMooseLikeCalvesAmountChoiceViewIfRequired:fields];
    [self createMooseLikeUnknownSpecimenAmountChoiceViewIfRequired:fields];
}

- (void)createMooselikeChoiceViewsReadOnly
{
    [self createMooseLikeMaleAmountChoiceView];
    [self createMooseLikeFemaleAmountChoiceView];
    [self createMooseLikeFemale1CalfAmountChoiceView];
    [self createMooseLikeFemale2CalvesAmountChoiceView];
    [self createMooseLikeFemale3CalvesAmountChoiceView];
    [self createMooseLikeFemale4CalvesAmountChoiceView];
    [self createMooseLikeCalvesAmountChoiceView];
    [self createMooseLikeUnknownSpecimenAmountChoiceView];
}

- (void)createMooseLikeMaleAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeMaleAmount"]) {
        if (self.selectedMooselikeMaleAmount == nil) {
            self.selectedMooselikeMaleAmount = @0;
        }

        [self createMooseLikeMaleAmountChoiceView];
    }
}

- (void)createMooseLikeMaleAmountChoiceView
{
    if (self.selectedMooselikeMaleAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseMale", nil)
                                  value:[self.selectedMooselikeMaleAmount stringValue]
                                    tag:MOOSE_AMOUNT_MALE_TAG];
    }
}

- (void)createMooseLikeFemaleAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeFemaleAmount"]) {
        if (self.selectedMooselikeFemaleAmount == nil) {
            self.selectedMooselikeFemaleAmount = @0;
        }

        [self createMooseLikeFemaleAmountChoiceView];
    }
}

- (void)createMooseLikeFemaleAmountChoiceView
{
    if (self.selectedMooselikeFemaleAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseFemale", nil)
                                  value:[self.selectedMooselikeFemaleAmount stringValue]
                                    tag:MOOSE_AMOUNT_FEMALE_TAG];
    }
}

- (void)createMooseLikeFemale1CalfAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeFemale1CalfAmount"]) {
        if (self.selectedMooselikeFemale1CalfAmount == nil) {
            self.selectedMooselikeFemale1CalfAmount = @0;
        }

        [self createMooseLikeFemale1CalfAmountChoiceView];
    }
}

- (void)createMooseLikeFemale1CalfAmountChoiceView
{
    if (self.selectedMooselikeFemale1CalfAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseFemale1Calf", nil)
                                  value:[self.selectedMooselikeFemale1CalfAmount stringValue]
                                    tag:MOOSE_AMOUNT_FEMALE1_TAG];
    }
}

- (void)createMooseLikeFemale2CalvesAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeFemale2CalfsAmount"]) {
        if (self.selectedMooselikeFemale2CalfAmount == nil) {
            self.selectedMooselikeFemale2CalfAmount = @0;
        }

        [self createMooseLikeFemale2CalvesAmountChoiceView];
    }
}

- (void)createMooseLikeFemale2CalvesAmountChoiceView
{
    if (self.selectedMooselikeFemale2CalfAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseFemale2Calf", nil)
                                  value:[self.selectedMooselikeFemale2CalfAmount stringValue]
                                    tag:MOOSE_AMOUNT_FEMALE2_TAG];
    }
}

- (void)createMooseLikeFemale3CalvesAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeFemale3CalfsAmount"]) {
        if (self.selectedMooselikeFemale3CalfAmount == nil) {
            self.selectedMooselikeFemale3CalfAmount = @0;
        }

        [self createMooseLikeFemale3CalvesAmountChoiceView];
    }
}

- (void)createMooseLikeFemale3CalvesAmountChoiceView
{
    if (self.selectedMooselikeFemale3CalfAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseFemale3Calf", nil)
                                  value:[self.selectedMooselikeFemale3CalfAmount stringValue]
                                    tag:MOOSE_AMOUNT_FEMALE3_TAG];
    }
}

- (void)createMooseLikeFemale4CalvesAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeFemale4CalfsAmount"]) {
        if (self.selectedMooselikeFemale4CalfAmount == nil) {
            self.selectedMooselikeFemale4CalfAmount = @0;
        }

        [self createMooseLikeFemale4CalvesAmountChoiceView];
    }
}

- (void)createMooseLikeFemale4CalvesAmountChoiceView
{
    if (self.selectedMooselikeFemale4CalfAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseFemale4Calf", nil)
                                  value:[self.selectedMooselikeFemale4CalfAmount stringValue]
                                    tag:MOOSE_AMOUNT_FEMALE4_TAG];
    }
}

- (void)createMooseLikeCalvesAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeCalfAmount"]) {
        if (self.selectedMooselikeCalfAmount == nil) {
            self.selectedMooselikeCalfAmount = @0;
        }

        [self createMooseLikeCalvesAmountChoiceView];
    }
}

- (void)createMooseLikeCalvesAmountChoiceView
{
    if (self.selectedMooselikeCalfAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseCalf", nil)
                                  value:[self.selectedMooselikeCalfAmount stringValue]
                                    tag:MOOSE_AMOUNT_CALF_TAG];
    }
}

- (void)createMooseLikeUnknownSpecimenAmountChoiceViewIfRequired:(ObservationContextSensitiveFieldSets*)fields
{
    if ([self hasRequiredFieldset:fields fieldKey:@"mooselikeUnknownSpecimenAmount"]) {
        if (self.selectedMooselikeUnknownAmount == nil) {
            self.selectedMooselikeUnknownAmount = @0;
        }

        [self createMooseLikeUnknownSpecimenAmountChoiceView];
    }
}

- (void)createMooseLikeUnknownSpecimenAmountChoiceView
{
    if (self.selectedMooselikeUnknownAmount != nil) {
        [self createMooseLikeChoiceView:RiistaLocalizedString(@"ObservationDetailsMooseUnknown", nil)
                                  value:[self.selectedMooselikeUnknownAmount stringValue]
                                    tag:MOOSE_AMOUNT_UNKNOWN_TAG];
    }
}


- (BOOL)hasRequiredFieldset:(ObservationContextSensitiveFieldSets*)fields fieldKey:(NSString*)fieldKey
{
    return [fields hasFieldSet:fields.baseFields name:fieldKey];
}

- (void)createMooseLikeChoiceView:(NSString*)name
                            value:(NSString*)value
                              tag:(NSInteger)tag
{
    RiistaValueListTextField * view = [self createMooseTextField:name value:value grow:0];
    view.textField.tag = tag;
    view.textField.keyboardType = UIKeyboardTypeNumberPad;
    view.maxNumberValue = [NSNumber numberWithInt:50];
    view.nonNegativeIntNumberOnly = YES;
    view.delegate = self;

    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view.heightAnchor constraintEqualToConstant:view.frame.size.height].active = YES;
    [view.widthAnchor constraintEqualToConstant:view.frame.size.width].active = YES;
    [self.variableContentContainer addArrangedSubview:view];
}

- (RiistaValueListTextField*)createMooseTextField:(NSString*)name value:(NSString*)value grow:(int)grow
{
    RiistaValueListTextField *control = [[RiistaValueListTextField alloc]
                                         initWithFrame:CGRectMake(0, 0, self.variableContentContainer.frame.size.width,
                                                                  RiistaDefaultValueElementHeight + grow)];
    control.backgroundColor = [UIColor whiteColor];
    control.textField.enabled = YES;
    control.textField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:control.textField];
    control.titleTextLabel.text = name;
    if (value == nil) {
        control.textField.text = @"";
    }
    else {
        control.textField.text = value;
    }

    return control;
}

- (void)onObservationTypeClick
{
    if (self.editMode) {
        ValueListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"valueListController"];
        controller.delegate = self;
        controller.fieldKey = [NSString stringWithString:OBSERVATION_TYPE_KEY];
        controller.titlePrompt = RiistaLocalizedString(@"ObservationDetailsType", nil);

        NSMutableArray *valueList = [[NSMutableArray alloc] init];

        ObservationSpecimenMetadata *meta = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:[self.selectedSpeciesCode integerValue]];
        for (ObservationContextSensitiveFieldSets *fieldSet in meta.contextSensitiveFieldSets) {
            if (fieldSet.category == self.selectedObservationCategory) {
                [valueList addObject:fieldSet.type];
            }
        }

        controller.values = valueList;

        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)onDeerHuntingTypeClick
{
    if (self.editMode) {
        ValueListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"valueListController"];
        controller.delegate = self;
        controller.fieldKey = [NSString stringWithString:DEER_HUNTING_TYPE_KEY];
        controller.titlePrompt = RiistaLocalizedString(@"DeerHuntingType", nil);

        NSMutableArray *valueList = [[NSMutableArray alloc] init];
        [valueList addObject:[DeerHuntingTypeHelper stringForDeerHuntingType:DeerHuntingTypeStandHunting]];
        [valueList addObject:[DeerHuntingTypeHelper stringForDeerHuntingType:DeerHuntingTypeDogHunting]];
        [valueList addObject:[DeerHuntingTypeHelper stringForDeerHuntingType:DeerHuntingTypeOther]];

        controller.values = valueList;

        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)saveValuesTo:(ObservationEntry*)entry cleanSpecimens:(BOOL)cleanSpecimens
{
    entry.gameSpeciesCode = self.selectedSpeciesCode;
    entry.observationCategory = [ObservationCategoryHelper categoryStringForCategory:self.selectedObservationCategory];
    // deer hunting type only valid if observation was within deer hunting
    if (self.selectedObservationCategory == ObservationCategoryDeerHunting) {
        // explicitly store DeerHuntingTypeNone as nil. String conversion would probably also produce the same result
        // but intention is more explicit this way.
        entry.deerHuntingType = self.selectedDeerHuntingType != DeerHuntingTypeNone ?
            [DeerHuntingTypeHelper stringForDeerHuntingType:self.selectedDeerHuntingType] : nil;
        // only store type description if it is allowed
        entry.deerHuntingTypeDescription = (self.selectedDeerHuntingType == DeerHuntingTypeOther) ? self.selectedDeerHuntingTypeDescription : nil;
    } else {
        entry.deerHuntingType = nil;
        entry.deerHuntingTypeDescription = nil;
    }
    entry.observationType = self.selectedObservationType;

    entry.mooselikeMaleAmount = self.selectedMooselikeMaleAmount;
    entry.mooselikeFemaleAmount = self.selectedMooselikeFemaleAmount;
    entry.mooselikeFemale1CalfAmount = self.selectedMooselikeFemale1CalfAmount;
    entry.mooselikeFemale2CalfsAmount = self.selectedMooselikeFemale2CalfAmount;
    entry.mooselikeFemale3CalfsAmount = self.selectedMooselikeFemale3CalfAmount;
    entry.mooselikeFemale4CalfsAmount = self.selectedMooselikeFemale4CalfAmount;
    entry.mooselikeCalfAmount = self.selectedMooselikeCalfAmount;
    entry.mooselikeUnknownSpecimenAmount = self.selectedMooselikeUnknownAmount;

    entry.observerName = self.selectedObserverName;
    entry.observerPhoneNumber = self.selectedObserverPhoneNumber;
    entry.officialAdditionalInfo = self.selectedOfficialAdditionalInfo;
    entry.verifiedByCarnivoreAuthority = self.selectedVerifiedByCarnivoreAuthority;

    // Nullifies fields if observation species/type changes
    entry.inYardDistanceToResidence = self.selectedInYardsDistanceFromResidence;
    entry.pack = self.selectedPack;
    entry.litter = self.selectedLitter;

    [self removeExtraSpecimens:[entry.totalSpecimenAmount integerValue] purgeEmpty:cleanSpecimens];
}

#pragma mark - DetailsViewControllerBase

- (void)refreshLocalizedTexts
{
    RiistaLanguageRefresh;

    [self.specimensButton setTitle:RiistaLocalizedString(@"SpecimenDetailsTitle", nil) forState:UIControlStateNormal];
}

- (void)disableUserControls
{
    self.editMode = NO;
}

- (void)setEditMode:(BOOL)editMode
{
    super.editMode = editMode;

    if (editMode) {
        // Value must be empty when saving moose amounts. Prevent creating specimen items.
        if ([self.entry getMooselikeSpecimenCount] > 0) {
            self.entry.totalSpecimenAmount = nil;
        }

        [self generateEmptySpecimensToAmount:[self.entry.totalSpecimenAmount integerValue]];
    }

    [self.speciesButton setEnabled:editMode animated:NO];
    [self.imagesButton setEnabled:(editMode || [imageUtil hasImagesWithEntry:self.entry])];

    [self.dateButton setEnabled:editMode animated:NO];

    self.variableContentContainer.userInteractionEnabled = editMode;
    self.variableContentContainer2.userInteractionEnabled = editMode;

    [self refreshViews];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == SPECIMEN_AMOUNT_TAG) {
        // Need to apply replacement to original string and validate the whole input instead of just changed part
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

        if ([newString length] == 0) {
            return YES;
        }

        NSScanner *sc = [NSScanner scannerWithString:newString];
        NSInteger value;
        if ([sc scanInteger:&value])
        {
            return [sc isAtEnd] && value > 0 && value <= [AppConstants ObservationMaxAmount];
        }

        return NO;
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == SPECIMEN_AMOUNT_TAG) {
        [self changeSpecimenAmount:[textField.text integerValue]];
    }
    else if (textField.tag == MOOSE_AMOUNT_MALE_TAG) {
        self.selectedMooselikeMaleAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_FEMALE_TAG) {
        self.selectedMooselikeFemaleAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_FEMALE1_TAG) {
        self.selectedMooselikeFemale1CalfAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_FEMALE2_TAG) {
        self.selectedMooselikeFemale2CalfAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_FEMALE3_TAG) {
        self.selectedMooselikeFemale3CalfAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_FEMALE4_TAG) {
        self.selectedMooselikeFemale4CalfAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_CALF_TAG) {
        self.selectedMooselikeCalfAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == MOOSE_AMOUNT_UNKNOWN_TAG) {
        self.selectedMooselikeUnknownAmount = [NSNumber numberWithInteger:[textField.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textField.tag == OBSERVATION_DEER_HUNTING_TYPE_DESCRIPTION_TAG) {
        self.selectedDeerHuntingTypeDescription = textField.text;
        [self selectedValuesChanged];
    }
}

#pragma mark - Connections

- (IBAction)speciesButtonClick:(id)sender
{
    if (self.editMode) {
        self.dialogTransitionController = [[MDCDialogTransitionController alloc] init];

        SpeciesCategoryDialogController *dialogController = [SpeciesCategoryDialogController new];
        dialogController.modalPresentationStyle = UIModalPresentationCustom;
        dialogController.transitioningDelegate = self.dialogTransitionController;

        dialogController.completionHandler = ^(NSInteger categoryCode) {
            if (categoryCode >= 1 && categoryCode <= 3) {
                RiistaSpeciesSelectViewController *speciesController = [self.storyboard instantiateViewControllerWithIdentifier:@"speciesSelectController"];
                speciesController.delegate = self;
                speciesController.category = self.categoryList[categoryCode - 1];

                [self.navigationController pushViewController:speciesController animated:YES];
            }
        };

        [self presentViewController:dialogController animated:YES completion:nil];
    }
}

- (IBAction)imagesButtonClick:(id)sender
{
    if (self.editMode) {
        [imageUtil editImageWithPickerDelegate:(id<ImageEditUtilDelegate>)self.parentViewController];
    }
    else if ([imageUtil hasImagesWithEntry:self.entry]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ImageFullViewController *dest = (ImageFullViewController*)[sb instantiateViewControllerWithIdentifier:@"ImageFullController"];
        dest.item = self.entry;

        UIStoryboardSegue *seque = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:dest performHandler:^{
            [self.navigationController pushViewController:dest animated:YES];
        }];

        [seque perform];
    }
}

- (IBAction)dateButtonClick:(id)sender
{
    [self.delegate showDateTimePicker];
}

- (IBAction)specimensButtonClick:(id)sender
{
    [self.delegate navigateToSpecimens];
}

#pragma mark - SpeciesSelectionDelegate

- (void)speciesSelected:(RiistaSpecies *)species
{
    self.selectedSpeciesCode = [NSNumber numberWithInteger:species.speciesId];
    self.selectedObservationType = nil;
    self.selectedObservationCategory = ObservationCategoryNormal;
    self.entry.totalSpecimenAmount = nil;
    self.selectedMooselikeFemaleAmount = nil;
    self.selectedMooselikeFemale1CalfAmount = nil;
    self.selectedMooselikeFemale2CalfAmount = nil;
    self.selectedMooselikeFemale3CalfAmount = nil;
    self.selectedMooselikeFemale4CalfAmount = nil;
    self.selectedMooselikeMaleAmount = nil;
    self.selectedMooselikeCalfAmount = nil;
    self.selectedMooselikeUnknownAmount = nil;

    self.selectedObserverName = nil;
    self.selectedObserverPhoneNumber = nil;
    self.selectedOfficialAdditionalInfo = nil;
    self.selectedVerifiedByCarnivoreAuthority = nil;

    self.selectedInYardsDistanceFromResidence = nil;
    self.selectedPack = nil;
    self.selectedLitter = nil;

    [self selectedValuesChanged];
}

#pragma mark - ValueSelectionDelegate

- (void)valueSelectedForKey:(NSString *)key value:(NSString *)value
{
    if ([key isEqualToString:OBSERVATION_TYPE_KEY]) {
        [self changeObservationType:value];
    } else if ([key isEqualToString:DEER_HUNTING_TYPE_KEY]) {
        [self changeDeerHuntingType:value];
    }
}

@end
