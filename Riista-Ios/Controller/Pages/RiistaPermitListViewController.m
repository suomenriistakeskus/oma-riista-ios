#import "RiistaPermitListViewController.h"
#import "RiistaLocalization.h"
#import "RiistaNetworkManager.h"
#import "RiistaPermitManager.h"
#import "Permit.h"
#import "PermitSpeciesAmounts.h"
#import "Styles.h"
#import "FinnishHuntingPermitNumberValidator.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaGameDatabase.h"
#import "RiistaSpecies.h"
#import "RiistaSettings.h"
#import "NSDateformatter+Locale.h"

#import "Oma_riista-Swift.h"

const NSInteger PERMIT_DATE_DAYS_LIMIT = 30;

@interface PermitCellItem : NSObject

@property (nonatomic, copy) NSString *permitNumber;
@property (nonatomic, copy) NSString *permitType;
@property (nonatomic, assign) NSInteger gameSpeciesCode;
@property (nonatomic, assign) NSInteger amount;
@property (nonatomic, copy) NSDate *beginDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, copy) NSDate *beginDate2;
@property (nonatomic, copy) NSDate *endDate2;

- (void)setContent:(Permit*)permit species:(PermitSpeciesAmounts*)species;

@end

@interface RiistaPermitCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *numberText;
@property (weak, nonatomic) IBOutlet UILabel *typeText;
@property (weak, nonatomic) IBOutlet UILabel *detailsText;

- (void)refreshContent:(PermitCellItem*)cellItem dateFormatter:(NSDateFormatter*)dateFormatter;

@end

@interface RiistaPermitListViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RiistaKeyboardHandlerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *helpText;
@property (weak, nonatomic) IBOutlet UILabel *inputPrompt;
@property (weak, nonatomic) IBOutlet MDCUnderlinedTextField *numberInput;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressView;
@property (weak, nonatomic) IBOutlet MDCButton *submitButton;
@property (weak, nonatomic) IBOutlet UILabel *errorNoteLabel;
@property (weak, nonatomic) IBOutlet UILabel *listTitle;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *errorNoteHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;

@property (strong, nonatomic) NSArray *permitListItems;
@property (strong, nonatomic) NSArray *filteredPermitListItems;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation RiistaPermitListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
    [self.dateFormatter setDateFormat:@"dd.MM.yyyy"];

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;
    [self registerForKeyboardNotifications];

    [_submitButton applyContainedThemeWithScheme:AppTheme.shared.primaryButtonScheme];
    _submitButton.titleEdgeInsets = UIEdgeInsetsMake(_submitButton.titleEdgeInsets.top, -10.0, _submitButton.titleEdgeInsets.bottom, -10.0);
    [self.submitButton addTarget:self action:@selector(submitButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    [self.numberInput configureFor:FontUsageInputValue];
    [self.numberInput setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(numberInputDidChange:)
                                                 name:UITextFieldTextDidChangeNotification object:self.numberInput];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    [self.helpText setText:RiistaLocalizedString(@"PermitListHelpText", nil)];
    [self.inputPrompt setText:RiistaLocalizedString(@"PermitListInputPrompt", nil)];
    [self.submitButton setTitle:RiistaLocalizedString(@"PermitListButtonText", nil) forState:UIControlStateNormal];
    [self.errorNoteLabel setText:RiistaLocalizedString(@"PermitListNotAvailable", nil)];
    [self.listTitle setText:RiistaLocalizedString(@"PermitListSectionHeader", nil)];

    [self.numberInput setText:self.inputValue];
    [self.progressView setHidden:YES];

    self.title = RiistaLocalizedString(@"PermitListPageTitle", nil);

    self.permitListItems = [self permitListToListItems:[[RiistaPermitManager sharedInstance] getAllPermits]];
    [self filterByNumberInput:self.inputValue];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pageSelected
{
}

- (void)submitButtonClick:(id)sender
{
    [self hideKeyboard];
    [self.submitButton setEnabled:NO];
    [self.progressView startAnimating];
    [self.progressView setHidden:NO];

    [[RiistaNetworkManager sharedInstance] checkPermitNumber:[self.numberInput text] completion:^(NSDictionary *data, NSError *error) {
        [self.progressView setHidden:YES];
        [self.progressView stopAnimating];

        if (error == nil) {
            Permit *permit = [Permit modelObjectWithDictionary:data];
            [[RiistaPermitManager sharedInstance] addManualPermit:permit];

            self.permitListItems = [self permitListToListItems:[[RiistaPermitManager sharedInstance] getAllPermits]];
            [self filterByNumberInput:self.inputValue];
            [self.tableView reloadData];
        }

        [self updateErrorNoteVisibility];
    }];
}

- (void)numberInputDidChange:(id)sender
{
    self.inputValue = [self.numberInput text];

    if ([FinnishHuntingPermitNumberValidator validate:self.inputValue verifyChecksum:YES]) {
        [self.submitButton setEnabled:([self.inputValue length] > 0) && [[RiistaPermitManager sharedInstance] getPermit:self.inputValue] == nil];
    }
    else {
        [self.submitButton setEnabled:NO];
    }

    [self updateErrorNoteVisibility];

    [self filterByNumberInput:self.inputValue];
    [self.tableView reloadData];
}

- (void)updateErrorNoteVisibility
{
    if ([self.inputValue length] > 0 && [FinnishHuntingPermitNumberValidator validate:self.inputValue verifyChecksum:YES]) {
        Permit *permit = [[RiistaPermitManager sharedInstance] getPermit:self.inputValue];

        if (permit != nil && permit.unavailable ) {
            self.errorNoteLabel.hidden = NO;
            self.errorNoteHeightConstraint.constant = 40.f;
        }
        else {
            self.errorNoteLabel.hidden = YES;
            self.errorNoteHeightConstraint.constant = 0.f;
        }
    }
    else {
        self.errorNoteLabel.hidden = YES;
        self.errorNoteHeightConstraint.constant = 0.f;
    }
}

- (BOOL)isPermitAvailable
{
    RiistaPermitManager *permitManager = [RiistaPermitManager sharedInstance];
    Permit *permit = [permitManager getPermit:self.inputValue];

    return permit != nil && !permit.unavailable;
}

- (void)filterByNumberInput:(NSString*)input
{
    if ([input length] == 0) {
        self.filteredPermitListItems = [self.permitListItems copy];
        return;
    }

    NSMutableArray *result = [[NSMutableArray alloc] init];

    for (PermitCellItem *item in self.permitListItems) {
        NSRange numberRange = [item.permitNumber rangeOfString:input options:NSCaseInsensitiveSearch];
        if (numberRange.location != NSNotFound) {
            [result addObject:item];
        }
    }

    self.filteredPermitListItems = [result copy];
    [self.tableView reloadData];
}

- (NSArray*)permitListToListItems:(NSArray*)permitList
{
    NSMutableArray *results = [[NSMutableArray alloc] init];

    for (Permit *permit in permitList) {
        if (!permit.unavailable) {
            [results addObjectsFromArray:[self permitToListItems:permit]];
        }
    }

    return results;
}

- (NSArray*)permitToListItems:(Permit*)permit
{
    NSMutableArray *results = [[NSMutableArray alloc] init];

    if (permit.unavailable) {
        return results;
    }

    for (PermitSpeciesAmounts *speciesItem in permit.speciesAmounts) {
        if ([[RiistaPermitManager sharedInstance] isSpeciesSeasonActive:speciesItem daysTolerance:PERMIT_DATE_DAYS_LIMIT]) {
            PermitCellItem *listItem = [[PermitCellItem alloc] init];
            [listItem setContent:permit species:speciesItem];

            [results addObject:listItem];
        }
    }

    return results;
}

- (void)configureCell:(RiistaPermitCell*)cell item:(PermitCellItem*)item index:(NSInteger)rowIndex
{
    [cell refreshContent:item dateFormatter:self.dateFormatter];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

    CGRect rect = self.view.frame;
    rect.size.height -= kbSize.height;
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

# pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.numberInput resignFirstResponder];
    return YES;
}

# pragma mark - RiistaKeyboardHandlerDelegate

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredPermitListItems count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    RiistaPermitCell *cell = (RiistaPermitCell*)[tableView dequeueReusableCellWithIdentifier:@"permitCell"];
    PermitCellItem *permitItem = self.filteredPermitListItems[indexPath.row];

    [self configureCell:cell item:permitItem index:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    PermitCellItem *selectedItem = self.filteredPermitListItems[indexPath.row];
    [self.delegate permitSelected:[selectedItem permitNumber] speciesCode:[selectedItem gameSpeciesCode]];

    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation PermitCellItem

- (void)setContent:(Permit*)permit species:(PermitSpeciesAmounts*)speciesAmount
{
    self.permitNumber = permit.permitNumber;
    self.permitType = permit.permitType;
    self.gameSpeciesCode = speciesAmount.gameSpeciesCode;
    self.amount = speciesAmount.amount;
    self.beginDate = speciesAmount.beginDate;
    self.endDate = speciesAmount.endDate;
    self.beginDate2 = speciesAmount.beginDate2;
    self.endDate2 = speciesAmount.endDate2;
}

@end

@implementation RiistaPermitCell

- (void)refreshContent:(PermitCellItem*)cellItem dateFormatter:(NSDateFormatter*)dateFormatter
{
    [self.numberText setText:cellItem.permitNumber];
    [self.typeText setText:cellItem.permitType];
    [self.detailsText setText:[self parseSpeciesAmountText:cellItem dateFormatter:dateFormatter]];
}

- (NSString*)parseSpeciesAmountText:(PermitCellItem*)item dateFormatter:(NSDateFormatter*)dateFormatter
{
    NSString *text;
    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:item.gameSpeciesCode];

    NSString *beginDate = [dateFormatter stringFromDate:item.beginDate];
    NSString *endDate = [dateFormatter stringFromDate:item.endDate];

    text = [NSString stringWithFormat:@"%@ %ld %@\n%@ - %@",
            [species.name objectForKey:[RiistaSettings language]],
            (long)item.amount,
            RiistaLocalizedString(@"PermitListAmountShort", nil),
            beginDate,
            endDate
     ];

    if (item.beginDate2 != nil && item.endDate2 != nil) {
        beginDate = [dateFormatter stringFromDate:item.beginDate2];
        endDate = [dateFormatter stringFromDate:item.endDate2];

        text = [text stringByAppendingFormat:@",\n%@ - %@", beginDate, endDate];
    }

    return text;
}

@end
