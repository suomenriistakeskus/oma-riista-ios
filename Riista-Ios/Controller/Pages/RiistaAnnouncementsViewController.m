#import "Announcement.h"
#import "AnnouncementSender.h"
#import "RiistaAnnouncementsViewController.h"
#import "RiistaAppDelegate.h"
#import "RiistaLocalization.h"
#import "RiistaPageViewController.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "UIColor+ApplicationColor.h"

@interface AnnouncementCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *timeView;
@property (weak, nonatomic) IBOutlet UILabel *senderNameView;
@property (weak, nonatomic) IBOutlet UILabel *roleView;
@property (weak, nonatomic) IBOutlet UILabel *organisationView;
@property (weak, nonatomic) IBOutlet UILabel *messageView;
@property (weak, nonatomic) IBOutlet UILabel *showAllView;

@end

@interface RiistaAnnouncementsViewController () <RiistaPageDelegate, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *stateMessageLagel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultController;

@end

@implementation RiistaAnnouncementsViewController
{
    NSDateFormatter *dateFormatter;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"MenuAnnouncements", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = nil;
    self.tableView.tableFooterView = nil;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120;

    NSError *error = nil;
    [self.fetchedResultController performFetch:&error];

    dateFormatter = [NSDateFormatter new];
    [dateFormatter setLocale:[RiistaUtils appLocale]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RiistaLanguageRefresh;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self pageSelected];

    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pageSelected
{
    self.navigationController.title = RiistaLocalizedString(@"Announcements", nil);
    self.stateMessageLagel.text = RiistaLocalizedString(@"AnnouncementsNone", nil);
}

- (void)toggleAnnouncementExpand:(UITableView *)tableView indexPath:(NSIndexPath*)indexPath
{
    AnnouncementCell *cell = (AnnouncementCell*)[tableView cellForRowAtIndexPath:indexPath];

    if (cell.messageView.numberOfLines == 0) {
        cell.messageView.numberOfLines = 3;
        cell.showAllView.hidden = NO;
    }
    else {
        cell.messageView.numberOfLines = 0;
        cell.showAllView.hidden = YES;
    }

    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    NSUInteger count = [[self.fetchedResultController sections] count];
    self.stateMessageLagel.hidden = count && count > 0 ? YES : NO;

    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultController sections] objectAtIndex:section];

    NSUInteger count = [sectionInfo numberOfObjects];
    self.stateMessageLagel.hidden = count && count > 0 ? YES : NO;

    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"announcementCell";
    AnnouncementCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil)
    {
        cell = [[AnnouncementCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    cell.showAllView.text = RiistaLocalizedString(@"DisplayAll", nil);
    [self addBordersForCell:cell];

    id item = [self.fetchedResultController objectAtIndexPath:indexPath];
    return [self setupCell:cell item:item];
}

- (UITableViewCell*)setupCell:(AnnouncementCell*)cell item:(Announcement*)item
{
    cell.titleView.text = item.subject;

    [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
    cell.timeView.text = [dateFormatter stringFromDate:item.pointOfTime];

    cell.messageView.text = item.body;

    AnnouncementSender *sender = item.sender;
    NSString *langCode = [RiistaSettings language];
    NSString *titleText = [sender.title objectForKey:langCode] ? [sender.title objectForKey:langCode] : [sender.title objectForKey:@"fi"];
    NSString *organisationText = [sender.organisation objectForKey:langCode] ? [sender.organisation objectForKey:langCode] : [sender.organisation objectForKey:@"fi"];

    cell.senderNameView.text = sender.fullName;
    cell.roleView.text = titleText;
    cell.organisationView.text = organisationText;

    return cell;
}

- (void)addBordersForCell:(AnnouncementCell*)cell
{
    cell.cardView.layer.borderColor = [UIColor applicationColor:RiistaApplicationColorDiaryCellBorder].CGColor;
    cell.cardView.layer.borderWidth = 1.0f;
    cell.cardView.layer.cornerRadius = 5.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self toggleAnnouncementExpand:tableView indexPath:indexPath];
}

#pragma mark - Fetched result controller

- (NSFetchedResultsController*)fetchedResultController
{
    if (_fetchedResultController != nil) {
        return _fetchedResultController;
    }
    RiistaAppDelegate *delegate = (RiistaAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedContext = delegate.managedObjectContext;

    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Announcement" inManagedObjectContext:managedContext];
    [fetchRequest setEntity:entity];

    [fetchRequest setFetchBatchSize:20];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pointOfTime" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    _fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:managedContext
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    _fetchedResultController.delegate = self;

    return _fetchedResultController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView reloadData];
}

@end

@implementation AnnouncementCell

@end
