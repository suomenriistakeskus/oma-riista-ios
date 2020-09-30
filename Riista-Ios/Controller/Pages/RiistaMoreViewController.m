#import "RiistaMoreViewController.h"
#import "RiistaLocalization.h"
#import "RiistaSettings.h"
#import "RiistaTabBarViewController.h"
#import "RiistaMagazineViewController.h"
#import "RiistaNavigationController.h"
#import "UserInfo.h"

#import "Oma_riista-Swift.h"

@interface MoreItem : NSObject

@property (strong, nonatomic) NSString *iconResource;
@property (strong, nonatomic) NSString *titleResource;

- (id)initWithIcon:(NSString*)icon title:(NSString*)title;

@end

@interface MoreItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@end

@interface RiistaMoreViewController () <RiistaPageDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *listItems;
@property (nonatomic) BOOL displayShootingTests;

@end

@implementation RiistaMoreViewController

const NSInteger SHOOTING_TEST_INDEX = 4;

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.displayShootingTests = [[RiistaSettings userInfo] isShootingTestOfficial];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = nil;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    self.listItems = [NSMutableArray arrayWithArray:@[[[MoreItem alloc] initWithIcon:@"more_person" title:@"MyDetails"],
                                                      [[MoreItem alloc] initWithIcon:@"more_gallery" title:@"Gallery"],
                                                      [[MoreItem alloc] initWithIcon:@"more_contacts" title:@"MenuContactDetails"],
                                                      [[MoreItem alloc] initWithIcon:@"more_settings" title:@"MenuSettings"],
                                                      [[MoreItem alloc] initWithIcon:@"more_search" title:@"MenuEventSearch"],
                                                      [[MoreItem alloc] initWithIcon:@"more_magazine" title:@"MenuReadMagazine"],
                                                      [[MoreItem alloc] initWithIcon:@"more_seasons" title:@"MenuOpenSeasons"],
                                                      [[MoreItem alloc] initWithIcon:@"more_logout" title:@"Logout"],
                                                      ]];
    if (self.displayShootingTests) {
        [self.listItems insertObject:[[MoreItem alloc] initWithIcon:@"more_shooting" title:@"MenuShootingTests"]
                             atIndex:SHOOTING_TEST_INDEX];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    [self pageSelected];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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

    navController.title = RiistaLocalizedString(@"MenuMore", nil);
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"MenuMore", nil);
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
   return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.listItems count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"moreItemCell";
    MoreItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil)
    {
        cell = [[MoreItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    id item = self.listItems[indexPath.row];
    return [self setupCell:cell item:item];
}

- (UITableViewCell*)setupCell:(MoreItemCell*)cell item:(MoreItem*)item
{
    cell.iconView.image = [UIImage imageNamed:item.iconResource];
    cell.titleView.text = RiistaLocalizedString(item.titleResource, nil);

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UIViewController *controller;
    
    switch (indexPath.row) {
        case 0:
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MyDetailsController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        case 1:
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"GalleryController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        case 2:
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ContactDetailsController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        case 3:
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        case 4:
            if (self.displayShootingTests) {
                [self didSelectShootingTests];
            }
            else {
                [self didSelectEventSearch];
            }
            break;
        case 5:
            if (self.displayShootingTests) {
                [self didSelectEventSearch];
            }
            else {
                [self didSelectMagazine];
            }
            break;
        case 6:
            if (self.displayShootingTests) {
                [self didSelectMagazine];
            }
            else {
                [self didSelectHuntingSeasons];
            }
            break;
        case 7:
            if (self.displayShootingTests) {
                [self didSelectHuntingSeasons];
            }
            else {
                [self didSelectLogout];
            }
            break;
        case 8:
            [self didSelectLogout];
            break;
        default:
            break;
    }
}

- (void) didSelectShootingTests
{
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ShootingTestCalendarEventsController"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void) didSelectEventSearch
{
    NSString *language = [RiistaSettings language];
    NSURL *url;

    if ([@"sv" isEqualToString:language]) {
        url = [NSURL URLWithString:EventSearchSv];
    }
    else {
        url = [NSURL URLWithString:EventSearchFi];
    }

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void) didSelectMagazine
{
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MagazineController"];

    if ([[RiistaSettings language] isEqualToString:@"sv"]) {
        ((RiistaMagazineViewController*)controller).urlAddress = MagazineUrlSv;
    }
    else {
        ((RiistaMagazineViewController*)controller).urlAddress = MagazineUrlFi;
    }
    [self.navigationController pushViewController:controller animated:YES];
}

- (void) didSelectHuntingSeasons
{
    NSString *language = [RiistaSettings language];
    NSURL *url;

    if ([@"sv" isEqualToString:language]) {
        url = [NSURL URLWithString:HuntingSeasonsUrlSv];
    }
    else if ([@"en" isEqualToString:language]) {
        url = [NSURL URLWithString:HuntingSeasonsUrlEn];
    }
    else {
        url = [NSURL URLWithString:HuntingSeasonsUrlFi];
    }

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void) didSelectLogout
{
    MDCAlertController *alertController =
    [MDCAlertController alertControllerWithTitle:[RiistaLocalizedString(@"Logout", nil) stringByAppendingString:@"?"]
                                         message:nil];

    MDCAlertAction *cancelAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                          handler:^(MDCAlertAction *action) {
        // Do nothing
    }];
    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                          handler:^(MDCAlertAction *action) {
        [(RiistaTabBarViewController*)self.tabBarController logout];
    }];

    [alertController addAction:cancelAction];
    [alertController addAction:okAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end

@implementation MoreItem

- (id)initWithIcon:(NSString *)icon title:(NSString *)title
{
    self = [super init];
    if (self)
    {
        _iconResource = icon;
        _titleResource = title;
    }
    return self;
}

@end

@implementation MoreItemCell

@end
