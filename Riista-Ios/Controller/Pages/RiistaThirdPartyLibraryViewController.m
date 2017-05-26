#import "RiistaThirdPartyLibraryViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaLocalization.h"

@interface RiistaThirdPartyLibraryViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;

@end

@implementation RiistaThirdPartyLibraryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentWebView.delegate = self;
    [self loadThirdPartyPage];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
}

- (void)loadThirdPartyPage
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ThirdPartyLibraries" ofType:@"html"];
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self.contentWebView loadHTMLString:content baseURL:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeOther) {
        // Initial html loading
        return YES;
    } else if ([[request.URL lastPathComponent] isEqualToString:@"ThirdPartyLibraries.html"]) {
        return YES;
    } else {
        // All other links will be handled by the external web browser
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
}

@end
