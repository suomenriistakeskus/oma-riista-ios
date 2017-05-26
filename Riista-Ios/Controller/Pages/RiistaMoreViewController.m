#import "RiistaMoreViewController.h"
#import "RiistaLocalization.h"
#import "RiistaTabBarViewController.h"

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

@property (strong, nonatomic) NSArray *listItems;

@end

@implementation RiistaMoreViewController

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = nil;
    self.tableView.tableFooterView = nil;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    self.listItems = @[[[MoreItem alloc] initWithIcon:@"ic_nav_contact.png" title:@"MenuContactDetails"],
                       [[MoreItem alloc] initWithIcon:@"ic_nav_settings.png" title:@"MenuSettings"],
                       [[MoreItem alloc] initWithIcon:@"ic_logout.png" title:@"Logout"]
                       ];
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
    self.navigationController.title = RiistaLocalizedString(@"MenuMore", nil);
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
    UIAlertView *alert;

    switch (indexPath.row) {
        case 0:
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ContactDetailsController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        case 1:
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        case 2:
            alert = [[UIAlertView alloc] initWithTitle:[RiistaLocalizedString(@"Logout", nil) stringByAppendingString:@"?"]
                                               message:nil
                                              delegate:self
                                     cancelButtonTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                     otherButtonTitles:RiistaLocalizedString(@"OK", nil), nil];
            [alert show];
            break;
        default:
            break;
    }
}

# pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [(RiistaTabBarViewController*)self.tabBarController logout];
            break;
        case 0:
        default:
            break;
    }
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
