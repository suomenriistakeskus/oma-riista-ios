#import "RiistaTabBarViewController.h"
#import "RiistaLocalization.h"
#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaSessionManager.h"
#import "RiistaPermitManager.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "RiistaNavigationController.h"
#import "RiistaPageViewController.h"
#import "RiistaClubAreaMapManager.h"
#import "DiaryEntryBase.h"
#import "Oma_riista-Swift.h"

@import Firebase;

@interface RiistaTabBarViewController () <AuthenticationViewControllerDelegate>

@property (strong, nonatomic) AuthenticationViewController *authenticationController;

@end


@implementation RiistaTabBarViewController
{
    // currently logging in?
    BOOL loggingIn;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logout) name:RiistaReloginFailedKey object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenuTexts) name:RiistaLanguageSelectionUpdatedKey object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logEntrySaved) name:RiistaLogEntrySavedKey object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenuTexts) name:RiistaPushAnnouncementKey object:nil];
    }

    [self.moreNavigationController.navigationBar setHidden:YES];

    [self.moreNavigationController setDelegate:self];

    // UITabBarControllerDelegate
    [self setDelegate:self];

    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Hides edit button
    self.customizableViewControllers = nil;
}

- (void)updateMenuTexts
{
    RiistaLanguageRefresh;

    // Must only set title for visible tabs or layout breaks (bug in iOS10)
    NSInteger vcCount = [self.viewControllers count];
    NSInteger maxVisibleTabs = 5;

    for (int i = 0; i < vcCount && i < maxVisibleTabs; i++) {
        RiistaPageViewController *vc = (RiistaPageViewController*)self.viewControllers[i];
        [vc refreshTabItem];
    }
}

- (void)logEntrySaved
{
    [self setSelectedViewController:[self.viewControllers objectAtIndex:1]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadView {
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tint for more menu icons
    self.moreNavigationController.topViewController.view.tintColor = [UIColor colorWithRed:55.0/256 green:149.0/256 blue:62.0/256 alpha:1];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autosyncStatusChanged:) name:RiistaAutosyncKey object:nil];

    // Only show login form if user hasn't stored credentials
    if (![[RiistaSessionManager sharedInstance] userCredentials]) {
        [self showLoginControllerAnimated:NO];
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.authenticationController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)autosyncStatusChanged:(NSNotification*)notification
{
    UINavigationController *navigationController = (UINavigationController*)self.navigationController;
    if (navigationController && [navigationController isKindOfClass:[RiistaNavigationController class]]) {
        ((RiistaNavigationController*)navigationController).syncStatus = [notification.userInfo[@"syncing"] boolValue];
    }
}

- (void)logout
{
    [RiistaSDKHelper logout];
    [[RiistaSessionManager sharedInstance] removeCredentials];
    [RiistaSettings setUserInfo:nil];
    [RiistaSettings setUseExperimentalMode:NO];

    [[RiistaPermitManager sharedInstance] clearPermits];
    [RiistaGameDatabase sharedInstance].autosync = NO;
    [RiistaUtils markAllAnnouncementsAsRead];
    [RiistaClubAreaMapManager clearCache];

    // Just delete the Firebase Cloud Messaging token. We don't want to delete the Installations id as that would
    // corrupt the analytics on how the app is updated etc
    [[FIRMessaging messaging] deleteTokenWithCompletion:^(NSError * _Nullable error) {
        NSLog(@"Deleted Firebase id: %@", error);
    }];

    [self.navigationController popToRootViewControllerAnimated:NO];
    [self showLoginControllerAnimated:YES];
}

- (BOOL)isDisplayingLoginScreen
{
    return loggingIn;
}

- (void)showLoginControllerAnimated:(BOOL)animated
{
    // Add the authentication controller as a child view controller. Ideally we would probably
    // want to present it but doing it so displays the home screen shortly before authentication
    // view controller is displayed
    // -> UI seems broken
    self.authenticationController = [[AuthenticationViewController alloc] init];
    self.authenticationController.delegate = self;


    loggingIn = YES;
    [self.navigationController setNavigationBarHidden:YES];

    [self addChildViewController:self.authenticationController];

    [self.view addSubview:self.authenticationController.view];
    self.authenticationController.view.frame = self.view.frame;
    [self.authenticationController willMoveToParentViewController:self];

    [self setNeedsStatusBarAppearanceUpdate];

    if (animated) {
        self.authenticationController.view.alpha = 0;
        // Not called automatically since adding to view hierarchy directly
        [self.authenticationController viewWillAppear:animated];
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            self.authenticationController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self.authenticationController didMoveToParentViewController:self];
        }];
    } else {
        // Not called automatically since adding to view hierarchy directly
        [self.authenticationController viewWillAppear:animated];
        [self.authenticationController didMoveToParentViewController:self];
    }
}

- (void)confirmLogout
{
    MDCAlertController *alert = [MDCAlertController alertControllerWithTitle:[RiistaLocalizedString(@"Logout", nil) stringByAppendingString:@"?"]
                                                                     message:nil];

    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil) handler:^(MDCAlertAction * _Nonnull action) {
        [self logout];
    }];
    MDCAlertAction *cancelAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                           handler:^(MDCAlertAction * _Nonnull action) {
        // Do nothing
    }];

    [alert addAction:cancelAction];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

# pragma mark - UITabBarControllerDelegate

- (BOOL) tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:NSClassFromString(@"UIMoreNavigationController")]) {
        // Do not remember navigation when returning to more item
        [self.moreNavigationController popToRootViewControllerAnimated:NO];

        return YES;
    }

    if ([viewController isKindOfClass:NSClassFromString(@"RiistaLogoutViewController")]) {
        [self confirmLogout];

        return NO;
    }

    return YES;
}

# pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([navigationController isKindOfClass:NSClassFromString(@"UIMoreNavigationController")]) {
        if ([self.navigationController isKindOfClass:[RiistaNavigationController class]]) {
            [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[]];
        }

        if ([viewController isKindOfClass:NSClassFromString(@"RiistaThirdPartyLibraryViewController")]) {
            self.navigationController.title = RiistaLocalizedString(@"ThirdPartyLibraries", nil);
        }
        else {
            self.navigationController.title = RiistaLocalizedString(@"MenuMore", nil);
        }
    }
}

#pragma mark - AuthenticationViewControllerDelegate

- (void)onLoggedIn
{
    loggingIn = NO;
    [self removeLoginController];
    [[RiistaGameDatabase sharedInstance] initUserSession];

    [self setSelectedViewController:[self.viewControllers objectAtIndex:0]];
}

- (void)removeLoginController
{
    [self.navigationController setNavigationBarHidden:NO];

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.authenticationController.view.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.authenticationController willMoveToParentViewController:nil];
                         [self.authenticationController.view removeFromSuperview];
                         [self.authenticationController removeFromParentViewController];
                         self.authenticationController = nil;

                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
}

@end
