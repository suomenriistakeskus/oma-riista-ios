#import "RiistaMagazineViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaLocalization.h"
#import "RiistaSettings.h"

@interface RiistaMagazineViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;

@end

@implementation RiistaMagazineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.contentWebView.delegate = self;

    [self updateTitle];

    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlAddress]];

    [self.contentWebView loadRequest:requestObj];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle:RiistaLocalizedString(@"Oma riista", nil)];
}

- (NSURL*)createMagazineUrl
{
    if ([[RiistaSettings language] isEqualToString:@"sv"]) {
        return [NSURL URLWithString:MagazineUrlSv];
    }
    else {
        return [NSURL URLWithString:MagazineUrlFi];
    }
}

@end
