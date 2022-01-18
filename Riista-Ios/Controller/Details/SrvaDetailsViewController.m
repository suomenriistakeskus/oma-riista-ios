#import "RiistaLocalization.h"
#import "SrvaDetailsViewController.h"
#import "RiistaViewUtils.h"
#import "RiistaUtils.h"
#import "RiistaSpecies.h"
#import "RiistaGameDatabase.h"
#import "SrvaEntry.h"
#import "SrvaSpecimen.h"
#import "RiistaValueListTextField.h"
#import "RiistaValueListButton.h"
#import "RiistaMetadataManager.h"
#import "SrvaMetadata.h"
#import "SrvaEventMetadata.h"
#import "SrvaMethod.h"
#import "M13Checkbox.h"
#import "ValueListViewController.h"
#import "RiistaSpeciesSelectViewController.h"
#import "SrvaSpecimensViewController.h"
#import "UIColor+ApplicationColor.h"
#import "KeyboardToolbarView.h"

#import "Oma_riista-Swift.h"

static NSString * const EVENT_NAME_KEY = @"EventNameKey";
static NSString * const EVENT_TYPE_KEY = @"EventTypeKey";
static NSString * const EVENT_RESULT_KEY = @"EventResultKey";

static NSInteger const TAG_SPECIES_OTHER = 100;
static NSInteger const TAG_TYPE_OTHER = 101;
static NSInteger const TAG_METHOD_OTHER = 102;
static NSInteger const TAG_PERSON_COUNT = 103;
static NSInteger const TAG_TIME_SPENT = 104;

static CGFloat const LEFT_MARGIN = 12;

@interface SrvaDetailsViewController () <UITextFieldDelegate, ValueSelectionDelegate, SpeciesSelectionDelegate, SrvaSpecimensUpdatedDelegate>

@property (weak, nonatomic) IBOutlet MDCButton *speciesButton;
@property (weak, nonatomic) IBOutlet MDCButton *imagesButton;

@property (weak, nonatomic) IBOutlet MDCButton *dateButton;

@property (weak, nonatomic) IBOutlet UILabel *amountTitle;
@property (weak, nonatomic) IBOutlet MDCTextField *amountTextField;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;

@property (weak, nonatomic) IBOutlet UIView *specimensView;
@property (weak, nonatomic) IBOutlet MDCButton *specimensButton;

@property (weak, nonatomic) IBOutlet UIStackView *contentView;

@property (strong, nonatomic) MDCTextInputControllerUnderline *amountInputController;

@property (strong, nonatomic) NSMutableArray<NSString*> *activeMethodNames;

@end

@implementation SrvaDetailsViewController
{
    ImageEditUtil *imageUtil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    imageUtil = [[ImageEditUtil alloc] initWithParentController:self];

    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.amountInputController = [AppTheme.shared setupAmountTextFieldWithTextField:self.amountTextField delegate:self];

    RiistaLanguageRefresh;
    _amountTitle.text = RiistaLocalizedString(@"Amount", nil);
    self.amountLabel.text = RiistaLocalizedString(@"EntryDetailsAmountShort", nil);

    [self.specimensButton setTitle:RiistaLocalizedString(@"SpecimenDetailsTitle", nil) forState:UIControlStateNormal];

    [AppTheme.shared setupSpeciesButtonThemeWithButton:self.speciesButton];
    [AppTheme.shared setupImagesButtonThemeWithButton:self.imagesButton];
    [AppTheme.shared setupPrimaryButtonThemeWithButton:self.specimensButton];

    [AppTheme.shared setupTextButtonThemeWithButton:self.dateButton];

    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - DetailsViewControllerBase

- (void)refreshLocalizedTexts
{
    RiistaLanguageRefresh;

//    self.specimenDetailsLabel.text = RiistaLocalizedString(@"SpecimenDetailsTitle", nil);
}

- (void)disableUserControls
{
    self.imagesButton.enabled = false;
}

- (void)setEditMode:(BOOL)editMode
{
    super.editMode = editMode;

    [self.speciesButton setEnabled:editMode];
    [self.imagesButton setEnabled:(editMode || [imageUtil hasImagesWithEntry:self.srva])];

    self.amountTextField.enabled = self.editMode;

    [self.dateButton setEnabled:editMode animated:NO];

    self.contentView.userInteractionEnabled = editMode;

    [self refreshViews];
}

- (void)refreshDateTime:(NSString *)dateTimeString
{
    [self.dateButton setTitle:dateTimeString forState:UIControlStateNormal];
}

- (IBAction)specimenDetailsButtonClick:(id)sender
{
    [self saveValues];

    SrvaSpecimensViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"srvaSpecimensPageController"];
    controller.delegate = self;
    controller.editContext = self.editContext;
    controller.editMode = self.editMode && [self.srva isEditable];
    controller.srva = self.srva;

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)specimenCountChanged
{
    [self updateSpecimenAmount:self.srva.specimens.count];
}

- (IBAction)speciesButtonClick:(id)sender
{
    if (!self.editMode) {
        return;
    }
    SrvaMetadata* metadata = [[RiistaMetadataManager sharedInstance] getSrvaMetadata];

    RiistaSpeciesSelectViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"speciesSelectController"];
    controller.delegate = self;
    controller.values = metadata.species;
    controller.showOther = [NSNumber numberWithBool:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)imagesButtonClick:(id)sender
{
    if (self.editMode) {
        DetailsViewController *parentVC = (DetailsViewController*)self.parentViewController;
        [imageUtil editImageWithPickerDelegate:(id<RiistaImagePickerDelegate>)parentVC];
    }
    else if ([imageUtil hasImagesWithEntry:self.srva]) {
        if (self.imagesButton.imageLoadStatus == LoadStatusFailure) {
            ImageLoadRequest *loadRequest = [ImageLoadRequest fromDiaryImage:self.diaryImage
                                                                     options:[ImageLoadOptions aspectFilledWithSize:CGSizeMake(50.f, 50.f)]];

            [imageUtil displayImageLoadFailedDialog:(id<RiistaImagePickerDelegate>)self.parentViewController
                                             reason:self.imagesButton.imageLoadFailureReason
                                   imageLoadRequest:loadRequest
                         allowAnotherPhotoSelection:NO];

            return;
        }

        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ImageFullViewController *dest = (ImageFullViewController*)[sb instantiateViewControllerWithIdentifier:@"ImageFullController"];
        dest.item = self.srva;

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

- (void)saveValues
{
    [self updateSpecimenAmount:[self.amountTextField.text integerValue]];

    RiistaValueListTextField* speciesOtherItem = [self.contentView viewWithTag:TAG_SPECIES_OTHER];
    if (self.srva.gameSpeciesCode == nil && speciesOtherItem) {
        self.srva.otherSpeciesDescription = speciesOtherItem.textField.text;
    }

    RiistaValueListTextField* typeOtherItem = [self.contentView viewWithTag:TAG_TYPE_OTHER];
    if ([self.srva.eventType isEqualToString:@"OTHER"] && typeOtherItem) {
        self.srva.otherTypeDescription = typeOtherItem.textField.text;
    }

    RiistaValueListTextField* methodOtherItem = [self.contentView viewWithTag:TAG_METHOD_OTHER];
    if ([self isMehodOtherChecked] && methodOtherItem) {
        self.srva.otherMethodDescription = methodOtherItem.textField.text;
    }

    RiistaValueListTextField* personsItem = [self.contentView viewWithTag:TAG_PERSON_COUNT];
    self.srva.personCount = @([personsItem.textField.text integerValue]);

    RiistaValueListTextField* timeItem = [self.contentView viewWithTag:TAG_TIME_SPENT];
    self.srva.timeSpent = @([timeItem.textField.text integerValue]);
}

- (void)updateSpecimenAmount:(NSInteger)amount
{
    if (amount < 1) {
        amount = 1;
    }
    NSMutableOrderedSet* specimens = [NSMutableOrderedSet new];

    if (self.srva.specimens) {
        for (SrvaSpecimen* specimen in self.srva.specimens) {
            [specimens addObject:specimen];
        }
    }

    for (NSUInteger i = specimens.count; i < amount; ++i) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SrvaSpecimen" inManagedObjectContext:self.srva.managedObjectContext];
        SrvaSpecimen *newSpecimen = (SrvaSpecimen*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.srva.managedObjectContext];
        [specimens addObject:newSpecimen];
    }

    while (specimens.count > amount) {
        NSUInteger index = specimens.count - 1;
        SrvaSpecimen* specimen = specimens[index];
        [specimens removeObjectAtIndex:index];
        [self.srva removeSpecimensObject:specimen];
        [specimen.managedObjectContext deleteObject:specimen];
    }

    self.srva.specimens = specimens;
    self.srva.totalSpecimenAmount = @(self.srva.specimens.count);

    self.amountTextField.text = [self.srva.totalSpecimenAmount stringValue];
}

- (void)speciesSelected:(RiistaSpecies*)species
{
    if (species.speciesId == -1) {
        //Other
        self.srva.gameSpeciesCode = nil;
        self.srva.otherSpeciesDescription = @"";
    }
    else {
        self.srva.gameSpeciesCode = [NSNumber numberWithInteger:species.speciesId];
        self.srva.otherSpeciesDescription = nil;
    }
    [self updateViews];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [self.amountTextField.text stringByReplacingCharactersInRange:range withString:string];
    if ([newString length] > 3) {
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [textField selectAll:nil];
    });
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateViews];
}

- (void)removeAllContentViews
{
    [[self.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (RiistaValueListButton*)createChoice:(NSString*)name value:(NSString*)value
{
    RiistaValueListButton *control = [[RiistaValueListButton alloc]
                                      initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, RiistaDefaultValueElementHeight)];
    control.backgroundColor = [UIColor whiteColor];
    control.enabled = self.editMode;
    control.titleText = name;
    if (value == nil) {
        control.valueText = @"";
    }
    else {
        control.valueText = value;
    }
    return control;
}

- (RiistaValueListTextField*)createTextField:(NSString*)name value:(NSString*)value
{
    RiistaValueListTextField *control = [[RiistaValueListTextField alloc]
                                         initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, RiistaDefaultValueElementHeight)];
    control.delegate = self;
    control.backgroundColor = [UIColor whiteColor];
    control.textField.enabled = self.editMode;
    control.titleTextLabel.text = name;
    if (value == nil) {
        control.textField.text = @"";
    }
    else {
        control.textField.text = value;
    }
    return control;
}

- (void)updateViews
{
    [self.delegate valuesUpdated:self];
}

- (CGFloat)refreshViews
{
    [self removeAllContentViews];
    [self updateSpeciesSelection];

    [self updateSpecimenAmount:[self.srva.totalSpecimenAmount integerValue]];

    [self refreshImage];

    if (self.srva.gameSpeciesCode == nil && self.srva.otherSpeciesDescription != nil) {
        [self createOtherSpeciesInput];
    }
    else {
        self.srva.otherSpeciesDescription = nil;
    }

    if (self.srva.gameSpeciesCode != nil || self.srva.otherSpeciesDescription != nil) {
        self.specimensView.hidden = NO;
    }
    else {
        self.specimensView.hidden = YES;
    }

    if ([self.srva.state isEqualToString:SrvaStateApproved] || [self.srva.state isEqualToString:SrvaStateRejected]) {
        [self createApproverInfoView];
    }

    [self createEventNameChoice];

    if (self.srva.eventName != nil) {
        [self createEventTypeChoice];
    }

    if ([self.srva.eventType isEqualToString:@"OTHER"]) {
        [self createEventOtherInput];
    }
    else {
        self.srva.otherTypeDescription = nil;
    }

    if (self.srva.eventName != nil) {
        [self createResultChoice];
    }
    else {
        self.srva.eventResult = nil;
    }

    if (self.srva.eventName != nil) {
        [self createMethodChoices];
    }
    else {
        [self.srva putMethods:@[]];
    }

    if ([self isMehodOtherChecked]) {
        [self createMethodOtherInput];
    }
    else {
        self.srva.otherMethodDescription = nil;
    }

    [self createPersonCountInput];

    [self createTimeSpentInput];

    [self.view setNeedsLayout];

    return 0.0;
}

- (void)refreshImage
{
    if (self.diaryImage != nil) {
        [ImageUtils loadDiaryImage:self.diaryImage
                           options:[ImageLoadOptions aspectFilledWithSize:CGSizeMake(50.0f, 50.0f)]
                         onSuccess:^(UIImage * _Nonnull image) {
            [self.imagesButton setImageLoadedSuccessfully];

            [self.imagesButton setBackgroundImage:image forState:UIControlStateNormal];
            [self.imagesButton setImage:nil forState:UIControlStateNormal];
            [self.imagesButton setBorderWidth:0 forState:UIControlStateNormal];
        }
                          onFailure:^(PhotoAccessFailureReason reason) {
            // currently selected image cnnot be loaded. Indicate this to the user
            UIImage *displayedIcon = nil;
            if (!self.editMode) {
                displayedIcon = [[UIImage imageNamed:@"missing-image-error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            } else {
                displayedIcon = [[UIImage imageNamed:@"camera"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            [self.imagesButton setImage:displayedIcon forState:UIControlStateNormal];
            [self.imagesButton setImageTintColor:[UIColor whiteColor] forState:UIControlStateNormal];

            [self.imagesButton setBackgroundImage:nil forState:UIControlStateNormal];
            [self.imagesButton setImageLoadFailedWithReason:reason];
        }];
    }
}

- (void)updateSpeciesSelection
{
    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.srva.gameSpeciesCode integerValue]];
    if (species) {
        [self.speciesButton setTitle:[RiistaUtils nameWithPreferredLanguage:species.name] forState:UIControlStateNormal];

        [self.speciesButton setImage:[ImageUtils loadSpeciesImageWithSpeciesCode:species.speciesId
                                                                            size:CGSizeMake(42.0f, 42.0f)]
                            forState:UIControlStateNormal];
        self.speciesButton.imageView.tintColor = nil;
        [self updateSpeciesButtonForSpecies:species];
    }
    else if (self.srva.otherSpeciesDescription) {
        [self.speciesButton setTitle:RiistaLocalizedString(@"SrvaOtherSpeciesDescription", nil) forState:UIControlStateNormal];
        [self.speciesButton setImage:[[UIImage imageNamed:@"unknown_white"] resizedImageToFitInSize:CGSizeMake(30.0f, 30.0f) scaleIfSmaller:NO] forState:UIControlStateNormal];
        self.speciesButton.imageView.tintColor = [UIColor blackColor];
        [self updateSpeciesButtonForSpecies:nil];
    }
    else {
        [self.speciesButton setTitle:RiistaLocalizedString(@"ChooseSpecies", nil) forState:UIControlStateNormal];
        [self.speciesButton setImage:[[UIImage imageNamed:@"srva_white"] resizedImageToFitInSize:CGSizeMake(30.0f, 30.0f) scaleIfSmaller:NO] forState:UIControlStateNormal];
        self.speciesButton.imageView.tintColor = nil;
        [self updateSpeciesButtonForSpecies:nil];
    }

    if (self.srva.totalSpecimenAmount) {
        self.amountTextField.text = [NSString stringWithFormat:@"%@", self.srva.totalSpecimenAmount];
    }
    else {
        self.amountTextField.text = @"";
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

- (void)createOtherSpeciesInput
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaOtherSpeciesDescription", nil) value:self.srva.otherSpeciesDescription];
    item.maxTextLength = [NSNumber numberWithInteger:255];
    item.textField.keyboardType = UIKeyboardTypeDefault;
    item.textField.returnKeyType = UIReturnKeyDone;
    item.tag = TAG_SPECIES_OTHER;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)createApproverInfoView
{
    UIView *item = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.contentView.frame.size.width, 40)];
    item.backgroundColor = [UIColor whiteColor];

    UIView *status = [[UIView alloc] initWithFrame: CGRectMake(15, 10, 20, 20)];
    status.layer.cornerRadius = status.frame.size.width / 2;
    [item addSubview:status];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(45, 0, item.frame.size.width, 40)];
    if ([self.srva.state isEqualToString:SrvaStateApproved]) {
        status.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusApproved];
        label.text = [RiistaLocalizedString(@"SrvaApprover", nil) stringByAppendingString:[self makeApproverFullName]];
    }
    else if ([self.srva.state isEqualToString:SrvaStateRejected]) {
        status.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusRejected];
        label.text = [RiistaLocalizedString(@"SrvaRejecter", nil) stringByAppendingString:[self makeApproverFullName]];
    }
    [item addSubview:label];

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (NSString*)makeApproverFullName
{
    NSString* name = @" (";
    if (self.srva.approverFirstName) {
        name = [name stringByAppendingString:self.srva.approverFirstName];
    }
    if (self.srva.approverLastName) {
        name = [NSString stringWithFormat:@"%@%@%@", name, @" ", self.srva.approverLastName];
    }
    return [name stringByAppendingString:@")"];
}

static NSString * const INJURED_ANIMAL = @"INJURED_ANIMAL";
static NSString * const SICK_ANIMAL = @"SICK_ANIMAL";

- (void)createEventNameChoice
{
    NSString *name = self.srva.eventName;
    if ([name isEqualToString:INJURED_ANIMAL]) {
        name = SICK_ANIMAL;
    }

    RiistaValueListButton *item = [self createChoice:RiistaLocalizedString(@"SrvaEvent", nil) value:RiistaMappedValueString(name, nil)];
    [item addTarget:self action:@selector(onEventNameClicked:) forControlEvents:UIControlEventTouchUpInside];

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)onEventNameClicked:(id)sender
{
    SrvaMetadata* metadata = [[RiistaMetadataManager sharedInstance] getSrvaMetadata];
    NSMutableArray *values = [NSMutableArray new];
    for (SrvaEventMetadata *event in metadata.events) {
        [values addObject:event.name];
    }
    [self showValueSelect:EVENT_NAME_KEY title:RiistaLocalizedString(@"SrvaEvent", nil) values:values overrides:@{INJURED_ANIMAL: SICK_ANIMAL}];
}

- (void)createEventTypeChoice
{
    RiistaValueListButton *item = [self createChoice:RiistaLocalizedString(@"SrvaType", nil) value:RiistaMappedValueString(self.srva.eventType, nil)];
    [item addTarget:self action:@selector(onEventTypeClicked:) forControlEvents:UIControlEventTouchUpInside];

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)onEventTypeClicked:(id)sender
{
    SrvaMetadata* metadata = [[RiistaMetadataManager sharedInstance] getSrvaMetadata];
    NSMutableArray *values = [NSMutableArray new];
    for (SrvaEventMetadata *event in metadata.events) {
        if ([event.name isEqualToString:self.srva.eventName]) {
            [values addObjectsFromArray:event.types];
            break;
        }
    }
    [self showValueSelect:EVENT_TYPE_KEY title:RiistaLocalizedString(@"SrvaType", nil) values:values overrides:nil];
}

- (void)createEventOtherInput
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaTypeDescription", nil) value:self.srva.otherTypeDescription];
    item.textField.keyboardType = UIKeyboardTypeDefault;
    item.textField.returnKeyType = UIReturnKeyDone;
    item.tag = TAG_TYPE_OTHER;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)createResultChoice
{
    RiistaValueListButton *item = [self createChoice:RiistaLocalizedString(@"SrvaResult", nil) value:RiistaMappedValueString(self.srva.eventResult, nil)];
    [item addTarget:self action:@selector(onEventResultClicked:) forControlEvents:UIControlEventTouchUpInside];

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)onEventResultClicked:(id)sender
{
    SrvaMetadata* metadata = [[RiistaMetadataManager sharedInstance] getSrvaMetadata];
    NSMutableArray *values = [NSMutableArray new];
    for (SrvaEventMetadata *event in metadata.events) {
        if ([event.name isEqualToString:self.srva.eventName]) {
            [values addObjectsFromArray:event.results];
            break;
        }
    }
    [self showValueSelect:EVENT_RESULT_KEY title:RiistaLocalizedString(@"SrvaResult", nil) values:values overrides:nil];
}

- (void)createMethodChoices
{
    CGFloat contentViewWidth = self.contentView.frame.size.width;
    UIView *item = [[UIView alloc] initWithFrame: CGRectMake(0, 0, contentViewWidth, 50)];
    item.backgroundColor = [UIColor whiteColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0, item.frame.size.width, 40)];
    label.text = RiistaLocalizedString(@"SrvaMethod", nil);
    [item addSubview:label];

    self.activeMethodNames = [NSMutableArray new];

    SrvaEventMetadata* meta = [self findMetadataForEventName:self.srva.eventName];

    CGFloat yBox = 40;
    for (SrvaMethod* method in meta.methods) {
        SrvaMethod* eventMethod = [self findEventMethod:method.name];

        M13Checkbox* box = [[M13Checkbox alloc] initWithFrame:CGRectMake(LEFT_MARGIN, yBox, contentViewWidth - LEFT_MARGIN, 25)];
        box.checkState = [eventMethod.isChecked boolValue] ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;
        box.enabled = self.editMode;
        box.tag = self.activeMethodNames.count;
        [RiistaViewUtils setCheckboxStyle:box];
        [box addTarget:self action:@selector(methodCheckboxChanged:) forControlEvents:UIControlEventValueChanged];
        [item addSubview:box];

        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(50, yBox, item.frame.size.width, 25)];
        name.text = RiistaMappedValueString(method.name, nil);
        [item addSubview:name];

        [self.activeMethodNames addObject:method.name];

        yBox += box.frame.size.height + 10;
    }

    CGRect frame = item.frame;
    frame.size.height = yBox;
    item.frame = frame;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)methodCheckboxChanged:(id)sender
{
    M13Checkbox* box = sender;
    NSString* methodName = self.activeMethodNames[box.tag];

    NSMutableArray<SrvaMethod*> *methods = [self.srva parseMethods];
    for (SrvaMethod* method in methods) {
        if ([method.name isEqualToString:methodName]) {
            method.isChecked = (box.checkState == M13CheckboxStateChecked) ? @(YES) : @(NO);
            break;
        }
    }
    [self.srva putMethods:methods];

    [self updateViews];
}

- (void)createMethodOtherInput
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaMethodDescription", nil)
                                                     value:self.srva.otherMethodDescription];
    item.textField.keyboardType = UIKeyboardTypeDefault;
    item.textField.returnKeyType = UIReturnKeyDone;
    item.tag = TAG_METHOD_OTHER;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)createPersonCountInput
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaPersonCount", nil)
                                                     value:[self.srva.personCount stringValue]];
    item.maxNumberValue = [NSNumber numberWithInt:100];
    item.nonNegativeIntNumberOnly = YES;
    item.textField.keyboardType = UIKeyboardTypeNumberPad;
    item.textField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:item.textField];
    item.tag = TAG_PERSON_COUNT;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (void)createTimeSpentInput
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaTimeSpent", nil)
                                                     value:[self.srva.timeSpent stringValue]];
    item.maxNumberValue = [NSNumber numberWithInt:999];
    item.nonNegativeIntNumberOnly = YES;
    item.textField.keyboardType = UIKeyboardTypeNumberPad;
    item.textField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:item.textField];
    item.tag = TAG_TIME_SPENT;

    item.translatesAutoresizingMaskIntoConstraints = NO;
    [item.heightAnchor constraintEqualToConstant:item.frame.size.height].active = YES;
    [item.widthAnchor constraintEqualToConstant:item.frame.size.width].active = YES;
    [self.contentView addArrangedSubview:item];
}

- (SrvaEventMetadata*)findMetadataForEventName:(NSString*)eventName
{
    SrvaMetadata* metadata = [[RiistaMetadataManager sharedInstance] getSrvaMetadata];

    for (SrvaEventMetadata* event in metadata.events) {
        if ([event.name isEqualToString:eventName]) {
            return event;
        }
    }
    return nil;
}

- (SrvaMethod*)findEventMethod:(NSString*)name
{
    NSMutableArray<SrvaMethod*> *methods = [self.srva parseMethods];
    for (SrvaMethod *method in methods) {
        if ([method.name isEqualToString:name]) {
            return method;
        }
    }

    SrvaMethod *m = [SrvaMethod new];
    m.name = name;
    m.isChecked = [NSNumber numberWithBool:NO];
    [methods addObject:m];

    [self.srva putMethods:methods];

    return nil;
}

- (BOOL)isMehodOtherChecked
{
    NSMutableArray<SrvaMethod*> *methods = [self.srva parseMethods];
    for (SrvaMethod *method in methods) {
        if ([method.name isEqualToString:@"OTHER"]) {
            return [method.isChecked boolValue];
        }
    }
    return NO;
}

- (void)showValueSelect:(NSString*)key title:(NSString*)title values:(NSArray*)values overrides:(NSDictionary*)overrides
{
    ValueListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"valueListController"];
    controller.fieldKey = key;
    controller.titlePrompt = title;
    controller.values = values;
    controller.delegate = self;

    if (overrides) {
        for (NSString *key in overrides) {
            [controller setTextKeyOverride:key overrideKey:[overrides valueForKey:key]];
        }
    }

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)valueSelectedForKey:(NSString*)key value:(NSString*)value
{
    if ([key isEqualToString:EVENT_NAME_KEY]) {
        self.srva.eventName = value;

        self.srva.eventType = nil;
        self.srva.eventResult = nil;
        [self.srva putMethods:[NSArray new]];
    }
    else if ([key isEqualToString:EVENT_TYPE_KEY]) {
        self.srva.eventType = value;
    }
    else if ([key isEqualToString:EVENT_RESULT_KEY]) {
        self.srva.eventResult = value;
    }
    [self updateViews];
}


@end
