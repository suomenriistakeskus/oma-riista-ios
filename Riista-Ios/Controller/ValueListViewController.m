#import "RiistaLocalization.h"
#import "RiistaNavigationController.h"
#import "RiistaUtils.h"
#import "ValueListViewController.h"

@interface RiistaValueListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *valueTextLabel;

@end

@interface ValueListViewController ()

@property (strong, nonatomic) NSMutableDictionary *textMappingOverrides;

@end

@implementation ValueListViewController

@synthesize textMappingOverrides;

- (void)viewDidLoad {
    [super viewDidLoad];

    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle:self.titlePrompt];

    self.tableView.tableFooterView = [UIView new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [(RiistaNavigationController*)self.navigationController setRightBarItems:nil];
}

- (void)setTextKeyOverride:(NSString *)key overrideKey:(NSString*)overrideKey
{
    if (!self.textMappingOverrides) {
        self.textMappingOverrides = [NSMutableDictionary new];
    }
    [self.textMappingOverrides setObject:overrideKey forKey:key];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.values.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    RiistaValueListCell *cell = (RiistaValueListCell*)[tableView dequeueReusableCellWithIdentifier:@"valueListCell"];

    NSString *key = self.values[indexPath.row];
    if ([self textMappingOverrides][key]) {
        key = [self textMappingOverrides][key];
    }

    cell.valueTextLabel.text = RiistaMappedValueString(key, nil);
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.delegate) {
        [self.delegate valueSelectedForKey:self.fieldKey value:self.values[indexPath.row]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}

@end

@implementation RiistaValueListCell

@end
