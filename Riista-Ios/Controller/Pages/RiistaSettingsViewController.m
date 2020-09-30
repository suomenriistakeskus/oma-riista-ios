#import "RiistaSettingsViewController.h"
#import "RiistaSettings.h"
#import "RiistaGameDatabase.h"
#import "RiistaLocalization.h"
#import "RiistaNavigationController.h"
#import "Styles.h"

#import "Oma_riista-Swift.h"

@interface RiistaSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *syncLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *syncSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet MDCButton *privacyTermsButton;
@property (weak, nonatomic) IBOutlet MDCButton *thirdPartyLicenseButton;
@property (weak, nonatomic) IBOutlet UILabel *languageSettingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *languageSegmentedControl;

@end

@implementation RiistaSettingsViewController

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


    [self setupPrivacyTermsButton];
    [self setupThirdPartyLibrariesButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self pageSelected];
}

- (void)refreshVersionText
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *versionFormat = RiistaLocalizedString(@"Version", nil);
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [[NSString alloc] initWithFormat:versionFormat, version];
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

- (void)setupPrivacyTermsButton
{
    [_privacyTermsButton applyTextThemeWithScheme:AppTheme.shared.outlineButtonScheme];
    [_privacyTermsButton addTarget:self action:@selector(openPrivacyTerms:) forControlEvents:UIControlEventTouchUpInside];
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

    [self.thirdPartyLicenseButton setTitle:RiistaLocalizedString(@"ThirdPartyLibraries", nil)
                                  forState:UIControlStateNormal];
    [self.privacyTermsButton setTitle:RiistaLocalizedString(@"PrivacyStatement", nil)
                             forState:UIControlStateNormal];


    [self pageSelected];
}

- (void)syncModeChanged:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:self.syncSegmentedControl.selectedSegmentIndex forKey:RiistaSettingsSyncModeKey];
    [RiistaGameDatabase sharedInstance].autosync = (self.syncSegmentedControl.selectedSegmentIndex == 1);
    [userDefaults synchronize];
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
    UIViewController *vc = self.navigationController;
    if ([vc isKindOfClass:NSClassFromString(@"UIMoreNavigationController")]) {
        vc.parentViewController.navigationController.title = RiistaLocalizedString(@"Settings", nil);
    }
    else
    {
        self.navigationController.title = RiistaLocalizedString(@"Settings", nil);
    }
}

- (void)openPrivacyTerms:(id)sender
{
    NSURL *privacyStatementUrl = [NSURL URLWithString:RiistaLocalizedString(@"PrivacyStatementUrl", nil)];
    [[UIApplication sharedApplication] openURL:privacyStatementUrl options:@{} completionHandler:nil];
}

- (void)openThirdPartyLibrariesPage:(id)sender
{
    UIViewController *controller = [[ThirdPartyLicensesController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
