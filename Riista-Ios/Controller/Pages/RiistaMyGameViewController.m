#import "RiistaMyGameViewController.h"
#import "RiistaLocalization.h"
#import "UIColor+ApplicationColor.h"
#import "UserInfo.h"
#import "RiistaSettings.h"
#import "Oma_riista-Swift.h"

@interface RiistaMyGameViewController ()

@property (weak, nonatomic) IBOutlet MaterialVerticalButton *logHarvestButton;
@property (weak, nonatomic) IBOutlet MDCButton *quickHarvestButton1;
@property (weak, nonatomic) IBOutlet MDCButton *quickHarvestButton2;

@property (weak, nonatomic) IBOutlet MaterialVerticalButton *logObservationButton;
@property (weak, nonatomic) IBOutlet MDCButton *quickObservationButton1;
@property (weak, nonatomic) IBOutlet MDCButton *quickObservationButton2;

@property (weak, nonatomic) IBOutlet MDCCard *srvaCard;
@property (weak, nonatomic) IBOutlet MaterialVerticalButton *logSrvaButton;
@property (weak, nonatomic) IBOutlet MaterialVerticalButton *mapButton;

@property (weak, nonatomic) IBOutlet MaterialVerticalButton *myDetailButton;
@property (weak, nonatomic) IBOutlet MDCButton *shootingTestsButton;
@property (weak, nonatomic) IBOutlet MDCButton *huntingLicenseButton;

@property (nonatomic, strong) UIBarButtonItem* synchronizeButton;

@end


@implementation RiistaMyGameViewController
{
    MyGameQuickButtonsHelper *quickButtonHelper;

    // Keeps track of language used when refreshing UI texts.
    NSString* previousLanguage;

    // Is the viewcontroller currently visible
    BOOL currentlyVisible;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"MenuFrontPage", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    quickButtonHelper = [[MyGameQuickButtonsHelper alloc] initWithNavigationController:self.navigationController];


    [self createSynchronizeTabButton];

    [self setupPrimaryButtonStyle:_logHarvestButton
                     textResource:@"Loggame"
                    imageResource:@"harvest"
                          onClick:@selector(logHarvestButtonClick:)];
    [self setupSecondaryButtonStyle:_quickHarvestButton1 textResource:nil imageResource:nil onClick:nil];
    [self setupSecondaryButtonStyle:_quickHarvestButton2 textResource:nil imageResource:nil onClick:nil];

    [self setupPrimaryButtonStyle:_logObservationButton
                     textResource:@"LogObservation"
                    imageResource:@"observation"
                          onClick:@selector(logObservationButtonClick:)];
    [self setupSecondaryButtonStyle:_quickObservationButton1 textResource:nil imageResource:nil onClick:nil];
    [self setupSecondaryButtonStyle:_quickObservationButton2 textResource:nil imageResource:nil onClick:nil];

    [self setupPrimaryButtonStyle:_logSrvaButton
                     textResource:@"LogSrva"
                    imageResource:@"srva"
                          onClick:@selector(logSrvaButtonClick:)];
    [self setupPrimaryButtonStyle:_mapButton
                     textResource:@"Map"
                    imageResource:@"map_pin"
                          onClick:@selector(navigateToMap:)];

    [self setupPrimaryButtonStyle:_myDetailButton
                     textResource:@"MyDetails"
                    imageResource:@"person"
                          onClick:@selector(navigateToMyDetails:)];
    [self setupSecondaryButtonStyle:_huntingLicenseButton
                       textResource:@"HomeHuntingLicense"
                      imageResource:nil
                            onClick:@selector(navigateToHuntingLicense:)];
    [self setupSecondaryButtonStyle:_shootingTestsButton
                       textResource:@"HomeShootingTests"
                      imageResource:nil
                            onClick:@selector(navigateToShootingTests:)];
    // reduce left/right edge insets as Swedish content is wrapped ugly (last line contains only 1 char)
    UIEdgeInsets currentContentInsets = [_shootingTestsButton contentEdgeInsets];
    [_shootingTestsButton setContentEdgeInsets:UIEdgeInsetsMake(
        currentContentInsets.top, currentContentInsets.left / 4, currentContentInsets.bottom, currentContentInsets.right / 4)];

    previousLanguage = LocalizationGetLanguage;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarEntriesUpdated:) name:RiistaCalendarEntriesUpdatedKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userInfoUpdated:) name:RiistaUserInfoUpdatedKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tryDisplayAppStartupMessage) name:RiistaUserInfoUpdatedKey object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarEntriesUpdated:) name:NotificationNames.EntityModifiedName object:nil];

    [self updateNavigationItemTitleView];
    [self setupQuickButtons];
    [self updateSrvaVisibility];
}

- (void)setupPrimaryButtonStyle:(MDCButton*)button textResource:(NSString*)textResource imageResource:(NSString*)imageResource onClick:(SEL)onClick
{
    [self setupButtonStyle:button
                     theme:AppTheme.shared.cardButtonSchemeBolded
              textResource:textResource
             imageResource:imageResource
                   onClick:onClick];
}

- (void)setupSecondaryButtonStyle:(MDCButton*)button textResource:(NSString*)textResource imageResource:(NSString*)imageResource onClick:(SEL)onClick
{
    [self setupButtonStyle:button
                     theme:AppTheme.shared.cardButtonScheme
              textResource:textResource
             imageResource:imageResource
                   onClick:onClick];
}

- (void)setupButtonStyle:(MDCButton*)button theme:(MDCContainerScheme*)theme textResource:(NSString*)textResource imageResource:(NSString*)imageResource onClick:(SEL)onClick
{
    [AppTheme.shared setupCardTextButtonThemeWithButton:button];
    [button applyTextThemeWithScheme:theme];

    [button setTitle:RiistaLocalizedString(textResource, nil) forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];

    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;

    if (imageResource != nil) {
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;

        UIImage *image = [UIImage imageNamed:imageResource];
        [button setImage:image forState:UIControlStateNormal];
    }

    if (onClick != nil) {
        [button addTarget:self action:onClick forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refreshLocalizedContent];
    [self updateSrvaVisibility];

    // ensure the remote configuration is kept up-to-date
    // - currently RiistaCommon initialization and related functionality require that remote configuration
    //   does not change after app has been launched
    [RemoteConfigurationManager.sharedInstance fetchRemoteConfigurationIfNotRecentWithCompletionHandler:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onManualSynchronizationPossibleStatusChanged:)
                                               name:NotificationNames.ManualSynchronizationPossibleStatusChanged
                                             object:nil];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    currentlyVisible = YES;
    [self pageSelected];

    if (![self tryDisplayUnregistrationRequestedNotification]) {
        [self tryDisplayAppStartupMessage];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    currentlyVisible = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pageSelected
{
    [self updateSyncButton];
    [self refreshLocalizedContent];
}

- (void)refreshLocalizedContent
{
    RiistaLanguageRefresh;
    NSString* activeLanguage = [RiistaSettings language];

    // Switching language requires refreshing the whole season statistics data.
    // Avoid doing this update unless app language has actually changed since last update.
    if (![previousLanguage isEqualToString:activeLanguage])
    {
        previousLanguage = activeLanguage;
        [_logHarvestButton setTitle:RiistaLocalizedString(@"Loggame", nil) forState:UIControlStateNormal];
        [_logObservationButton setTitle:RiistaLocalizedString(@"LogObservation", nil) forState:UIControlStateNormal];
        [_logSrvaButton setTitle:RiistaLocalizedString(@"LogSrva", nil) forState:UIControlStateNormal];

        [_mapButton setTitle:RiistaLocalizedString(@"Map", nil) forState:UIControlStateNormal];

        [_myDetailButton setTitle:RiistaLocalizedString(@"MyDetails", nil) forState:UIControlStateNormal];
        [_shootingTestsButton setTitle:RiistaLocalizedString(@"HomeShootingTests", nil) forState:UIControlStateNormal];
        [_huntingLicenseButton setTitle:RiistaLocalizedString(@"HomeHuntingLicense", nil) forState:UIControlStateNormal];

        [self calendarEntriesUpdated:nil];
        [self updateNavigationItemTitleView];
    }
}

- (void)updateNavigationItemTitleView
{
    NSString* activeLanguage = [RiistaSettings language];

    if ([@"sv" isEqualToString:activeLanguage]) {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_home_sv"]];
    }
    else if ([@"en" isEqualToString:activeLanguage]) {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_home_en"]];
    }
    else {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_home_fi"]];
    }
}


- (void)createSynchronizeTabButton
{
    self.synchronizeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh_white"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(performManualAppSync)];
    [self.navigationItem setRightBarButtonItem:self.synchronizeButton];

    [self updateSyncButton];
}

- (void)updateSyncButton
{
    self.synchronizeButton.isHiddenCompat = [AppSync.shared isAutomaticSyncEnabled];
    self.synchronizeButton.enabled = AppSync.shared.manualSynchronizationPossible;
}

- (void)onManualSynchronizationPossibleStatusChanged:(NSNotification *)notification
{
    if (notification.object && [notification.object isKindOfClass:[NSNumber class]]) {
        BOOL manualSyncPossible = [((NSNumber *)notification.object) boolValue];

        [self.synchronizeButton setEnabled:manualSyncPossible];
    }
}

- (void)performManualAppSync
{
    [AppSync.shared synchronizeManuallyWithForceContentReload:false];
}


- (void)logHarvestButtonClick:(id)sender
{
    UIViewController *viewController = [CreateHarvestViewControllerHelper createViewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)logObservationButtonClick:(id)sender
{
    UIViewController *viewController = [CreateObservationViewControllerHelper createViewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)logSrvaButtonClick:(id)sender
{
    UIViewController *controller = [CreateSrvaEventViewControllerHelper createViewController];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)calendarEntriesUpdated:(NSNotification*)notification
{
    [self setupQuickButtons];
}

- (void)userInfoUpdated:(NSNotification*)notification
{
    [self setupQuickButtons];
    [self updateSrvaVisibility];
}

- (BOOL)tryDisplayUnregistrationRequestedNotification
{
    TopLevelTabBarViewController *tabController = (TopLevelTabBarViewController*)self.tabBarController;

    BOOL loggingIn = [tabController isDisplayingLoginScreen];
    if (currentlyVisible == NO || loggingIn == YES) {
        return NO;
    }

    // check whether there's a pending unregistration
    BOOL notified = [UserAccountUnregisterRequestedViewController notifyIfUnregistrationRequestedWithNavigationController:self.navigationController ignoreCooldown:NO];

    return notified;
}

- (void)tryDisplayAppStartupMessage
{
    TopLevelTabBarViewController *tabController = (TopLevelTabBarViewController*)self.tabBarController;

    BOOL loggingIn = [tabController isDisplayingLoginScreen];
    if (currentlyVisible == YES && loggingIn == NO) {
        [CrashlyticsHelper logWithMsg:@"Trying to display app startup message"];

        BOOL startupMessageDisplayed = [RiistaSDKHelper displayAppStartupMessageWithParentViewController:self];
        if (!startupMessageDisplayed) {
            [AppUpdateNotifier checkVersionAndLaunchUpdateDialogFromLandingPage];
        }
    }
}

- (void)updateSrvaVisibility
{
    BOOL hideSrva = YES;

    UserInfo *userInfo = [RiistaSettings userInfo];
    if ([userInfo.enableSrva boolValue]) {
        hideSrva = NO;
    }

    self.srvaCard.hidden = hideSrva;
}

- (void)setupQuickButtons
{
    [quickButtonHelper setupHarvestButtonsWithButton1:self.quickHarvestButton1
                                              button2:self.quickHarvestButton2];
    [quickButtonHelper setupObservationButtonsWithButton1:self.quickObservationButton1
                                                  button2:self.quickObservationButton2];
}

- (void)navigateToMap:(id)sender
{
    [self.tabBarController setSelectedIndex:2];
}

- (void)navigateToMyDetails:(id)sender
{
    UIViewController *controller = [[MyDetailsViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)navigateToShootingTests:(id)sender
{
    ShootingTestsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ShootingTestsController"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)navigateToHuntingLicense:(id)sender
{
    HuntingLicenseViewController *controller = [[HuntingLicenseViewController alloc] initWithUserInfo:[RiistaSettings userInfo]];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
