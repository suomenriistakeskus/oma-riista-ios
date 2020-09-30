#import "Announcement.h"
#import "AnnouncementSender.h"
#import "AnnouncementsSync.h"
#import "RiistaAnnouncementsViewController.h"
#import "RiistaAppDelegate.h"
#import "RiistaLocalization.h"
#import "RiistaPageViewController.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "UIColor+ApplicationColor.h"
#import "CheckOsVersionMacros.h"
#import "NSDateformatter+Locale.h"
#import "Oma_riista-Swift.h"

@interface AnnouncementCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageView;
@property (weak, nonatomic) IBOutlet UILabel *showAllView;

@end

@interface RiistaAnnouncementsViewController () <RiistaPageDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

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

    [self refreshBadge];
}

- (void)refreshBadge
{
    NSInteger unread = [RiistaUtils unreadAnnouncementCount];
    if (unread > 0) {
        self.tabBarItem.badgeValue = [@(unread) stringValue];
    }
    else {
        self.tabBarItem.badgeValue = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableHeaderView = nil;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120;

    NSError *error = nil;
    [self.fetchedResultController performFetch:&error];

    dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
    [dateFormatter setDateFormat:@"dd.MM.yyyy"];

    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    self.tableView.refreshControl.backgroundColor = [UIColor whiteColor];
    self.tableView.refreshControl.tintColor = [UIColor blackColor];
    [self.tableView.refreshControl addTarget:self
                                      action:@selector(pullToRefresh)
                            forControlEvents:UIControlEventValueChanged];
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
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController setLeftBarItem:nil];
    [navController setRightBarItems:nil];

    navController.title = RiistaLocalizedString(@"Announcements", nil);

    self.stateMessageLagel.text = RiistaLocalizedString(@"AnnouncementsNone", nil);

    [RiistaUtils markAllAnnouncementsAsRead];
    [self refreshBadge];
}

- (void)pullToRefresh
{
    if (self.tableView.refreshControl) {
        NSString *title = @"";
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor blackColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.tableView.refreshControl.attributedTitle = attributedTitle;
    }

    [[AnnouncementsSync new] sync:^(NSArray *items, NSError *error) {
        [self.tableView.refreshControl endRefreshing];

        // Ignore all errors including common ones like no network and session expired
    }];
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

    id item = [self.fetchedResultController objectAtIndexPath:indexPath];
    return [self setupCell:cell item:item index:indexPath];
}

- (UITableViewCell*)setupCell:(AnnouncementCell*)cell item:(Announcement*)item index:(NSIndexPath*)index
{
    cell.subjectLabel.text = item.subject;
    cell.timeLabel.text = [dateFormatter stringFromDate:item.pointOfTime];
    cell.messageView.text = item.body;

    AnnouncementSender *sender = item.sender;
    NSString *langCode = [RiistaSettings language];
    NSString *titleText = [sender.title objectForKey:langCode] ? [sender.title objectForKey:langCode] : [sender.title objectForKey:@"fi"];
    NSString *organisationText = [sender.organisation objectForKey:langCode] ? [sender.organisation objectForKey:langCode] : [sender.organisation objectForKey:@"fi"];

    cell.senderLabel.text = [NSString stringWithFormat:@"%@ - %@", titleText, organisationText];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    Announcement *item = [self.fetchedResultController objectAtIndexPath:indexPath];
    if (!item) {
        return;
    }

    AnnouncementViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AnnouncementController"];
    controller.item = item;
    [self.navigationController pushViewController:controller animated:true];
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
