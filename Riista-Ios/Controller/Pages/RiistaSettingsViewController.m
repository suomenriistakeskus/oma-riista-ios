#import "RiistaSettingsViewController.h"
#import "RiistaSettings.h"
#import "RiistaGameDatabase.h"
#import "RiistaLocalization.h"
#import "Styles.h"

#import "RiistaCommon/RiistaCommon.h"
#import "Oma_riista-Swift.h"

@interface RiistaSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *syncLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *syncSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet MDCButton *privacyTermsButton;
@property (weak, nonatomic) IBOutlet MDCButton *thirdPartyLicenseButton;
@property (weak, nonatomic) IBOutlet MDCButton *termsOfServiceButton;
@property (weak, nonatomic) IBOutlet MDCButton *accessibilityStatementButton;
@property (weak, nonatomic) IBOutlet UILabel *languageSettingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *languageSegmentedControl;

// added in code
@property (nonatomic, strong) UIBarButtonItem* synchronizeButton;
@end

@implementation RiistaSettingsViewController
{
    int clickCountForExperimentalMode;
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
    self.tabBarItem.title = RiistaLocalizedString(@"MenuSettings", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createSynchronizeTabButton];

    self.view.backgroundColor = [UIColor applicationColor:ViewBackground];
    [AppTheme.shared setupSegmentedControllerWithSegmentedController:self.syncSegmentedControl];

    RiistaSyncMode mode = [RiistaSettings syncMode];
    if (mode == RiistaSyncModeManual) {
        [self.syncSegmentedControl setSelectedSegmentIndex:0];
    } else {
        [self.syncSegmentedControl setSelectedSegmentIndex:1];
    }
    [self.syncSegmentedControl addTarget:self action:@selector(syncModeChanged:) forControlEvents:UIControlEventValueChanged];

    // will also refresh version, no need to it separately here
    [self setupLanguageSelect];

    [self setupExperimentalModeToggle];
    [self setupPrivacyTermsButton];
    [self setupTermsOfServiceButton];
    [self setupAccessibilityStatementButton];
    [self setupThirdPartyLibrariesButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupLocalizedTexts];
    [self updateSyncButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self pageSelected];
}

- (void)createSynchronizeTabButton
{
    self.synchronizeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh_white"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(synchronizeEvents)];
    [self.navigationItem setRightBarButtonItem:self.synchronizeButton];

    [self updateSyncButton];
}

- (void)updateSyncButton
{
    self.synchronizeButton.isHidden = [RiistaSettings syncMode] != RiistaSyncModeManual;
    self.synchronizeButton.enabled = ![[RiistaGameDatabase sharedInstance] synchronizing];
}

- (void)synchronizeEvents
{
    [self.synchronizeButton setEnabled:NO];
    [[RiistaGameDatabase sharedInstance] synchronizeDiaryEntries:^() {
        [self.synchronizeButton setEnabled:YES];
    }];
}

- (void)refreshVersionText
{
    NSString *appVersion = [[[RiistaCommonRiistaSDK riistaSDK] versionInfo] appVersion];

    NSString *versionPostfix = [self determineVersionPostfix];
    appVersion = [appVersion stringByAppendingString:versionPostfix];

    NSString *versionFormat = RiistaLocalizedString(@"Version", nil);
    self.versionLabel.text = [[NSString alloc] initWithFormat:versionFormat, appVersion];
}

- (NSString*)determineVersionPostfix
{
    NSString *postfix = @"";
    if ([FeatureAvailabilityChecker.shared isEnabled:FeatureExperimentalMode]) {
        postfix = [postfix stringByAppendingString:@"e"];
    }

    if (postfix.length > 0) {
        return [NSString stringWithFormat:@" (%@)", postfix];
    } else {
        return @"";
    }
}

- (void)setupLanguageSelect
{
    [AppTheme.shared setupSegmentedControllerWithSegmentedController:self.languageSegmentedControl];

    [self.languageSegmentedControl setTitle:RiistaLocalizedString(@"Suomi", nil) forSegmentAtIndex:0];
    [self.languageSegmentedControl setTitle:RiistaLocalizedString(@"Svenska", nil) forSegmentAtIndex:1];
    [self.languageSegmentedControl setTitle:RiistaLocalizedString(@"English", nil) forSegmentAtIndex:2];

    NSString* languageSetting = [RiistaSettings language];
    if ([languageSetting isEqual: @"fi"]) {
        [self.languageSegmentedControl setSelectedSegmentIndex:0];
    }
    else if ([languageSetting isEqual: @"sv"]) {
        [self.languageSegmentedControl setSelectedSegmentIndex:1];
    }
    else {
        [self.languageSegmentedControl setSelectedSegmentIndex:2];
    }
    [self.languageSegmentedControl addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupExperimentalModeToggle
{
    clickCountForExperimentalMode = 0;

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] init];
    [gestureRecognizer addTarget:self action:@selector(onVersionLabelClicked)];
    _versionLabel.userInteractionEnabled = YES;
    [_versionLabel addGestureRecognizer:gestureRecognizer];
}

- (void)onVersionLabelClicked
{
    if (![RemoteConfigurationManager.sharedInstance experimentalModeAllowed]) {
        DDLog(@"Refusing to enable experimental mode, not allowed!");
        return;
    }

    clickCountForExperimentalMode++;

    DDLog(@"Version label clicked! (%d clicks so far)", clickCountForExperimentalMode);
    if (clickCountForExperimentalMode >= 7) {
        clickCountForExperimentalMode = 0;

        [FeatureAvailabilityChecker.shared toggleExperimentalMode];
        [self refreshVersionText];
    }
}


- (void)setupPrivacyTermsButton
{
    [_privacyTermsButton applyTextThemeWithScheme:AppTheme.shared.outlineButtonScheme];
    [_privacyTermsButton addTarget:self action:@selector(openPrivacyTerms:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTermsOfServiceButton
{
    [_termsOfServiceButton applyTextThemeWithScheme:AppTheme.shared.outlineButtonScheme];
    [_termsOfServiceButton addTarget:self action:@selector(displayTermsOfService:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupAccessibilityStatementButton
{
    [_accessibilityStatementButton applyTextThemeWithScheme:AppTheme.shared.outlineButtonScheme];
    [_accessibilityStatementButton addTarget:self action:@selector(displayAccessibilityStatement:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupThirdPartyLibrariesButton
{
    [_thirdPartyLicenseButton applyTextThemeWithScheme:AppTheme.shared.outlineButtonScheme];
    [_thirdPartyLicenseButton addTarget:self action:@selector(openThirdPartyLibrariesPage:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupLocalizedTexts
{
    RiistaLanguageRefresh;
    self.syncLabel.text = RiistaLocalizedString(@"Synchronization", nil);
    [self.syncSegmentedControl setTitle:RiistaLocalizedString(@"Manual", nil) forSegmentAtIndex:0];
    [self.syncSegmentedControl setTitle:RiistaLocalizedString(@"Automatic", nil) forSegmentAtIndex:1];

    self.languageSettingLabel.text = RiistaLocalizedString(@"Language", nil);
    [self refreshVersionText];

    [self.privacyTermsButton setTitle:RiistaLocalizedString(@"PrivacyStatement", nil)
                             forState:UIControlStateNormal];
    [self.termsOfServiceButton setTitle:RiistaLocalizedString(@"TermsOfService", nil)
                             forState:UIControlStateNormal];
    [self.accessibilityStatementButton setTitle:RiistaLocalizedString(@"AccessibilityStatement", nil)
                                       forState:UIControlStateNormal];
    [self.thirdPartyLicenseButton setTitle:RiistaLocalizedString(@"ThirdPartyLibraries", nil)
                                  forState:UIControlStateNormal];



    [self pageSelected];
}

- (void)syncModeChanged:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:self.syncSegmentedControl.selectedSegmentIndex forKey:RiistaSettingsSyncModeKey];
    [RiistaGameDatabase sharedInstance].autosync = (self.syncSegmentedControl.selectedSegmentIndex == 1);
    [userDefaults synchronize];

    [self updateSyncButton];
    [SynchronizationAnalytics onSynchronizationModeChanged];
}

- (void)languageChanged:(id)sender
{
    if (self.languageSegmentedControl) {
        NSInteger selectedIndex = self.languageSegmentedControl.selectedSegmentIndex;

        if (selectedIndex == 0) {
            [RiistaSettings setLanguageSetting:@"fi"];
        }
        else if (selectedIndex == 1) {
            [RiistaSettings setLanguageSetting:@"sv"];
        }
        else if (selectedIndex == 2) {
            [RiistaSettings setLanguageSetting:@"en"];
        }

        [self setupLocalizedTexts];

        // Refresh navigation drawer and entry log
        [[NSNotificationCenter defaultCenter] postNotificationName:RiistaLanguageSelectionUpdatedKey object:nil];
    }
}

- (void)pageSelected
{
    self.title = RiistaLocalizedString(@"Settings", nil);
}

- (void)openPrivacyTerms:(id)sender
{
    NSURL *privacyStatementUrl = [NSURL URLWithString:RiistaLocalizedString(@"PrivacyStatementUrl", nil)];
    [[UIApplication sharedApplication] openURL:privacyStatementUrl options:@{} completionHandler:nil];
}

- (void)displayTermsOfService:(id)sender
{
    NSURL *termsOfServiceUrl = [NSURL URLWithString:RiistaLocalizedString(@"TermsOfServiceUrl", nil)];
    [[UIApplication sharedApplication] openURL:termsOfServiceUrl options:@{} completionHandler:nil];
}

- (void)displayAccessibilityStatement:(id)sender
{
    NSURL *accessibilityStatementUrl = [NSURL URLWithString:RiistaLocalizedString(@"AccessibilityStatementUrl", nil)];
    [[UIApplication sharedApplication] openURL:accessibilityStatementUrl options:@{} completionHandler:nil];
}

- (void)openThirdPartyLibrariesPage:(id)sender
{
    UIViewController *controller = [[ThirdPartyLicensesController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
