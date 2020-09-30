#import "RiistaNavigationController.h"
#import "RiistaSpecimenListViewController.h"
#import "RiistaSpecimen.h"
#import "RiistaSpecies.h"
#import "RiistaLocalization.h"
#import "RiistaUtils.h"
#import "DiaryEntry.h"
#import "RiistaKeyboardHandler.h"
#import "KeyboardToolbarView.h"
#import "MaterialTextFields.h"

#import "Oma_riista-Swift.h"

@protocol SpecimenCellDelegate

- (void)removeSpecimen:(RiistaSpecimen*)specimen;

@end

static BOOL sGenderRequired = false;
static BOOL sAgeRequired = false;
static BOOL sWeigthRequired = false;

@interface RiistaSpecimenCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSelect;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ageSelect;
@property (weak, nonatomic) IBOutlet MDCTextField *weightInput;
@property (weak, nonatomic) IBOutlet MDCButton *removeButton;

@property (weak, nonatomic) IBOutlet UILabel *genderRequiredIndicator;
@property (weak, nonatomic) IBOutlet UILabel *ageRequiredIndicator;
@property (weak, nonatomic) IBOutlet UILabel *weightRequiredIndicator;

@property (strong, nonatomic) MDCTextInputControllerUnderline *weightInputController;

@property (weak, nonatomic) id<SpecimenCellDelegate> delegate;
@property (strong, nonatomic) RiistaSpecimen *specimen;

- (void)updateLocalizedTexts;
- (void)updateValueSelections;
- (void)updateItemTitle:(NSString*)titleText;
- (void)setRequiresGender:(BOOL)genderRequired andAge:(BOOL)ageRequired andWeight:(BOOL)weightRequired;

@end

@interface RiistaSpecimenListViewController () <SpecimenCellDelegate, KeyboardHandlerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;
@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;

@property (strong, nonatomic) NSMutableOrderedSet *specimens;
@property (strong, nonatomic) UIBarButtonItem *addButton;

@end

@implementation RiistaSpecimenListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = [UIView new];

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;

    UIImage *addImage = [UIImage imageNamed:@"ic_menu_add.png"];
    _addButton = [[UIBarButtonItem alloc] initWithImage:addImage
                                    landscapeImagePhone:addImage
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(addSpecimen:)];
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController setRightBarItems:@[_addButton]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RiistaLanguageRefresh;

    [self updateTitle];
    [_addButton setEnabled:_editMode];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle: [NSString stringWithFormat:@"%@ (%lu)",
                                 [RiistaUtils nameWithPreferredLanguage:_species.name],
                                 (unsigned long)[_specimens count]]];
}

- (void)setRequiredFields:(BOOL)genderRequired ageREquired:(BOOL)ageRequired weightRequired:(BOOL)weightRequired
{
    sGenderRequired = genderRequired;
    sAgeRequired = ageRequired;
    sWeigthRequired = weightRequired;
}

- (void)addSpecimen:(id)sender
{
    if ([_specimens count] < DiaryEntrySpecimenDetailsMax) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Specimen" inManagedObjectContext:_editContext];
        RiistaSpecimen *newSpecimen = (RiistaSpecimen*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:_editContext];
        [_delegate didAddSpecimen:newSpecimen];

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

- (void)configureCell:(RiistaSpecimenCell*)cell item:(RiistaSpecimen*)specimen index:(NSInteger)rowIndex
{
    cell.delegate = self;

    [AppTheme.shared setupSegmentedControllerWithSegmentedController:cell.genderSelect];
    [AppTheme.shared setupSegmentedControllerWithSegmentedController:cell.ageSelect];
    [AppTheme.shared setupValueFontWithTextField:cell.weightInput];

    [cell updateLocalizedTexts];
    [cell setSpecimen:specimen];
    [cell updateValueSelections];

    NSString *titleText = [NSString stringWithFormat:@"%@ %ld", [RiistaUtils nameWithPreferredLanguage:_species.name], (long)rowIndex + 1];
    [cell updateItemTitle:titleText];

    // Hide remove button when not editing
    [cell.removeButton setHidden:!_editMode];

    [cell.genderSelect setUserInteractionEnabled:_editMode ? YES : NO];
    [cell.ageSelect setUserInteractionEnabled:_editMode ? YES : NO];
    [cell.weightInput setUserInteractionEnabled:_editMode ? YES : NO];
}

- (void)setContent:(NSMutableOrderedSet *)specimens
{
    self.specimens = specimens;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.specimens.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    RiistaSpecimenCell *cell = (RiistaSpecimenCell*)[tableView dequeueReusableCellWithIdentifier:@"specimenCell"];
    RiistaSpecimen *specimen = self.specimens[indexPath.row];

    [self configureCell:cell item:specimen index:indexPath.row];
    [cell setRequiresGender:sGenderRequired andAge:sAgeRequired andWeight:sWeigthRequired];

    return cell;
}

#pragma mark - SpecimenCellDelegate

- (void)removeSpecimen:(RiistaSpecimen*)specimen
{
    // Removing last specimen is not allowed since amount would become 0
    if ([_specimens count] > 1) {
        [_delegate didRemoveSpecimen:specimen];

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

@implementation RiistaSpecimenCell
{
    BOOL isGenderRequired;
    BOOL isAgeRequired;
    BOOL isWeightRequired;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _weightInput.delegate = self;
    _weightInput.keyboardType = UIKeyboardTypeDecimalPad;
    _weightInput.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:_weightInput];

    _weightInputController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:_weightInput];
    [_weightInputController applyThemeWithScheme:AppTheme.shared.textFieldContainerScheme];

    [_genderSelect addTarget:self action:@selector(genderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_ageSelect addTarget:self action:@selector(ageValueChanged:) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(weightValueChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:_weightInput];

    [AppTheme.shared setupImageButtonThemeWithButton:_removeButton];
    [_removeButton addTarget:self action:@selector(removeSpecimenItem:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)updateLocalizedTexts
{
    [_ageSelect setTitle:RiistaLocalizedString(@"SpecimenAgeAdult", nil) forSegmentAtIndex:0];
    [_ageSelect setTitle:RiistaLocalizedString(@"SpecimenAgeYoung", nil) forSegmentAtIndex:1];
    _weightInput.placeholder = RiistaLocalizedString(@"SpecimenWeightTitle", nil);
}

- (void)updateItemTitle:(NSString*)titleText
{
    [_itemTitle setText:titleText];
}

- (void)setRequiresGender:(BOOL)genderRequired andAge:(BOOL)ageRequired andWeight:(BOOL)weightRequired
{
    isGenderRequired = genderRequired;
    isAgeRequired = ageRequired;
    isWeightRequired = weightRequired;

    [self refreshRequiredValueIndicators];
}

- (void)refreshRequiredValueIndicators
{
    [self.genderRequiredIndicator setHidden:!(isGenderRequired && [[self.specimen gender] length] == 0)];
    [self.ageRequiredIndicator setHidden:!(isAgeRequired && [[self.specimen age] length] == 0)];
    [self.weightRequiredIndicator setHidden:!(isWeightRequired && [self.specimen weight] == 0)];
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
    else {
        [_genderSelect setSelectedSegmentIndex:-1];
    }

    // Selected age
    if ([_specimen.age isEqualToString:SpecimenAgeAdult]) {
        [_ageSelect setSelectedSegmentIndex:0];
    }
    else if ([_specimen.age isEqualToString:SpecimenAgeYoung]) {
        [_ageSelect setSelectedSegmentIndex:1];
    }
    else {
        [_ageSelect setSelectedSegmentIndex:-1];
    }

    _weightInput.text = _specimen.weight == nil ? nil
        : [NSNumberFormatter localizedStringFromNumber:_specimen.weight numberStyle:NSNumberFormatterDecimalStyle];
}

- (void)genderValueChanged:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == 0) {
        _specimen.gender = SpecimenGenderFemale;
    }
    else if (sender.selectedSegmentIndex == 1) {
        _specimen.gender = SpecimenGenderMale;
    }
    else {
        _specimen.gender = nil;
    }

    [self refreshRequiredValueIndicators];
}

- (void)ageValueChanged:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == 0) {
        _specimen.age = SpecimenAgeAdult;
    }
    else if (sender.selectedSegmentIndex == 1) {
        _specimen.age = SpecimenAgeYoung;
    }
    else {
        _specimen.age = nil;
    }

    [self refreshRequiredValueIndicators];
}

- (void)weightValueChanged:(id)sender
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    _specimen.weight = [formatter numberFromString:[_weightInput text]];

    [self refreshRequiredValueIndicators];
}

- (void)removeSpecimenItem:(UIButton*)sender
{
    [_delegate removeSpecimen:_specimen];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.weightInput)
    {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

        NSString *pattern = @"^([0-9]{0,3}(([\\.,][0-9])||([\\.,])))?$";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
        if (numberOfMatches == 0)
            return NO;
    }

    return YES;
}

@end
