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
#import "RiistaViewUtils.h"
#import "UIColor+ApplicationColor.h"
#import "ValueListViewController.h"
#import "M13Checkbox.h"
#import "KeyboardToolbarView.h"

@interface ObservationDetailsViewController () <SpeciesSelectionDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, ValueSelectionDelegate>

@property (weak, nonatomic) IBOutlet UIView *speciesView;
@property (weak, nonatomic) IBOutlet UIImageView *speciesImageView;

@property (weak, nonatomic) IBOutlet UILabel *speciesNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speciesMandatoryLabel;

@property (weak, nonatomic) IBOutlet UIButton *specimenDetailsButton;
@property (weak, nonatomic) IBOutlet UILabel *specimenDetailsLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *specimenDetailsButtonHeight;

@property (weak, nonatomic) IBOutlet UIView *variableContentContainer;

@property (strong, nonatomic) NSMutableArray<RiistaSpeciesCategory*> *categoryList;

@property (strong, nonatomic) UITapGestureRecognizer *speciesTapRecognizer;
@property (strong, nonatomic) UIAlertView *speciesSelectionAlertView;

@end

static CGFloat const FIELD_HEIGHT_SMALL = 43.0;

static NSInteger const DIALOG_TAG_CATEGORY = 20;

static CGFloat const VERTICAL_SPACING = 8.0;
static CGFloat const LEFT_MARGIN = 17.0;
static CGFloat const RIGHT_MARGIN = 15.0;

static NSString * const OBSERVATION_TYPE_KEY = @"ObservationTypeKey";
static NSInteger const SPECIMEN_AMOUNT_TAG = 201;
static NSInteger const MOOSE_AMOUNT_MALE_TAG = 202;
static NSInteger const MOOSE_AMOUNT_FEMALE_TAG = 203;
static NSInteger const MOOSE_AMOUNT_FEMALE1_TAG = 204;
static NSInteger const MOOSE_AMOUNT_FEMALE2_TAG = 205;
static NSInteger const MOOSE_AMOUNT_FEMALE3_TAG = 206;
static NSInteger const MOOSE_AMOUNT_FEMALE4_TAG = 207;
static NSInteger const MOOSE_AMOUNT_UNKNOWN_TAG = 208;

@implementation ObservationDetailsViewController

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

    [RiistaViewUtils addTopAndBottomBorders:self.speciesView];
    [RiistaViewUtils addTopAndBottomBorders:self.specimenDetailsButton];
    [self.specimenDetailsButton setBackgroundImage:[RiistaUtils imageWithColor:[UIColor applicationColor:RiistaApplicationColorWhiteButtonHilight] width:1 height:1]
                                          forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refreshLocalizedTexts];
    [self selectedValuesChanged];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (self.speciesSelectionAlertView) {
        [self.speciesSelectionAlertView dismissWithClickedButtonIndex:self.speciesSelectionAlertView.cancelButtonIndex animated:YES];
    }
}

- (void)dealloc
{
    self.speciesSelectionAlertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public interface

- (CGFloat)refreshViews
{
    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.selectedSpeciesCode integerValue]];
    if (!species) {
        self.speciesNameLabel.text = RiistaLocalizedString(@"ChooseSpecies", nil);
        self.speciesImageView.image = nil;
        self.speciesMandatoryLabel.hidden = NO;
    }
    else {
        self.speciesNameLabel.text = [RiistaUtils nameWithPreferredLanguage:species.name];
        self.speciesImageView.image = [RiistaUtils loadSpeciesImage:species.speciesId];
        self.speciesMandatoryLabel.hidden = YES;
    }

    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:species.speciesId];

    [self resetObservationViews:metadata];

    //Calculate and return content height
    CGFloat y = 0;
    for (UIView *view in [self.variableContentContainer subviews]) {
        y = MAX(y, view.frame.origin.y + view.frame.size.height);

        if (!self.specimenDetailsButton.hidden) {
            y += self.specimenDetailsButton.frame.size.height + 6.0;
        }
    }
    return y;
}

#pragma mark -

// Clear existing specimens and replace with empty
- (void)resetSpecimensToAmount:(NSInteger)amount
{
    if (!self.editMode) {
        DLog(@"Tried to reset specimens while not editing");
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
        DLog(@"Tried to generate specimens while not editing");
        return;
    }

    if (amount > DiaryEntrySpecimenDetailsMax) {
        DLog(@"Trying to generate specimens to %ld", amount);
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
        DLog(@"Tried to remove specimens while not editing");
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

- (void)changeObservationType:(NSString*)type
{
    self.selectedObservationType = type;

    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:[self.selectedSpeciesCode integerValue]];

    if (metadata && [metadata hasBaseFieldSet:@"withinMooseHunting"]) {
        self.selectedWithinMooseHunting = [self.selectedWithinMooseHunting boolValue] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    }
    else {
        self.selectedWithinMooseHunting = nil;
    }

    ObservationContextSensitiveFieldSets *field = [metadata findFieldSetByType:type withinMooseHunting:[self.selectedWithinMooseHunting boolValue]];
    if (field != nil && [field hasFieldSet:field.baseFields name:@"amount"]) {
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
    self.selectedMooselikeUnknownAmount = nil;

    [self resetSpecimensToAmount:[self.entry.totalSpecimenAmount integerValue]];
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
    self.specimenDetailsButton.hidden = YES;
    self.specimenDetailsButtonHeight.constant = 0.0;

    if (metadata) {
        if ([metadata hasBaseFieldSet:@"withinMooseHunting"]) {
            [self createMooseHuntingChoice];
        }

        [self createObservationTypeChoiceView:metadata];
        [self createAmountChoiceView:metadata];
        [self createMooselikeChoiceViews:metadata];

        ObservationContextSensitiveFieldSets *field = [metadata findFieldSetByType:self.selectedObservationType withinMooseHunting:[self.selectedWithinMooseHunting boolValue]];

        // Hack to hide for mooselike species
        if (![field requiresMooselikeAmounts:field.baseFields] &&
            [self.entry.totalSpecimenAmount integerValue] > 0 &&
            [self.entry.totalSpecimenAmount integerValue] <= DiaryEntrySpecimenDetailsMax &&
            [field.specimenFields count] > 0)
        {
            self.specimenDetailsButton.hidden = NO;
            self.specimenDetailsButtonHeight.constant = FIELD_HEIGHT_SMALL;
        }
    }

    [self.specimenDetailsButton setNeedsLayout];
    [self.specimenDetailsButton layoutIfNeeded];
}

- (void)createMooseHuntingChoice
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0, VERTICAL_SPACING, self.variableContentContainer.frame.size.width, FIELD_HEIGHT_SMALL)];
    container.backgroundColor = [UIColor whiteColor];
    [RiistaViewUtils addTopAndBottomBorders:container];

    M13Checkbox *checkbox = [[M13Checkbox alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0.0, container.frame.size.width - LEFT_MARGIN - RIGHT_MARGIN, FIELD_HEIGHT_SMALL)
                                                         title:RiistaLocalizedString(@"ObservationDetailsWithinMooseHunting", nil)
                                                   checkHeight:20.0f];
    [checkbox setStrokeColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [checkbox setCheckColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground]];

    checkbox.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    checkbox.checkState = [self.selectedWithinMooseHunting boolValue] ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;

    [checkbox addTarget:self action:@selector(mooseHuntingCheckboxDidChange:) forControlEvents:UIControlEventValueChanged];

    [container addSubview:checkbox];
    [self.variableContentContainer addSubview:container];
}

- (void)mooseHuntingCheckboxDidChange:(M13Checkbox*)sender
{
    if (sender.checkState == M13CheckboxStateChecked) {
        self.selectedWithinMooseHunting = [NSNumber numberWithBool:YES];
    }
    else {
        self.selectedWithinMooseHunting = [NSNumber numberWithBool:NO];
    }

    [self changeObservationType:nil];
}

- (void)createObservationTypeChoiceView:(ObservationSpecimenMetadata *)metadata
{
    NSMutableArray<NSString*> *types = [NSMutableArray new];
    for (ObservationContextSensitiveFieldSets *field in metadata.contextSensitiveFieldSets) {
        BOOL withinMooseHunting = (self.selectedWithinMooseHunting != nil) && self.selectedWithinMooseHunting;

        if (field.withinMooseHunting == withinMooseHunting) {
            [types addObject:field.type];
        }
    }

    UIView *lastChild = [self.variableContentContainer.subviews lastObject];
    CGFloat yCoord = lastChild.frame.origin.y + lastChild.frame.size.height;

    RiistaValueListButton *control = [[RiistaValueListButton alloc] initWithFrame:CGRectMake(0, yCoord + VERTICAL_SPACING, self.variableContentContainer.frame.size.width, 63)];
    [RiistaViewUtils addTopAndBottomBorders:control];
    control.backgroundColor = [UIColor whiteColor];
    control.titleText = RiistaLocalizedString(@"ObservationDetailsType", nil);
    control.valueText = RiistaMappedValueString(self.selectedObservationType, nil);

    [control addTarget:self action:@selector(onObservationTypeClick) forControlEvents:UIControlEventTouchUpInside];

    [RiistaViewUtils addTopAndBottomBorders:control];
    [self.variableContentContainer addSubview:control];
}

- (void)createAmountChoiceView:(ObservationSpecimenMetadata *)metadata
{
    ObservationContextSensitiveFieldSets *fields = [metadata findFieldSetByType:self.selectedObservationType withinMooseHunting:[self.selectedWithinMooseHunting boolValue]];
    if (fields != nil) {
        if ([fields hasFieldSet:fields.baseFields name:@"amount"]) {
            NSInteger amount = 0;
            if (self.entry.totalSpecimenAmount) {
                amount = [self.entry.totalSpecimenAmount integerValue];
            }

            amount = MAX(amount, 1);

            self.entry.totalSpecimenAmount = [NSNumber numberWithInteger:amount];

            UIView *lastChild = [self.variableContentContainer.subviews lastObject];
            CGFloat yCoord = lastChild.frame.origin.y + lastChild.frame.size.height;

            RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"Amount", nil)
                                                                  value:[self.entry.totalSpecimenAmount stringValue]
                                                                      y:yCoord + VERTICAL_SPACING
                                                                   grow:0];
            item.maxNumberValue = [NSNumber numberWithInt:999];
            item.textView.tag = SPECIMEN_AMOUNT_TAG;
            item.textView.keyboardType = UIKeyboardTypeNumberPad;
            item.textView.delegate = self;

            [self.variableContentContainer addSubview:item];
        }
        else {

        }
    }
}

- (void)createMooselikeChoiceViews:(ObservationSpecimenMetadata *)metadata
{
    ObservationContextSensitiveFieldSets *fields = [metadata findFieldSetByType:self.selectedObservationType withinMooseHunting:[self.selectedWithinMooseHunting boolValue]];
    if (fields == nil) {
        return;
    }

    UIView *lastChild = [self.variableContentContainer.subviews lastObject];
    CGFloat yCoord = lastChild.frame.origin.y + lastChild.frame.size.height + VERTICAL_SPACING;
    NSInteger const H = 70;
    NSInteger addedFields = 0;

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeMaleAmount"]) {
        if (self.selectedMooselikeMaleAmount == nil) {
            self.selectedMooselikeMaleAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseMale", nil)
                                                               value:[self.selectedMooselikeMaleAmount stringValue]
                                                                   y:yCoord + H * addedFields
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_MALE_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeFemaleAmount"]) {
        if (self.selectedMooselikeFemaleAmount == nil) {
            self.selectedMooselikeFemaleAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseFemale", nil)
                                                               value:[self.selectedMooselikeFemaleAmount stringValue]
                                                                   y:(yCoord + H * addedFields)
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_FEMALE_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeFemale1CalfAmount"]) {
        if (self.selectedMooselikeFemale1CalfAmount == nil) {
            self.selectedMooselikeFemale1CalfAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseFemale1Calf", nil)
                                                               value:[self.selectedMooselikeFemale1CalfAmount stringValue]
                                                                   y:(yCoord + H * addedFields)
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_FEMALE1_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeFemale2CalfsAmount"]) {
        if (self.selectedMooselikeFemale2CalfAmount == nil) {
            self.selectedMooselikeFemale2CalfAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseFemale2Calf", nil)
                                                               value:[self.selectedMooselikeFemale2CalfAmount stringValue]
                                                                   y:(yCoord + H * addedFields)
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_FEMALE2_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeFemale3CalfsAmount"]) {
        if (self.selectedMooselikeFemale3CalfAmount == nil) {
            self.selectedMooselikeFemale3CalfAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseFemale3Calf", nil)
                                                               value:[self.selectedMooselikeFemale3CalfAmount stringValue]
                                                                   y:(yCoord + H * addedFields)
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_FEMALE3_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeFemale4CalfsAmount"]) {
        if (self.selectedMooselikeFemale4CalfAmount == nil) {
            self.selectedMooselikeFemale4CalfAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseFemale4Calf", nil)
                                                               value:[self.selectedMooselikeFemale4CalfAmount stringValue]
                                                                   y:(yCoord + H * addedFields)
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_FEMALE4_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }

    if ([fields hasFieldSet:fields.baseFields name:@"mooselikeUnknownSpecimenAmount"]) {
        if (self.selectedMooselikeUnknownAmount == nil) {
            self.selectedMooselikeUnknownAmount = @0;
        }

        RiistaValueListTextField * view = [self createMooseTextField:RiistaLocalizedString(@"ObservationDetailsMooseUnknown", nil)
                                                               value:[self.selectedMooselikeUnknownAmount stringValue]
                                                                   y:(yCoord + H * addedFields)
                                                                grow:0];
        view.textView.tag = MOOSE_AMOUNT_UNKNOWN_TAG;
        view.maxNumberValue = [NSNumber numberWithInt:50];
        view.delegate = self;
        [self.variableContentContainer addSubview:view];
        ++addedFields;
    }
}

- (RiistaValueListTextField*)createMooseTextField:(NSString*)name value:(NSString*)value y:(int)y grow:(int)grow
{
    RiistaValueListTextField *control = [[RiistaValueListTextField alloc] initWithFrame:CGRectMake(0, y, self.variableContentContainer.frame.size.width, 63 + grow)];
    control.backgroundColor = [UIColor whiteColor];
    control.textView.editable = YES;
    control.textView.scrollEnabled = NO;
    control.textView.inputAccessoryView = [KeyboardToolbarView textViewDoneToolbarView:control.textView];
    control.titleTextLabel.text = name;
    if (value == nil) {
        control.textView.text = @"";
    }
    else {
        control.textView.text = value;
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
            if (fieldSet.withinMooseHunting == [self.selectedWithinMooseHunting boolValue]) {
                [valueList addObject:fieldSet.type];
            }
        }

        controller.values = valueList;

        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)saveValuesTo:(ObservationEntry*)entry cleanSpecimens:(BOOL)cleanSpecimens
{
    entry.gameSpeciesCode = self.selectedSpeciesCode;
    entry.withinMooseHunting = self.selectedWithinMooseHunting;
    entry.observationType = self.selectedObservationType;

    entry.mooselikeMaleAmount = self.selectedMooselikeMaleAmount;
    entry.mooselikeFemaleAmount = self.selectedMooselikeFemaleAmount;
    entry.mooselikeFemale1CalfAmount = self.selectedMooselikeFemale1CalfAmount;
    entry.mooselikeFemale2CalfsAmount = self.selectedMooselikeFemale2CalfAmount;
    entry.mooselikeFemale3CalfsAmount = self.selectedMooselikeFemale3CalfAmount;
    entry.mooselikeFemale4CalfsAmount = self.selectedMooselikeFemale4CalfAmount;
    entry.mooselikeUnknownSpecimenAmount = self.selectedMooselikeUnknownAmount;

    [self removeExtraSpecimens:[entry.totalSpecimenAmount integerValue] purgeEmpty:cleanSpecimens];
}

#pragma mark - DetailsViewControllerBase

- (void)refreshLocalizedTexts
{
    RiistaLanguageRefresh;

    self.specimenDetailsLabel.text = RiistaLocalizedString(@"SpecimenDetailsTitle", nil);
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

    self.speciesView.userInteractionEnabled = editMode;
    self.variableContentContainer.userInteractionEnabled = editMode;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];

    if ([newString length] == 0) {
        return YES;
    }

    NSScanner *sc = [NSScanner scannerWithString:newString];
    NSInteger value;
    if ([sc scanInteger:&value])
    {
        return [sc isAtEnd] && value > 0 && value <= 999;
    }

    return NO;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView selectAll:nil];
    });
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView.tag == SPECIMEN_AMOUNT_TAG) {
        [self changeSpecimenAmount:[textView.text integerValue]];
    }
    else if (textView.tag == MOOSE_AMOUNT_MALE_TAG) {
        self.selectedMooselikeMaleAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textView.tag == MOOSE_AMOUNT_FEMALE_TAG) {
        self.selectedMooselikeFemaleAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textView.tag == MOOSE_AMOUNT_FEMALE1_TAG) {
        self.selectedMooselikeFemale1CalfAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textView.tag == MOOSE_AMOUNT_FEMALE2_TAG) {
        self.selectedMooselikeFemale2CalfAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textView.tag == MOOSE_AMOUNT_FEMALE3_TAG) {
        self.selectedMooselikeFemale3CalfAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textView.tag == MOOSE_AMOUNT_FEMALE4_TAG) {
        self.selectedMooselikeFemale4CalfAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
    else if (textView.tag == MOOSE_AMOUNT_UNKNOWN_TAG) {
        self.selectedMooselikeUnknownAmount = [NSNumber numberWithInteger:[textView.text integerValue]];
        [self selectedValuesChanged];
    }
}

#pragma mark - Connections

- (IBAction)speciesButtonClick:(id)sender
{
    if (!self.editMode) {
        return;
    }
    UIAlertView *alertView = [UIAlertView new];
    alertView.title = RiistaLocalizedString(@"ChooseSpecies", nil);
    alertView.delegate = self;
    for (RiistaSpeciesCategory* item in self.categoryList) {
        [alertView addButtonWithTitle:[RiistaUtils nameWithPreferredLanguage:item.name]];
    }
    [alertView addButtonWithTitle:RiistaLocalizedString(@"CancelRemove", nil)];
    alertView.cancelButtonIndex = self.categoryList.count;

    alertView.tag = DIALOG_TAG_CATEGORY;
    [alertView show];
}

- (IBAction)specimensButtonClick:(id)sender
{
    [self.delegate navigateToSpecimens];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DIALOG_TAG_CATEGORY) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            RiistaSpeciesSelectViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"speciesSelectController"];
            controller.delegate = self;
            controller.category = self.categoryList[buttonIndex];
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

#pragma mark - SpeciesSelectionDelegate

- (void)speciesSelected:(RiistaSpecies *)species
{
    self.selectedSpeciesCode = [NSNumber numberWithInteger:species.speciesId];
    self.selectedObservationType = nil;
    self.selectedWithinMooseHunting = nil;
    self.entry.totalSpecimenAmount = nil;
    self.selectedMooselikeFemaleAmount = nil;
    self.selectedMooselikeFemale1CalfAmount = nil;
    self.selectedMooselikeFemale2CalfAmount = nil;
    self.selectedMooselikeFemale3CalfAmount = nil;
    self.selectedMooselikeFemale4CalfAmount = nil;
    self.selectedMooselikeMaleAmount = nil;
    self.selectedMooselikeUnknownAmount = nil;

    [self selectedValuesChanged];
}

#pragma mark - ValueSelectionDelegate

- (void)valueSelectedForKey:(NSString *)key value:(NSString *)value
{
    if ([key isEqualToString:OBSERVATION_TYPE_KEY]) {
        [self changeObservationType:value];
    }
}

@end
