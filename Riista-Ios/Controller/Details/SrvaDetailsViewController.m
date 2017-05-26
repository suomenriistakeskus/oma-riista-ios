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

static const CGFloat SrvaItemHeight = 63;

static NSString * const EVENT_NAME_KEY = @"EventNameKey";
static NSString * const EVENT_TYPE_KEY = @"EventTypeKey";
static NSString * const EVENT_RESULT_KEY = @"EventResultKey";

static NSInteger const TAG_SPECIES_OTHER = 100;
static NSInteger const TAG_TYPE_OTHER = 101;
static NSInteger const TAG_METHOD_OTHER = 102;
static NSInteger const TAG_PERSON_COUNT = 103;
static NSInteger const TAG_TIME_SPENT = 104;

@interface SrvaDetailsViewController () <UITextFieldDelegate, UITextViewDelegate, ValueSelectionDelegate, SpeciesSelectionDelegate, SrvaSpecimensUpdatedDelegate>

@property (weak, nonatomic) IBOutlet UIView *speciesView;
@property (weak, nonatomic) IBOutlet UIImageView *speciesImageView;
@property (weak, nonatomic) IBOutlet UILabel *speciesNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speciesMandatoryLabel;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIView *specimenDetailsButton;
@property (weak, nonatomic) IBOutlet UILabel *specimenDetailsLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *specimenButtonTopConstraint;

@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) NSMutableArray<NSString*> *activeMethodNames;

@end

@implementation SrvaDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [RiistaViewUtils addTopAndBottomBorders:self.speciesView];
    [RiistaViewUtils addTopAndBottomBorders:self.specimenDetailsButton];
    [RiistaViewUtils setTextViewStyle:self.amountTextField];
    self.amountTextField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:self.amountTextField];

    self.specimenDetailsLabel.text = RiistaLocalizedString(@"SpecimenDetailsTitle", nil);

    self.amountTextField.delegate = self;
    self.amountTextField.keyboardType = UIKeyboardTypeNumberPad;

    self.amountLabel.text = RiistaLocalizedString(@"EntryDetailsAmountShort", nil);
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
    //self.editMode = NO;
}

- (void)setEditMode:(BOOL)editMode
{
    super.editMode = editMode;

    self.amountTextField.enabled = self.editMode;
    self.speciesView.userInteractionEnabled = self.editMode;

    [self refreshViews];

//    [self generateEmptySpecimensToAmount:[self.selectedAmount integerValue]];

//    self.variableContentContainer.userInteractionEnabled = editMode;
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

- (void)saveValues
{
    [self updateSpecimenAmount:[self.amountTextField.text integerValue]];

    RiistaValueListTextField* speciesOtherItem = [self.contentView viewWithTag:TAG_SPECIES_OTHER];
    if (self.srva.gameSpeciesCode == nil && speciesOtherItem) {
        self.srva.otherSpeciesDescription = speciesOtherItem.textView.text;
    }

    RiistaValueListTextField* typeOtherItem = [self.contentView viewWithTag:TAG_TYPE_OTHER];
    if ([self.srva.eventType isEqualToString:@"OTHER"] && typeOtherItem) {
        self.srva.otherTypeDescription = typeOtherItem.textView.text;
    }

    RiistaValueListTextField* methodOtherItem = [self.contentView viewWithTag:TAG_METHOD_OTHER];
    if ([self isMehodOtherChecked] && methodOtherItem) {
        self.srva.otherMethodDescription = methodOtherItem.textView.text;
    }

    RiistaValueListTextField* personsItem = [self.contentView viewWithTag:TAG_PERSON_COUNT];
    self.srva.personCount = @([personsItem.textView.text integerValue]);

    RiistaValueListTextField* timeItem = [self.contentView viewWithTag:TAG_TIME_SPENT];
    self.srva.timeSpent = @([timeItem.textView.text integerValue]);
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

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self updateViews];
}

- (CGFloat)contentHeight
{
    CGFloat y = 0;
    for (UIView *view in [self.contentView subviews]) {
        y = MAX(y, view.frame.origin.y + view.frame.size.height);
    }
    return y;
}

- (void)removeAllContentViews
{
    [[self.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (RiistaValueListButton*)createChoice:(NSString*)name value:(NSString*)value y:(int)y
{
    RiistaValueListButton *control = [[RiistaValueListButton alloc] initWithFrame:CGRectMake(0, y, self.contentView.frame.size.width, SrvaItemHeight)];
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

- (RiistaValueListTextField*)createTextField:(NSString*)name value:(NSString*)value y:(int)y
{
    RiistaValueListTextField *control = [[RiistaValueListTextField alloc] initWithFrame:CGRectMake(0, y, self.contentView.frame.size.width, SrvaItemHeight)];
    control.delegate = self;
    control.backgroundColor = [UIColor whiteColor];
    control.textView.editable = self.editMode;
    control.textView.scrollEnabled = NO;
    control.titleTextLabel.text = name;
    if (value == nil) {
        control.textView.text = @"";
    }
    else {
        control.textView.text = value;
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

    CGFloat y = 10;
    CGFloat pad = 10;
    if (self.srva.gameSpeciesCode == nil && self.srva.otherSpeciesDescription != nil) {
        [self createOtherSpeciesInput:y];
        self.specimenButtonTopConstraint.constant = SrvaItemHeight + pad * 2;
        y += SrvaItemHeight + pad;
    }
    else {
        self.srva.otherSpeciesDescription = nil;
        self.specimenButtonTopConstraint.constant = y;
    }

    if (self.srva.gameSpeciesCode != nil || self.srva.otherSpeciesDescription != nil) {
        y += self.specimenDetailsButton.frame.size.height;
        self.specimenDetailsButton.hidden = NO;
    }
    else {
        y -= pad;
        self.specimenDetailsButton.hidden = YES;
    }

    if ([self.srva.state isEqualToString:SrvaStateApproved] || [self.srva.state isEqualToString:SrvaStateRejected]) {
        y += [self createApproverInfoView:y+pad] + pad;
    }

    [self createEventNameChoice:y+pad];
    y += SrvaItemHeight + pad;

    if (self.srva.eventName != nil) {
        [self createEventTypeChoice:y+pad];
        y += SrvaItemHeight + pad;
    }

    if ([self.srva.eventType isEqualToString:@"OTHER"]) {
        [self createEventOtherInput:y+pad];
        y += SrvaItemHeight + pad;
    }
    else {
        self.srva.otherTypeDescription = nil;
    }

    if (self.srva.eventName != nil) {
        [self createResultChoice:y+pad];
        y += SrvaItemHeight + pad;
    }
    else {
        self.srva.eventResult = nil;
    }

    if (self.srva.eventName != nil) {
        y += [self createMethodChoices:y+pad] + pad;
    }
    else {
        [self.srva putMethods:@[]];
    }

    if ([self isMehodOtherChecked]) {
        [self createMethodOtherInput:y+pad];
        y += SrvaItemHeight + pad;
    }
    else {
        self.srva.otherMethodDescription = nil;
    }

    [self createPersonCountInput:y+pad];
    y += SrvaItemHeight + pad;

    [self createTimeSpentInput:y+pad];

    return [self contentHeight] + 5;
}

- (void)updateSpeciesSelection
{
    self.speciesMandatoryLabel.hidden = YES;

    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.srva.gameSpeciesCode integerValue]];
    if (species) {
        self.speciesNameLabel.text = [RiistaUtils nameWithPreferredLanguage:species.name];
        self.speciesImageView.image = [RiistaUtils loadSpeciesImage:species.speciesId];
        self.speciesImageView.tintColor = nil;
    }
    else if (self.srva.otherSpeciesDescription) {
        self.speciesNameLabel.text = RiistaLocalizedString(@"SrvaOtherSpeciesDescription", nil);
        self.speciesImageView.image = [[UIImage imageNamed:@"ic_question_mark_green.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.speciesImageView.tintColor = [UIColor blackColor];
    }
    else {
        self.speciesNameLabel.text = RiistaLocalizedString(@"ChooseSpecies", nil);
        self.speciesImageView.image = nil;
        self.speciesImageView.tintColor = nil;

        self.speciesMandatoryLabel.hidden = NO;
    }

    if (self.srva.totalSpecimenAmount) {
        self.amountTextField.text = [NSString stringWithFormat:@"%@", self.srva.totalSpecimenAmount];
    }
    else {
        self.amountTextField.text = @"";
    }
}

- (void)createOtherSpeciesInput:(CGFloat)y
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaOtherSpeciesDescription", nil) value:self.srva.otherSpeciesDescription y:y];
    item.maxTextLength = [NSNumber numberWithInteger:255];
    item.textView.keyboardType = UIKeyboardTypeDefault;
    item.textView.returnKeyType = UIReturnKeyDone;
    item.tag = TAG_SPECIES_OTHER;
    [self.contentView addSubview:item];
}

- (CGFloat)createApproverInfoView:(CGFloat)y
{
    UIView *item = [[UIView alloc] initWithFrame: CGRectMake(0, y, self.contentView.frame.size.width, 40)];
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

    [RiistaViewUtils addTopAndBottomBorders:item];
    [self.contentView addSubview:item];

    return item.frame.size.height;
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

- (void)createEventNameChoice:(CGFloat)y
{
    NSString *name = self.srva.eventName;
    if ([name isEqualToString:INJURED_ANIMAL]) {
        name = SICK_ANIMAL;
    }

    RiistaValueListButton *item = [self createChoice:RiistaLocalizedString(@"SrvaEvent", nil) value:RiistaMappedValueString(name, nil) y:y];
    [item addTarget:self action:@selector(onEventNameClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:item];
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

- (void)createEventTypeChoice:(CGFloat)y
{
    RiistaValueListButton *item = [self createChoice:RiistaLocalizedString(@"SrvaType", nil) value:RiistaMappedValueString(self.srva.eventType, nil) y:y];
    [item addTarget:self action:@selector(onEventTypeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:item];
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

- (void)createEventOtherInput:(CGFloat)y
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaTypeDescription", nil) value:self.srva.otherTypeDescription y:y];
    item.textView.keyboardType = UIKeyboardTypeDefault;
    item.textView.returnKeyType = UIReturnKeyDone;
    item.tag = TAG_TYPE_OTHER;
    [self.contentView addSubview:item];
}

- (void)createResultChoice:(CGFloat)y
{
    RiistaValueListButton *item = [self createChoice:RiistaLocalizedString(@"SrvaResult", nil) value:RiistaMappedValueString(self.srva.eventResult, nil) y:y];
    [item addTarget:self action:@selector(onEventResultClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:item];
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

- (CGFloat)createMethodChoices:(CGFloat)y
{
    UIView *item = [[UIView alloc] initWithFrame: CGRectMake(0, y, self.contentView.frame.size.width, 50)];
    item.backgroundColor = [UIColor whiteColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, item.frame.size.width, 40)];
    label.text = RiistaLocalizedString(@"SrvaMethod", nil);
    [item addSubview:label];

    self.activeMethodNames = [NSMutableArray new];

    SrvaEventMetadata* meta = [self findMetadataForEventName:self.srva.eventName];

    CGFloat yBox = 40;
    for (SrvaMethod* method in meta.methods) {
        SrvaMethod* eventMethod = [self findEventMethod:method.name];

        M13Checkbox* box = [[M13Checkbox alloc] initWithFrame:CGRectMake(15, yBox, 25, 25)];
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

    [RiistaViewUtils addTopAndBottomBorders:item];
    [self.contentView addSubview:item];

    return item.frame.size.height;
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

- (void)createMethodOtherInput:(CGFloat)y
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaMethodDescription", nil) value:self.srva.otherMethodDescription y:y];
    item.textView.keyboardType = UIKeyboardTypeDefault;
    item.textView.returnKeyType = UIReturnKeyDone;
    item.tag = TAG_METHOD_OTHER;
    [self.contentView addSubview:item];
}

- (void)createPersonCountInput:(CGFloat)y
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaPersonCount", nil) value:[self.srva.personCount stringValue] y:y];
    item.maxNumberValue = [NSNumber numberWithInt:100];
    item.textView.keyboardType = UIKeyboardTypeNumberPad;
    item.textView.inputAccessoryView = [KeyboardToolbarView textViewDoneToolbarView:item.textView];
    item.tag = TAG_PERSON_COUNT;
    [self.contentView addSubview:item];
}

- (void)createTimeSpentInput:(CGFloat)y
{
    RiistaValueListTextField *item = [self createTextField:RiistaLocalizedString(@"SrvaTimeSpent", nil) value:[self.srva.timeSpent stringValue] y:y];
    item.maxNumberValue = [NSNumber numberWithInt:999];
    item.textView.keyboardType = UIKeyboardTypeNumberPad;
    item.textView.inputAccessoryView = [KeyboardToolbarView textViewDoneToolbarView:item.textView];
    item.tag = TAG_TIME_SPENT;
    [self.contentView addSubview:item];
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
