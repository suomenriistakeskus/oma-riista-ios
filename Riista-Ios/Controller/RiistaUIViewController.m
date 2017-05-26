#import "RiistaPageViewController.h"
#import "RiistaUIViewController.h"
#import "RiistaNavigationController.h"

@interface RiistaUIViewController () <RiistaPageDelegate>

@end

@implementation RiistaUIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupEmptyRightBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - RiistaPageDelegate

- (void)pageSelected
{
    self.navigationController.title = @"";
}

#pragma mark

- (void)setupEmptyRightBar
{
    if ([self.navigationController isKindOfClass:[RiistaNavigationController class]]) {
        [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[]];
    }
}

@end
