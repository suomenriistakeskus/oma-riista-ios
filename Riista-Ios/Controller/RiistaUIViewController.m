#import "RiistaPageViewController.h"
#import "RiistaUIViewController.h"
#import "Oma_riista-Swift.h"

@interface RiistaUIViewController () <RiistaPageDelegate>

@end

@implementation RiistaUIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *breadcrumb = [NSString stringWithFormat:@"%@ - viewWillAppear(_:)", NSStringFromClass([self class])];
    [CrashlyticsHelper breadcrumbWithBreadcrumb:breadcrumb];
}

#pragma mark - RiistaPageDelegate

- (void)pageSelected
{
}

#pragma mark

@end
