#import "RiistaSettingsViewController.h"
#import "RiistaSettings.h"
#import "RiistaGameDatabase.h"
#import "RiistaLocalization.h"
#import "RiistaNavigationController.h"
#import "Styles.h"

@interface RiistaSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *syncLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *syncSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *versionSettingLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *thirdPartyLicenseButton;
@property (weak, nonatomic) IBOutlet UILabel *languageSettingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *languageSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *mapSourceLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapSourceSegmentedControl;

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

    RiistaSyncMode mode = [RiistaSettings syncMode];
    if (mode == RiistaSyncModeManual) {
        [self.syncSegmentedControl setSelectedSegmentIndex:0];
    } else {
        [self.syncSegmentedControl setSelectedSegmentIndex:1];
    }
    [self.syncSegmentedControl addTarget:self action:@selector(syncModeChanged:) forControlEvents:UIControlEventValueChanged];

    [self setupLanguageSelect];
    [self setupMapTypeSelect];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@%@", version, @""];

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

- (void)setupLanguageSelect
{
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

- (void)setupMapTypeSelect
{
    RiistaMapType mapTypeSetting = [RiistaSettings mapType];
    if (mapTypeSetting == GoogleMapType) {
        [self.mapSourceSegmentedControl setSelectedSegmentIndex:0];
    }
    else {
        [self.mapSourceSegmentedControl setSelectedSegmentIndex:1];
    }

    [self.mapSourceSegmentedControl addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupThirdPartyLibrariesButton
{
    [Styles styleLinkButton:_thirdPartyLicenseButton];
    _thirdPartyLicenseButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_thirdPartyLicenseButton addTarget:self action:@selector(openThirdPartyLibrariesPage:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupLocalizedTexts
{
    RiistaLanguageRefresh;
    self.syncLabel.text = RiistaLocalizedString(@"Synchronization", nil);
    [self.syncSegmentedControl setTitle:RiistaLocalizedString(@"Manual", nil) forSegmentAtIndex:0];
    [self.syncSegmentedControl setTitle:RiistaLocalizedString(@"Automatic", nil) forSegmentAtIndex:1];

    self.languageSettingLabel.text = RiistaLocalizedString(@"Language", nil);
    self.versionSettingLabel.text = RiistaLocalizedString(@"Version", nil);

    self.mapSourceLabel.text = RiistaLocalizedString(@"SettingsMapTypeTitle", nil);
    [self.mapSourceSegmentedControl setTitle:RiistaLocalizedString(@"SettingsMapTypeGoogle", nil) forSegmentAtIndex:0];
    [self.mapSourceSegmentedControl setTitle:RiistaLocalizedString(@"SettingsMapTypeMml", nil) forSegmentAtIndex:1];

    [self.thirdPartyLicenseButton setTitle:RiistaLocalizedString(@"UsedThirdPartyLibraries", nil) forState:UIControlStateNormal];
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

- (void)mapTypeChanged:(id)sender
{
    if (self.mapSourceSegmentedControl) {
        NSInteger selectedIndex = self.mapSourceSegmentedControl.selectedSegmentIndex;

        if (selectedIndex == 0) {
            [RiistaSettings setMapTypeSetting:GoogleMapType];
        }
        else if (selectedIndex == 1) {
            [RiistaSettings setMapTypeSetting:MmlTopographicMapType];
        }
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

- (void)openThirdPartyLibrariesPage:(id)sender
{
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ThirdPartyLibrariesController"];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
