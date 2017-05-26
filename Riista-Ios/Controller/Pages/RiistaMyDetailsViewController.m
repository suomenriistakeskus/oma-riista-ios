#import "RiistaMyDetailsViewController.h"
#import "RiistaHeaderLabel.h"
#import "RiistaLocalization.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "DataModels.h"
#import "RiistaGameDatabase.h"

@interface RiistaMyDetailsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *detailsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@property (strong, nonatomic) NSMutableArray *personData;
@property (strong, nonatomic) NSMutableArray *assignmentData;
@property (strong, nonatomic) NSMutableArray *huntingLicenseData;

@property (strong, nonatomic) UserInfo *user;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

NSInteger const CELL_TYPE_TITLE_VALUE = 1;
NSInteger const CELL_TYPE_VALUE_ONLY = 2;
NSInteger const CELL_TYPE_TEXT_SHORT = 3;
NSInteger const CELL_TYPE_TEXT_LONG = 4;
NSInteger const CELL_TYPE_TITLE_VALUE_EMPHASIS = 5;

NSString *const CELL_IDENTIFIER_SECTION_HEADER = @"SectionHeaderCell";
NSString *const CELL_IDENTIFIER_TITLE_SUBTITLE = @"TitleSubtitleCell";
NSString *const CELL_IDENTIFIER_TEXT_SHORT = @"TextShortCell";
NSString *const CELL_IDENTIFIER_TEXT_LONG = @"TextLongCell";
NSString *const CELL_IDENTIFIER_TITLE_SUBTITLE_EMPHASIS = @"TitleSubtitleEmphasisCell";

static CGFloat const CELL_WIDTH = 290.0f;
static CGFloat const HORIZONTAL_SPACING = 8.0f;

@interface ListCellItem : NSObject

@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;

+ (ListCellItem*)itemWithTitleIdAndValue:(NSString*)key andValue:(NSString*)value;
+ (ListCellItem*)itemWithTitleIdAndValueEmphasis:(NSString*)key andValue:(NSString*)value;
+ (ListCellItem*)itemWithValue:(NSString*)value;
+ (ListCellItem*)itemWithTextShort:(NSString*)value;
+ (ListCellItem*)itemWithTextLong:(NSString*)value;

@end

@interface TitleSubtitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
// For whatever reason cannot get label visible if reusing detailTextLabel
// from UITableViewCell as with textLabel
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@interface TextCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation RiistaMyDetailsViewController

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"MenuMyDetails", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.personData = [[NSMutableArray alloc] init];
    self.assignmentData = [[NSMutableArray alloc] init];
    self.huntingLicenseData = [[NSMutableArray alloc] init];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"dd.MM.yyyy"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageSelectionUpdated:) name:RiistaLanguageSelectionUpdatedKey object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    [self refreshInformation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self pageSelected];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)pageSelected
{
    self.navigationController.title = RiistaLocalizedString(@"MyDetails", nil);
}

- (void)languageSelectionUpdated:(NSNotification*)notification
{
    RiistaLanguageRefresh;
    [self refreshInformation];
}

- (void)refreshInformation
{
    self.user = [RiistaSettings userInfo];
    if (self.user != nil) {
        NSString *langCode = [RiistaSettings language];

        [self setupPersonalInformation:langCode];
        [self setupOccupationInformation:langCode];
        [self setupHuntingLicense:langCode];
    }
    else {
        // Generate empty stucture of basic information to make it more obvious that data is missing
        [_personData removeAllObjects];
        [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsName" andValue:@""]];
        [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsDateOfBirth" andValue:@""]];
        [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsHomeMunicipality" andValue:@""]];
        [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsAddress" andValue:@""]];
    }

    [self.detailsTableView reloadData];
    [self adjustTableViewHeight];
}

- (void)setupPersonalInformation:(NSString *)langCode
{
    NSString *name = [NSString stringWithFormat:@"%@ %@", self.user.firstName, self.user.lastName];
    NSString *dateOfBirth = [self.dateFormatter stringFromDate:self.user.birthDate];
    NSString *homeMunicipality = [self.user.homeMunicipality objectForKey:langCode]
                               ? [self.user.homeMunicipality objectForKey:langCode]
                               : [self.user.homeMunicipality objectForKey:@"fi"];

    NSString *address = nil;
    if (self.user.address != nil) {
        Address *userAddress = self.user.address;
        address = [NSString stringWithFormat:@"%@\n%@ %@\n%@",
                   userAddress.streetAddress != nil ? userAddress.streetAddress : @"",
                   userAddress.postalCode != nil ? userAddress.postalCode : @"",
                   userAddress.city != nil ? userAddress.city : @"",
                   userAddress.country != nil ? userAddress.country : @""];
    }

    [_personData removeAllObjects];
    [_personData addObject:[ListCellItem itemWithTitleIdAndValueEmphasis:@"MyDetailsName" andValue:name != nil ? name : @""]];
    [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsDateOfBirth" andValue:dateOfBirth != nil ? dateOfBirth : @""]];
    [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsHomeMunicipality" andValue:homeMunicipality != nil ? homeMunicipality : @""]];
    [_personData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsAddress" andValue:address != nil ? address : @""]];
}

- (void)setupOccupationInformation:(NSString *)langCode
{
    [_assignmentData removeAllObjects];

    for (Occupation *occupation in self.user.occupations) {
        NSString *occupationDuration = nil;
        NSString *occupationName = nil;
        NSString *occupationOrganization = nil;

        if (occupation.beginDate == nil && occupation.endDate == nil) {
            occupationDuration = RiistaLocalizedString(@"DurationIndefinite", nil);
        }
        else {
            NSString *beginDate = [self.dateFormatter stringFromDate:occupation.beginDate];
            NSString *endDate = [self.dateFormatter stringFromDate:occupation.endDate];

            occupationDuration = [NSString stringWithFormat:@"%@ - %@",
                                  beginDate != nil ? beginDate : @"",
                                  endDate != nil ? endDate : @""];
        }

        occupationName = [occupation.name objectForKey:langCode]
                       ? [occupation.name objectForKey:langCode]
                       : [occupation.name objectForKey:@"fi"];

        occupationOrganization = [occupation.organisation.name objectForKey:langCode]
                               ? [occupation.organisation.name objectForKey:langCode]
                               : [occupation.organisation.name objectForKey:@"fi"];

        [_assignmentData addObject:[ListCellItem itemWithValue:[NSString stringWithFormat:@"%@\n%@\n%@",
                                                                occupationOrganization,
                                                                occupationName,
                                                                occupationDuration]]];
    }
}

- (void)setupHuntingLicense:(NSString *)langCode
{
    [_huntingLicenseData removeAllObjects];

    if (self.user.huntingBanStart != nil || self.user.huntingBanEnd != nil) {

        // Hunting ban information is displayed instead of all other data if active
        NSString *huntingBanDuration = [NSString stringWithFormat:@"%@ - %@",
                                        [self.dateFormatter stringFromDate:self.user.huntingBanStart],
                                        [self.dateFormatter stringFromDate:self.user.huntingBanEnd]];
        [_huntingLicenseData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsHuntingBan" andValue:huntingBanDuration]];
    }
    else if (self.user.huntingCardValidNow) {

        // Valid licence, display full information
        NSString *paymentText = nil;
        NSString *rhyText = nil;

        if (self.user.huntingCardValidNow) {
            paymentText = [NSString stringWithFormat:RiistaLocalizedString(@"MyDetailsFeePaidFormat", nil),
                           [self.dateFormatter stringFromDate:self.user.huntingCardStart],
                           [self.dateFormatter stringFromDate:self.user.huntingCardEnd]];
        }
        else {
            paymentText = RiistaLocalizedString(@"MyDetailsFeeNotPaid", nil);
        }

        if (self.user.rhy != nil) {
            NSString *rhyName = [self.user.rhy.name objectForKey:langCode]
                              ? [self.user.rhy.name objectForKey:langCode]
                              : [self.user.rhy.name objectForKey:@"fi"];

            rhyText = [NSString stringWithFormat:@"%@ (%@)", rhyName, self.user.rhy.officialCode];
        }

        [_huntingLicenseData addObject:[ListCellItem itemWithTitleIdAndValueEmphasis:@"MyDetailsHunterId" andValue:self.user.hunterNumber]];
        [_huntingLicenseData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsPayment" andValue:paymentText]];
        [_huntingLicenseData addObject:[ListCellItem itemWithTitleIdAndValue:@"MyDetailsMembership" andValue:rhyText]];
        [_huntingLicenseData addObject:[ListCellItem itemWithTextLong:RiistaLocalizedString(@"MyDetailsInsurancePolicyText", nil)]];
    }
    else {

        // No valid active license
        [_huntingLicenseData addObject:[ListCellItem itemWithTextShort:RiistaLocalizedString(@"MyDetailsNoValidLicense", nil)]];
    }
}

- (void)adjustTableViewHeight
{
    CGFloat height = self.detailsTableView.contentSize.height;
    CGFloat maxHeight = self.detailsTableView.superview.frame.size.height - self.detailsTableView.frame.origin.y;

    // if the height of the content is greater than the maxHeight of
    // total space on the screen, limit the height to the size of the
    // superview.

    if (height > maxHeight)
        height = maxHeight;

    [UIView animateWithDuration:0.25 animations:^{
        self.tableViewHeightConstraint.constant = height;
        [self.view setNeedsUpdateConstraints];
    }];

    // Disable scrolling if content fits screen
    if (self.detailsTableView.contentSize.height < maxHeight) {
        self.detailsTableView.scrollEnabled = NO;
        self.detailsTableView.userInteractionEnabled = NO;
    }
    else {
        self.detailsTableView.scrollEnabled = YES;
        self.detailsTableView.userInteractionEnabled = YES;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = 0;

    // Assignements section is the only optional
    if ([_assignmentData count] > 0) {
        sectionCount = 3;
    }
    else {
        sectionCount = 2;
    }

    return sectionCount;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    if (section == 0) {
        numberOfRows = [_personData count];
    }
    else if (section == 1 && [_assignmentData count] > 0) {
        numberOfRows = [_assignmentData count];
    }
    else if (section == 1 || section == 2) {
        numberOfRows = [_huntingLicenseData count];
    }

    return numberOfRows;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_SECTION_HEADER];

    NSString *headerTitle = @"";

    if (section == 0) {
        headerTitle = RiistaLocalizedString(@"MyDetailsTitlePerson", nil);
    }
    else if (section == 1 && [_assignmentData count] > 0) {
        headerTitle = RiistaLocalizedString(@"MyDetailsAssignmentsTitle", nil);
    }
    else if (section == 1 || section == 2) {
        headerTitle = RiistaLocalizedString(@"MyDetailsTitleHuntingLicense", nil);
    }

    RiistaHeaderLabel *label = (RiistaHeaderLabel *)[cell viewWithTag:101];
    [label setText:headerTitle];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListCellItem *cellItem = [self itemFromIndexPath:indexPath];
    UITableViewCell *cell = nil;

    if (cellItem.type == CELL_TYPE_TITLE_VALUE) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TITLE_SUBTITLE forIndexPath:indexPath];
        [self configureSubtitleCell:(TitleSubtitleCell *)cell cellItem:cellItem];
    }
    else if (cellItem.type == CELL_TYPE_TITLE_VALUE_EMPHASIS) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TITLE_SUBTITLE_EMPHASIS forIndexPath:indexPath];
        [self configureSubtitleCell:(TitleSubtitleCell *)cell cellItem:cellItem];
    }
    else if (cellItem.type == CELL_TYPE_VALUE_ONLY) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TEXT_SHORT forIndexPath:indexPath];
        [self configureTextCell:(TextCell *)cell cellItem:cellItem];
    }
    else if (cellItem.type == CELL_TYPE_TEXT_SHORT) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TEXT_SHORT forIndexPath:indexPath];
        [self configureTextCell:(TextCell *)cell cellItem:cellItem];
    }
    else if (cellItem.type == CELL_TYPE_TEXT_LONG) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TEXT_LONG forIndexPath:indexPath];
        [self configureTextCell:(TextCell *)cell cellItem:cellItem];
    }

    return cell;
}

- (ListCellItem *)itemFromIndexPath:(NSIndexPath *)indexPath
{
    ListCellItem *cellItem = nil;

    if (indexPath.section == 0) {
        cellItem = _personData[indexPath.row];
    }
    else if (indexPath.section == 1 && [_assignmentData count] > 0) {
        cellItem = _assignmentData[indexPath.row];
    }
    else if (indexPath.section == 1 || indexPath.section == 2) {
        cellItem = _huntingLicenseData[indexPath.row];
    }

    return cellItem;
}

- (void)configureSubtitleCell:(TitleSubtitleCell *)cell cellItem:(ListCellItem *)item {
    cell.textLabel.text = item.key;
    cell.detailLabel.text = item.value;
}

- (void)configureTextCell:(TextCell *)cell cellItem:(ListCellItem *)item {
    cell.textLabel.text = item.value;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static TitleSubtitleCell *subtitleSizingCell = nil;
    static TextCell *textSizingCell = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        subtitleSizingCell = [tableView dequeueReusableCellWithIdentifier:@"TitleSubtitleCell"];
        textSizingCell = [tableView dequeueReusableCellWithIdentifier:@"TextShortCell"];
    });

    ListCellItem *item = [self itemFromIndexPath:indexPath];
    CGFloat retValue;

    if (item.type == CELL_TYPE_TITLE_VALUE || item.type == CELL_TYPE_TITLE_VALUE_EMPHASIS) {
        [self configureSubtitleCell:subtitleSizingCell cellItem:item];
        retValue = [self calculateHeightForCell:subtitleSizingCell];

        // TitleSubtitleCell is used for both CELL_TYPE_TITLE_VALUE and CELL_TYPE_TITLE_VALUE_EMPHASIS
        // Need to manually override font size used for bounding rect calculations
        NSDictionary *fontAttrs = @{NSFontAttributeName:subtitleSizingCell.detailLabel.font};
        if (item.type == CELL_TYPE_TITLE_VALUE_EMPHASIS) {
            UIFont *font = fontAttrs[@"NSFont"];
            fontAttrs = @{NSFontAttributeName:[font fontWithSize:15.0f]};
        }

        NSString *cellText = item.value;
        CGSize titleSize = [subtitleSizingCell.textLabel systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        CGSize constraintSize = CGSizeMake(CELL_WIDTH - titleSize.width - HORIZONTAL_SPACING, MAXFLOAT);
        CGRect subtitleRect = [cellText boundingRectWithSize:constraintSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:fontAttrs
                                                     context:nil];

        retValue = MAX(retValue, subtitleRect.size.height + 13.0f);
    }
    else {
        [self configureTextCell:textSizingCell cellItem:item];
        retValue = [self calculateHeightForCell:textSizingCell];
    }

    return retValue;
}

- (CGFloat)calculateHeightForCell:(UITableViewCell *)sizingCell
{
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];

    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height + 13.0f; // 2 * 6.0f margins + 1.0f for separator height
}

/*
// Fix item insets
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}
*/

@end

@implementation ListCellItem

+ (ListCellItem*)itemWithTitleIdAndValue:(NSString*)key andValue:(NSString*)value
{
    return [ListCellItem createItem:CELL_TYPE_TITLE_VALUE andKey:RiistaLocalizedString(key, nil) andValue:value];
}

+ (ListCellItem*)itemWithTitleIdAndValueEmphasis:(NSString*)key andValue:(NSString*)value
{
    return [ListCellItem createItem:CELL_TYPE_TITLE_VALUE_EMPHASIS andKey:RiistaLocalizedString(key, nil) andValue:value];
}

+ (ListCellItem*)itemWithValue:(NSString*)value
{
    return [ListCellItem createItem:CELL_TYPE_VALUE_ONLY andKey:nil andValue:value];
}

+ (ListCellItem*)itemWithTextShort:(NSString*)value
{
    return [ListCellItem createItem:CELL_TYPE_TEXT_SHORT andKey:nil andValue:value];
}

+ (ListCellItem*)itemWithTextLong:(NSString*)value
{
    return [ListCellItem createItem:CELL_TYPE_TEXT_LONG andKey:nil andValue:value];
}

+ (ListCellItem*)createItem:(NSInteger)type andKey:(NSString*)key andValue:(NSString*)value
{
    ListCellItem* item = [[ListCellItem alloc] init];
    item.type = type;
    item.key = key;
    item.value = value;

    return item;
}

@end

@implementation TitleSubtitleCell

@dynamic textLabel;
@synthesize detailLabel;

@end

@implementation TextCell

@dynamic textLabel;

@end
