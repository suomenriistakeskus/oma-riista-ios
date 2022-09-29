#import "RiistaMagazineViewController.h"
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

    self.title = @"Oma riista";

    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlAddress]];

    [self.contentWebView loadRequest:requestObj];
}

@end
