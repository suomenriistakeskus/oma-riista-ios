#import "RiistaGameLogViewController.h"
#import "RiistaPageViewController.h"
#import "RiistaCalendarViewController.h"
#import "RiistaAppDelegate.h"
#import "RiistaGameDatabase.h"
#import "RiistaUtils.h"
#import "DiaryEntry.h"
#import "ObservationEntry.h"
#import "SrvaEntry.h"
#import "RiistaSpecies.h"
#import "RiistaNavigationController.h"
#import "RiistaLogGameViewController.h"
#import "UIColor+ApplicationColor.h"
#import "RiistaDiaryEntryUpdate.h"
#import "RiistaLocalization.h"
#import "RiistaSettings.h"
#import "RiistaDateTimeUtils.h"
#import "RiistaLogTabButton.h"
#import "RiistaMetaDataManager.h"
#import "UIColor+ApplicationColor.h"
#import "DetailsViewController.h"
#import "UserInfo.h"

@interface RiistaCalendarSectionView : UIView

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;

@end

@interface LogImage : NSObject

@property (strong, nonatomic) UIImage *image;

@end

@interface LogEventCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *logImageView;
@property (weak, nonatomic) IBOutlet UILabel *speciesLabel;
@property (weak, nonatomic) IBOutlet UIView *statusIndicator;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *sendStatusImageView;
@property (weak, nonatomic) IBOutlet UIImageView *eventTypeImageView;

@property (strong, nonatomic) LogImage *logImage;
@property (strong, nonatomic) DiaryEntry *diaryEntry;
@property (strong, nonatomic) ObservationEntry *observationEntry;

@end

@interface RiistaGameLogViewController () <RiistaPageDelegate, NSFetchedResultsControllerDelegate, RiistaCalendarDelegate>

@property (weak, nonatomic) IBOutlet RiistaLogTabButton *harvestsButton;
@property (weak, nonatomic) IBOutlet RiistaLogTabButton *observationsButton;
@property (weak, nonatomic) IBOutlet RiistaLogTabButton *srvasButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *calendarView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *srvaTrailingConstraint;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *leftArrow;
@property (weak, nonatomic) IBOutlet UIButton *rightArrow;
@property (weak, nonatomic) IBOutlet UILabel *seasonLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalAmountLabel;

@property (nonatomic, strong) RiistaCalendarViewController *calendarController;

@property (strong, nonatomic) NSMutableDictionary *cachedImages;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultController;

@end

const NSInteger BATCH_SIZE = 20;
const CGFloat ROW_HEIGHT = 55;
const CGFloat SEPARATOR_HEIGHT = 10;



@implementation RiistaGameLogViewController
{
    NSDateFormatter *dateFormatter;

    // Keeps track of language used when refreshing UI texts.
    NSString* previousLanguage;

    RiistaEntryType selectedLogType;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _cachedImages = [NSMutableDictionary new];
        _selectedYear = -1;

        [self refreshTabItem];
    }
    return self;
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"MenuGameLog", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor applicationColor:RiistaApplicationColorBackground];
    NSError *error = nil;
    [self.fetchedResultController performFetch:&error];
    
    dateFormatter = [NSDateFormatter new];
    [dateFormatter setLocale:[RiistaUtils appLocale]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarEntriesUpdated:) name:RiistaCalendarEntriesUpdatedKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageSelectionUpdated:) name:RiistaLanguageSelectionUpdatedKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userInfoUpdated:) name:RiistaUserInfoUpdatedKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logTypeSelected:) name:RiistaLogTypeSelectedKey object:nil];

    self.tableView.sectionFooterHeight = 0;

    _calendarController = [RiistaCalendarViewController new];
    _calendarController.delegate = self;
    [self addChildViewController:_calendarController];
    [self.calendarView addSubview:_calendarController.view];

    [self setupCalendarNavContent];

    [_harvestsButton addTarget:self action:@selector(selectHarvestLog:) forControlEvents:UIControlEventTouchUpInside];
    [_observationsButton addTarget:self action:@selector(selectObservationLog:) forControlEvents:UIControlEventTouchUpInside];
    [_srvasButton addTarget:self action:@selector(selectSrvaLog:) forControlEvents:UIControlEventTouchUpInside];

    [self setupArrows];

    [self selectHarvestLog:nil];

    [self setupButtonStyles];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupLocalizedTexts];

    [self setupButtonStyles];
    [self pageSelected];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupButtonStyles
{
    UserInfo *userInfo = [RiistaSettings userInfo];
    if ([userInfo.enableSrva boolValue]) {
        _srvasButton.hidden = NO;
        self.srvaTrailingConstraint.constant = 0;
    }
    else {
        _srvasButton.hidden = YES;
        self.srvaTrailingConstraint.constant = self.view.frame.size.width / 2;
    }

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];

    [_harvestsButton setupStyle];
    [_observationsButton setupStyle];
    [_srvasButton setupStyle];
}

- (void)setupArrows
{
    self.leftArrow.imageView.contentMode = UIViewContentModeCenter;
    self.rightArrow.imageView.contentMode = UIViewContentModeCenter;
    [self.leftArrow addTarget:self action:@selector(selectPreviousYear:) forControlEvents:UIControlEventTouchUpInside];
    [self.rightArrow addTarget:self action:@selector(selectNextYear:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)selectPreviousYear:(id)sender
{
    [self.calendarController selectPreviousYear:sender];
    [self setupCalendarNavContent];

    [self filterLogForSelectedTypeAndSeason];
}

- (void)selectNextYear:(id)sender
{
    [self.calendarController selectNextYear:sender];
    [self setupCalendarNavContent];

    [self filterLogForSelectedTypeAndSeason];
}

- (void)filterLogForSelectedTypeAndSeason
{
    if (selectedLogType == RiistaEntryTypeObservation) {
        [self filterLogEntries:@"ObservationEntry" forSeason:(int)[self.calendarController activeSeasonStartYear]];
    }
    else if (selectedLogType == RiistaEntryTypeHarvest) {
        [self filterLogEntries:@"DiaryEntry" forSeason:(int)[self.calendarController activeSeasonStartYear]];
    }
    else if (selectedLogType == RiistaEntryTypeSrva) {
        [self filterLogEntries:@"SrvaEntry" forSeason:(int)[self.calendarController activeSeasonStartYear]];
    }
}

- (void)filterLogEntries:(NSString*)forType forSeason:(int)seasonStart
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:forType inManagedObjectContext:self.fetchedResultController.managedObjectContext];
    [self.fetchedResultController.fetchRequest setEntity:entity];

    NSDate *startTime = [RiistaDateTimeUtils seasonStartForStartYear:seasonStart];
    NSDate *endTime = [RiistaDateTimeUtils seasonEndForStartYear:seasonStart];

    if (selectedLogType == RiistaEntryTypeSrva) {
        //Srva events use calendar years, not hunting years
        NSDateComponents *components = [NSDateComponents new];
        [components setYear:seasonStart + 1];
        [components setMonth:1];
        [components setDay:1];
        [components setHour:0];
        [components setMinute:0];
        [components setSecond:0];
        startTime = [[NSCalendar currentCalendar] dateFromComponents:components];

        [components setYear:seasonStart + 2];
        endTime = [[NSCalendar currentCalendar] dateFromComponents:components];
    }
    // Do not display entries waiting to be deleted
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@",
                              DiaryEntryOperationDelete, startTime, endTime];
    [self.fetchedResultController.fetchRequest setPredicate:predicate];

    NSError *error = nil;
    [self.fetchedResultController performFetch:&error];
    [self.tableView reloadData];
}

- (void)pageSelected
{
    self.navigationController.title = RiistaLocalizedString(@"Gamelog", nil);
    [self setupAddButton];
    [self setupLocalizedTexts];
    [self setupCalendarNavContent];
}

- (void)setupAddButton
{
    UIImage *addImage = [UIImage imageNamed:@"ic_menu_add.png"];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithImage:addImage landscapeImagePhone:addImage style:UIBarButtonItemStylePlain target:self action:@selector(addEntry:)];
    [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[addButton]];
}

- (void)setupLocalizedTexts
{
    RiistaLanguageRefresh;
    NSString* activeLanguage = [RiistaSettings language];

    // Switching language requires refreshing the whole season statistics data.
    // Avoid doing this update unless app language has actually changed since last update.
    if (![previousLanguage isEqualToString:activeLanguage])
    {
        previousLanguage = activeLanguage;
        [_harvestsButton setTitle:[RiistaLocalizedString(@"Game", nil) uppercaseString] forState:UIControlStateNormal];
        [_observationsButton setTitle:[RiistaLocalizedString(@"Observation", nil) uppercaseString] forState:UIControlStateNormal];

        [self calendarEntriesUpdated:nil];
    }
}

- (void)setupCalendarNavContent
{
    NSInteger startYear = [self.calendarController activeSeasonStartYear];
    NSInteger totalAmount = [self.calendarController activeSeasonTotalAmount];

    _seasonLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"%ld - %ld", nil), startYear, startYear+1];

    if (selectedLogType == RiistaEntryTypeHarvest) {
        _totalAmountLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"TotalCatchFormat", nil), totalAmount];
    }
    else if (selectedLogType == RiistaEntryTypeObservation) {
        _totalAmountLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"TotalObservationsFormat", nil), totalAmount];
    }
    else if (selectedLogType == RiistaEntryTypeSrva) {
        _seasonLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"%ld", nil), startYear + 1];
        _totalAmountLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"TotalSrvasFormat", nil), totalAmount];
    }

    _pageControl.currentPage = [self.calendarController activeSeasonIndex];
    _leftArrow.hidden = ![self.calendarController activeSeasonHasPrevious];
    _rightArrow.hidden = ![self.calendarController activeSeasonHasNext];
}

- (void)selectHarvestLog:(id) sender
{
    selectedLogType = RiistaEntryTypeHarvest;

    _harvestsButton.selected = YES;
    _observationsButton.selected = NO;
    _srvasButton.selected = NO;

    self.calendarController.startMonth = 7;
    [self resizeCalendarView:180];

    [self calendarEntriesUpdated:nil];
    [self setupCalendarNavContent];

    [self filterLogForSelectedTypeAndSeason];
}

- (void)selectObservationLog:(id) sender
{
    selectedLogType = RiistaEntryTypeObservation;

    _harvestsButton.selected = NO;
    _observationsButton.selected = YES;
    _srvasButton.selected = NO;

    self.calendarController.startMonth = 7;
    [self resizeCalendarView:180];

    [self calendarEntriesUpdated:nil];
    [self setupCalendarNavContent];

    [self filterLogForSelectedTypeAndSeason];
}

- (void)selectSrvaLog:(id)sender
{
    selectedLogType = RiistaEntryTypeSrva;

    _harvestsButton.selected = NO;
    _observationsButton.selected = NO;
    _srvasButton.selected = YES;

    self.calendarController.startMonth = 0;
    [self resizeCalendarView:100];

    [self calendarEntriesUpdated:nil];
    [self setupCalendarNavContent];

    [self filterLogForSelectedTypeAndSeason];
}

- (void)resizeCalendarView:(CGFloat)height
{
    CGRect frame = self.calendarView.frame;
    frame.size.height = height;
    self.calendarView.frame = frame;

    //Force layout update
    self.tableView.tableHeaderView = self.calendarView;
}

- (void)addEntry:(id)sender
{
    if (selectedLogType == RiistaEntryTypeHarvest) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"HarvestStoryboard" bundle:nil];
        RiistaLogGameViewController *destination = [sb instantiateInitialViewController];

        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
            [self.navigationController pushViewController:destination animated:YES];
        }];
        [segue perform];
    }
    else if (selectedLogType == RiistaEntryTypeObservation) {
        if (![[RiistaMetadataManager sharedInstance] hasObservationMetadata]) {
            DLog(@"No metadata");
            return;
        }

        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
        DetailsViewController *destination = [sb instantiateInitialViewController];

        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
            [self.navigationController pushViewController:destination animated:YES];
        }];
        [segue perform];
    }
    else if (selectedLogType == RiistaEntryTypeSrva) {
        if (![[RiistaMetadataManager sharedInstance] hasSrvaMetadata]) {
            DLog(@"No metadata");
            return;
        }

        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
        DetailsViewController *destination = [sb instantiateInitialViewController];
        destination.srvaNew = [NSNumber numberWithBool:YES];

        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
            [self.navigationController pushViewController:destination animated:YES];
        }];
        [segue perform];
    }
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedResultController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultController sections] objectAtIndex:section];
    RiistaCalendarSectionView *view = [[[NSBundle mainBundle] loadNibNamed:@"RiistaCalendarSectionView" owner:self options:nil] firstObject];
    DiaryEntry *entry = [[sectionInfo objects] firstObject];
    if (section > 0) {
        [self addBordersForSeparator:view.separatorView];
    } else {
        view.separatorView.hidden = YES;
    }
    view.containerView.layer.cornerRadius = 2.0f;
    [dateFormatter setLocale:[RiistaUtils appLocale]];
    [dateFormatter setDateFormat:@"MM"];
    NSString *dateString = [NSString stringWithFormat:@"%ld", (long)[entry.month integerValue]];
    NSDate *date = [dateFormatter dateFromString:dateString];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateFormat:@"LLLL"];
    
    NSString *yearText = @"";
    if (section > 0) {
        id<NSFetchedResultsSectionInfo> prevSectionInfo = [[self.fetchedResultController sections] objectAtIndex:section-1];
        NSInteger lastEventYear = [((DiaryEntry*)[[prevSectionInfo objects] lastObject]).year integerValue];
        if ([entry.year integerValue] != lastEventYear) {
            yearText = [NSString stringWithFormat:@"%ld ", (long)[entry.year integerValue]];
        }
    }
    view.monthLabel.text = [NSString stringWithFormat:@"%@%@", yearText,[[dateFormatter stringFromDate:date] capitalizedString]];

    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    [view setBackgroundColor:[UIColor clearColor]];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"eventCell";
    LogEventCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self addBordersForCell:cell];

    id item = [self.fetchedResultController objectAtIndexPath:indexPath];
    if ([item class] == [ObservationEntry class]) {
        return [self setupObservationCell:cell observation:item];
    }
    else if ([item class] == [DiaryEntry class]) {
        return [self setupHarvestCell:cell harvest:item];
    }
    else {
        return [self setupSrvaCell:cell srva:item];
    }
}

- (UITableViewCell*)setupHarvestCell:(LogEventCell*)cell harvest:(DiaryEntry*)entry
{
    cell.logImageView.image = nil;
    
    if (cell.logImage) {
        [cell.logImage removeObserver:cell forKeyPath:@"image"];
    }
    NSString *identifier = [entry.objectID.URIRepresentation absoluteString];

    LogImage *logImage = [self.cachedImages objectForKey:identifier];
    if (!logImage) {
        logImage = [LogImage new];
        self.cachedImages[identifier] = logImage;
    }
    cell.logImage = logImage;

    [self.cachedImages[identifier] addObserver:cell forKeyPath:@"image" options:0 context:NULL];

    [self loadImageForEntry:entry forImageView:cell.logImageView];

    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[entry.gameSpeciesCode integerValue]];
    cell.speciesLabel.text = @"-";
    NSString *name = [RiistaUtils nameWithPreferredLanguage:species.name];
    if (name) {
        cell.speciesLabel.text = name;

        if ([entry.amount intValue] > 1) {
            cell.speciesLabel.text = [cell.speciesLabel.text stringByAppendingFormat:@" (%@)", entry.amount];
        }
    }
    [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
    cell.dateLabel.text = [dateFormatter stringFromDate:entry.pointOfTime];
    
    if (entry.stateAcceptedToHarvestPermit != nil || entry.harvestReportState != nil || [entry.harvestReportRequired boolValue]) {
        [self setupHarvestState:cell permitState:entry.stateAcceptedToHarvestPermit reportState:entry.harvestReportState];
    }
    else {
        cell.statusIndicator.hidden = YES;
    }

    cell.sendStatusImageView.image = nil;
    if (![entry.sent boolValue]) {
        cell.sendStatusImageView.image = [UIImage imageNamed:@"ic_stat_upload.png"];
    }
    cell.eventTypeImageView.image = nil;
    if ([entry.type isEqual:DiaryEntryTypeHarvest]) {
        cell.eventTypeImageView.image = [UIImage imageNamed:@"ic_kaato.png"];
    }

    cell.frame = CGRectMake(0, SEPARATOR_HEIGHT, cell.frame.size.width, ROW_HEIGHT);

    return cell;
}

- (UITableViewCell*)setupObservationCell:(LogEventCell*)cell observation:(ObservationEntry*)observation
{
    cell.logImageView.image = nil;

    if (cell.logImage) {
        [cell.logImage removeObserver:cell forKeyPath:@"image"];
    }
    NSString *identifier = [observation.objectID.URIRepresentation absoluteString];

    LogImage *logImage = [self.cachedImages objectForKey:identifier];
    if (!logImage) {
        logImage = [LogImage new];
        self.cachedImages[identifier] = logImage;
    }
    cell.logImage = logImage;

    [self.cachedImages[identifier] addObserver:cell forKeyPath:@"image" options:0 context:NULL];

    [self loadImageForEntry:observation forImageView:cell.logImageView];

    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[observation.gameSpeciesCode integerValue]];
    cell.speciesLabel.text = @"-";
    NSString *name = [RiistaUtils nameWithPreferredLanguage:species.name];
    if (name) {
        cell.speciesLabel.text = name;

        if ([observation.totalSpecimenAmount intValue] > 1) {
            cell.speciesLabel.text = [cell.speciesLabel.text stringByAppendingFormat:@" (%@)", observation.totalSpecimenAmount];
        }
    }
    [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
    cell.dateLabel.text = [dateFormatter stringFromDate:observation.pointOfTime];

    cell.statusIndicator.hidden = YES;

    cell.sendStatusImageView.image = nil;
    if (![observation.sent boolValue]) {
        cell.sendStatusImageView.image = [UIImage imageNamed:@"ic_stat_upload.png"];
    }
    cell.eventTypeImageView.image = nil;
    if ([observation.type isEqual:DiaryEntryTypeObservation]) {
        cell.eventTypeImageView.image = [UIImage imageNamed:@"ic_observation.png"];
    }

    cell.frame = CGRectMake(0, SEPARATOR_HEIGHT, cell.frame.size.width, ROW_HEIGHT);

    return cell;
}

- (UITableViewCell*)setupSrvaCell:(LogEventCell*)cell srva:(SrvaEntry*)srva
{
    cell.logImageView.image = nil;
    cell.logImageView.tintColor = nil;

    if (cell.logImage) {
        [cell.logImage removeObserver:cell forKeyPath:@"image"];
    }
    NSString *identifier = [srva.objectID.URIRepresentation absoluteString];

    LogImage *logImage = [self.cachedImages objectForKey:identifier];
    if (!logImage) {
        logImage = [LogImage new];
        self.cachedImages[identifier] = logImage;
    }
    cell.logImage = logImage;

    [self.cachedImages[identifier] addObserver:cell forKeyPath:@"image" options:0 context:NULL];

    [self loadImageForEntry:srva forImageView:cell.logImageView];

    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[srva.gameSpeciesCode integerValue]];
    cell.speciesLabel.text = @"-";
    NSString *name = [RiistaUtils nameWithPreferredLanguage:species.name];
    if (srva.gameSpeciesCode == nil) {
        cell.logImageView.tintColor = [UIColor blackColor];
        name = RiistaLocalizedString(@"SrvaOtherSpeciesShort", nil);
    }
    if ([srva.totalSpecimenAmount intValue] > 1) {
        name = [name stringByAppendingFormat:@" (%@)", srva.totalSpecimenAmount];
    }
    if (srva.gameSpeciesCode == nil && srva.otherSpeciesDescription != nil) {
        NSString *other = srva.otherSpeciesDescription;
        NSInteger maxLength = 10;
        if (![srva.sent boolValue]) {
            maxLength -= 3;
        }

        if (other.length > maxLength) {
            //Manual elide
            other = [[other substringToIndex:maxLength] stringByAppendingString:@"..."];
        }
        name = [name stringByAppendingFormat:@" - %@", other];
    }
    if (name) {
        cell.speciesLabel.text = name;
    }

    [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
    cell.dateLabel.text = [dateFormatter stringFromDate:srva.pointOfTime];

    [self setupSrvaState:cell state:srva.state];

    cell.sendStatusImageView.image = nil;
    if (![srva.sent boolValue]) {
        cell.sendStatusImageView.image = [UIImage imageNamed:@"ic_stat_upload.png"];
    }
    cell.eventTypeImageView.image = nil;
    if ([srva.type isEqual:DiaryEntryTypeSrva]) {
        cell.eventTypeImageView.image = [UIImage imageNamed:@"ic_srva.png"];
    }

    cell.frame = CGRectMake(0, SEPARATOR_HEIGHT, cell.frame.size.width, ROW_HEIGHT);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];

    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row && self.selectedYear != -1){
        NSArray *sections = [self.fetchedResultController sections];
        for (int i=0; i<sections.count; i++) {
            id<NSFetchedResultsSectionInfo> sectionInfo = sections[i];
            DiaryEntry *entry = [[sectionInfo objects] firstObject];
            NSInteger startYear = [entry.month integerValue] < RiistaCalendarStartMonth ? [entry.year integerValue]-1 : [entry.year integerValue];
            if (startYear == self.selectedYear) {
                CGRect sectionRect = [self.tableView rectForSection:i];
                sectionRect.size.height = self.tableView.frame.size.height;
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                self.selectedYear = -1;
            }
        }
    }
}

- (void)addBordersForSeparator:(UIView*)view
{
    CALayer *borderLeft = [CALayer layer];
    borderLeft.backgroundColor = [UIColor grayColor].CGColor;
    borderLeft.frame = CGRectMake(0, 0, 1, view.frame.size.height);
    [view.layer addSublayer:borderLeft];
    CALayer *borderRight = [CALayer layer];
    borderRight.backgroundColor = [UIColor grayColor].CGColor;
    borderRight.frame = CGRectMake(view.frame.size.width-1, 0, 1, view.frame.size.height);
    [view.layer addSublayer:borderRight];
}

- (void)addBordersForCell:(LogEventCell*)cell
{
    [self addBordersForSeparator:cell.separatorView];
    cell.containerView.layer.borderColor = [UIColor applicationColor:RiistaApplicationColorDiaryCellBorder].CGColor;
    cell.containerView.layer.borderWidth = 1.0f;
    cell.containerView.layer.cornerRadius = 2.0f;
}

- (void)setupSrvaState:(LogEventCell*)cell state:(NSString*)state
{
    cell.statusIndicator.hidden = YES;
    cell.statusIndicator.layer.cornerRadius = cell.statusIndicator.frame.size.width / 2;

    if (state != nil) {
        if ([state isEqualToString:SrvaStateApproved]) {
            cell.statusIndicator.hidden = NO;
            cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusApproved];
        }
        else if ([state isEqualToString:SrvaStateRejected]) {
            cell.statusIndicator.hidden = NO;
            cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusRejected];
        }
    }
}

- (void)setupHarvestState:(LogEventCell*)cell permitState:(NSString*)permitState reportState:(NSString*)harvestState
{
    cell.statusIndicator.hidden = NO;
    cell.statusIndicator.layer.cornerRadius = cell.statusIndicator.frame.size.width/2;

    if ([permitState isEqual:DiaryEntryHarvestPermitProposed]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusProposed];
    } else if ([permitState isEqual:DiaryEntryHarvestPermitAccepted]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusAccepted];
    } else if ([permitState isEqual:DiaryEntryHarvestPermitRejected]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusRejected];
    } else if ([harvestState isEqual:DiaryEntryHarvestStateProposed]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusProposed];
    } else if ([harvestState isEqual:DiaryEntryHarvestStateSentForApproval]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusSentForApproval];
    } else if ([harvestState isEqual:DiaryEntryHarvestStateApproved]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusApproved];
    } else if ([harvestState isEqual:DiaryEntryHarvestStateRejected]) {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusRejected];
    } else {
        cell.statusIndicator.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusCreateReport];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return SEPARATOR_HEIGHT + ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (selectedLogType == RiistaEntryTypeObservation) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
        DetailsViewController *destination = [sb instantiateInitialViewController];
        [destination setObservationId:((ObservationEntry*)[self.fetchedResultController objectAtIndexPath:indexPath]).objectID];

        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
            [self.navigationController pushViewController:destination animated:YES];
        }];

        [segue perform];
    }
    else if (selectedLogType == RiistaEntryTypeHarvest) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"HarvestStoryboard" bundle:nil];
        RiistaLogGameViewController *destination = [sb instantiateInitialViewController];
        [destination setEventId:((DiaryEntry*)[self.fetchedResultController objectAtIndexPath:indexPath]).objectID];

        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
            [self.navigationController pushViewController:destination animated:YES];
        }];

        [segue perform];
    }
    else if (selectedLogType == RiistaEntryTypeSrva) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
        DetailsViewController *destination = [sb instantiateInitialViewController];
        [destination setSrvaId:((SrvaEntry*)[self.fetchedResultController objectAtIndexPath:indexPath]).objectID];

        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
            [self.navigationController pushViewController:destination animated:YES];
        }];

        [segue perform];
    }
}

#pragma mark - Fetched result controller
- (NSFetchedResultsController*)fetchedResultController
{
    if (_fetchedResultController != nil) {
        return _fetchedResultController;
    }
    RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedContext = delegate.managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryEntry" inManagedObjectContext:managedContext];
    [fetchRequest setEntity:entity];

    // Do not display entries waiting to be deleted
    int seasonStart = (int)[self.calendarController activeSeasonStartYear];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@", DiaryEntryOperationDelete, [RiistaDateTimeUtils seasonStartForStartYear:seasonStart], [RiistaDateTimeUtils seasonEndForStartYear:seasonStart]];
    [fetchRequest setPredicate:predicate];

    [fetchRequest setFetchBatchSize:BATCH_SIZE];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pointOfTime" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    _fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedContext sectionNameKeyPath:@"yearMonth" cacheName:@"Root"];
    
    return _fetchedResultController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView reloadData];
}

#pragma mark - NSNotificationCenter

- (void)calendarEntriesUpdated:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;

    // Clear cache for updated entries
    NSArray *entries = userInfo[@"entries"];
    for (int i=0; i<entries.count; i++) {
        RiistaDiaryEntryUpdate *update = entries[i];
        if (update.type == UpdateTypeInsert || update.type == UpdateTypeUpdate) {
            NSString *uri = [[update.entry.objectID URIRepresentation] absoluteString];
            if ([self.cachedImages objectForKey:uri]) {
                [self.cachedImages removeObjectForKey:uri];
            }
        }
    }

    NSError *error = nil;
    [self.fetchedResultController performFetch:&error];
    [self.tableView reloadData];

    NSString* entryType;
    if (selectedLogType == RiistaEntryTypeHarvest) {
        entryType = DiaryEntryTypeHarvest;
    }
    else if (selectedLogType == RiistaEntryTypeObservation) {
        entryType = DiaryEntryTypeObservation;
    }
    else if (selectedLogType == RiistaEntryTypeSrva) {
        entryType = DiaryEntryTypeSrva;
    }

    NSArray *years = [[RiistaGameDatabase sharedInstance] eventYears:entryType];
    [self.calendarController setupCalendarYears:years];
    [self setupCalendarNavContent];
}

- (void)languageSelectionUpdated:(NSNotification*)notification
{
    RiistaLanguageRefresh;

    NSError *error = nil;
    [self.fetchedResultController performFetch:&error];
    [self.tableView reloadData];
}

- (void)userInfoUpdated:(NSNotification*)notification
{
    [self setupButtonStyles];
}

- (void)logTypeSelected:(NSNotification*)notification
{
    RiistaEntryType type = [notification.object intValue];

    if (type == RiistaEntryTypeHarvest) {
        [self selectHarvestLog:nil];
    }
    else if (type == RiistaEntryTypeObservation) {
        [self selectObservationLog:nil];
    }
    else if (type == RiistaEntryTypeSrva) {
        [self selectSrvaLog:nil];
    }
}

- (void)loadImageForEntry:(DiaryEntryBase*)entry forImageView:(UIImageView*)imageView
{
    NSString *identifier = [entry.objectID.URIRepresentation absoluteString];
    LogImage *logImage = [self.cachedImages objectForKey:identifier];
    
    if (logImage.image) {
        imageView.image = logImage.image;
    } else {
        [RiistaUtils loadEventImage:entry forImageView:imageView completion:^(UIImage* image) {
            if (logImage && image) {
                logImage.image = image;
            }
        }];
    }
}

# pragma mark - RiistaCalendarDelegate methods

- (RiistaCalendarYear*)dataForYear:(NSInteger)startYear
{
    RiistaCalendarYear *newData;

    if (selectedLogType == RiistaEntryTypeObservation) {
        newData = [[RiistaGameDatabase sharedInstance] observationStatisticsForYear:startYear];
    }
    else if (selectedLogType == RiistaEntryTypeHarvest) {
        newData = [[RiistaGameDatabase sharedInstance] statisticsForYear:startYear];
    }
    else if (selectedLogType == RiistaEntryTypeSrva) {
        newData = [[RiistaGameDatabase sharedInstance] srvaStatisticsForYear:startYear];
    }
    return newData;
}

- (void)calendarYearClicked:(NSInteger)year
{
    // Not used
}

@end

@implementation RiistaCalendarSectionView
@end

@implementation LogEventCell

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object)
        self.logImageView.image = ((LogImage*)object).image;
}

- (void)dealloc
{
    if (self.logImage) {
        [self.logImage removeObserver:self forKeyPath:@"image"];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self setStyleForHighlighted:highlighted];
}

- (void)setStyleForHighlighted:(BOOL)highlighted
{
    const CGFloat textAlpha = highlighted ? 0.5 : 1.0;
    self.speciesLabel.alpha = textAlpha;
    self.dateLabel.alpha = textAlpha;
}

@end

@implementation LogImage
@end
