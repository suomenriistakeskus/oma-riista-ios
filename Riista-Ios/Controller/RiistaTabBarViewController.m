#import "RiistaTabBarViewController.h"
#import "RiistaLocalization.h"
#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaSessionManager.h"
#import "RiistaPermitManager.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "RiistaLoginViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaPageViewController.h"
#import "RiistaClubAreaMapManager.h"
#import "DiaryEntryBase.h"
#import "Oma_riista-Swift.h"

@import Firebase;

@interface RiistaTabBarViewController () <LoginDelegate>

@property (strong, nonatomic) RiistaLoginViewController *loginController;

@end

@implementation RiistaTabBarViewController

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
    else {
        //Always relogin to get updated session cookies and also update metadata, push tokens etc.
        RiistaCredentials *credentials = [[RiistaSessionManager sharedInstance] userCredentials];
        if (credentials) {
            [[RiistaNetworkManager sharedInstance] relogin:credentials.username password:credentials.password completion:^(NSError *error) {
                    [[RiistaGameDatabase sharedInstance] initUserSession];
            }];
        };
    }
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
    [[RiistaSessionManager sharedInstance] removeCredentials];
    [RiistaSettings setUserInfo:nil];
    [RiistaSettings setOnboardingShownVersion:nil];

    [[RiistaPermitManager sharedInstance] clearPermits];
    [RiistaGameDatabase sharedInstance].autosync = NO;
    [RiistaUtils markAllAnnouncementsAsRead];
    [RiistaClubAreaMapManager clearCache];
    [[FIRInstanceID instanceID] deleteIDWithHandler:^(NSError * _Nullable error) {
        NSLog(@"Deleted Firebase id: %@", error);
    }];

    [self.navigationController popToRootViewControllerAnimated:NO];
    [self showLoginControllerAnimated:YES];
}

- (void)showLoginControllerAnimated:(BOOL)animated
{
    self.loginController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginController"];
    self.loginController.delegate = self;

    [self.navigationController setNavigationBarHidden:YES];

    if (animated) {
        [self.loginController willMoveToParentViewController:self];
        self.loginController.view.alpha = 0;
        [self.view addSubview:self.loginController.view];
        // Not called automatically since adding to view hierarchy directly
        [self.loginController viewWillAppear:animated];
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            self.loginController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self.loginController didMoveToParentViewController:self];
        }];
    } else {
        [self.loginController willMoveToParentViewController:self];
        [self.view addSubview:self.loginController.view];
        // Not called automatically since adding to view hierarchy directly
        [self.loginController viewWillAppear:animated];
        [self.loginController didMoveToParentViewController:self];
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

#pragma mark - LoginDelegate

- (void)didLogin
{
    [self removeLoginController];
    [[RiistaGameDatabase sharedInstance] initUserSession];

    [self setSelectedViewController:[self.viewControllers objectAtIndex:0]];
}

- (void)removeLoginController
{
    [self.navigationController setNavigationBarHidden:NO];

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.loginController.view.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.loginController willMoveToParentViewController:nil];
                         [self.loginController.view removeFromSuperview];
                         [self.loginController removeFromParentViewController];
                         self.loginController = nil;
                     }];
}

@end
