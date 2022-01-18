#import "RiistaMyGameViewController.h"
#import "RiistaLogGameViewController.h"
#import "RiistaHeaderLabel.h"
#import "Styles.h"
#import "RiistaUtils.h"
#import "RiistaGameDatabase.h"
#import "DiaryEntry.h"
#import "SrvaEntry.h"
#import "RiistaSpecies.h"
#import "RiistaNavigationController.h"
#import "RiistaTabBarViewController.h"
#import "RiistaSettings.h"
#import "RiistaLocalization.h"
#import "RiistaMetadataManager.h"
#import "DetailsViewController.h"
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

@property (nonatomic, strong) NSArray *latestHarvestSpecies;
@property (nonatomic, strong) NSArray *latestObservationSpecies;

@property (nonatomic, strong) UIView *refreshView;
@property (nonatomic, strong) UIImageView *refreshImageView;
@property (nonatomic, strong) UIButton *refreshButton;

@property (nonatomic, copy) NSNumber *srvaQuick1SpeciesCode;
@property (nonatomic, copy) NSString *srvaQuick1EventName;
@property (nonatomic, copy) NSString *srvaQuick1EventType;

@property (nonatomic, copy) NSNumber *srvaQuick2SpeciesCode;
@property (nonatomic, copy) NSString *srvaQuick2EventName;
@property (nonatomic, copy) NSString *srvaQuick2EventType;

@end

NSInteger const quickHarvest1Default = 47503; // Hirvi
NSInteger const quickHarvest2Default = 50106; // Metsajanis

NSInteger const quickObservation1Default = 47503; // Hirvi
NSInteger const quickObservation2Default = 47629; // Valkohantapeura

NSInteger const quickSrva1Default = 47503; // Hirvi
NSInteger const quickSrva2Default = 47629; // Valkohantapeura

@implementation RiistaMyGameViewController
{
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

    self.refreshView = [UIView new];
    self.refreshView.frame = CGRectMake(0, 0, RiistaRefreshImageSize+RiistaRefreshPadding, RiistaRefreshImageSize);
    self.refreshImageView = [UIImageView new];
    [self.refreshView addSubview:self.refreshImageView];
    self.refreshImageView.image = [UIImage imageNamed:@"ic_action_refresh.png"];
    self.refreshImageView.userInteractionEnabled = YES;
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.refreshImageView.frame = CGRectMake(RiistaRefreshPadding, 0, RiistaRefreshImageSize, RiistaRefreshImageSize);
    [self.refreshImageView addSubview:self.refreshButton];
    self.refreshButton.frame = CGRectMake(0, 0, RiistaRefreshImageSize, RiistaRefreshImageSize);

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    currentlyVisible = YES;
    [self pageSelected];

    [self tryDisplayAppStartupMessage];
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
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController setLeftBarItem:nil];
    [navController setRightBarItems:nil];

    [self setupSyncButton];
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
    }

    UIImageView *titleImageView;

    if ([@"sv" isEqualToString:activeLanguage]) {
        titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_home_sv"]];
    }
    else if ([@"en" isEqualToString:activeLanguage]) {
        titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_home_en"]];
    }
    else {
        titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header_home_fi"]];
    }

    self.tabBarController.navigationItem.titleView = titleImageView;
}

- (void)setupSyncButton
{
    RiistaSyncMode mode = [RiistaSettings syncMode];
    if (mode == RiistaSyncModeManual) {
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithCustomView:self.refreshView];
        [self.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
        [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[refreshButton]];
    }
}

- (void)refresh:(id)sender
{
    CGFloat speed = 0.4f;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * speed];
    rotationAnimation.duration = 0.5f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [self.refreshImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    [[RiistaGameDatabase sharedInstance] synchronizeDiaryEntries:^() {
        [self.refreshImageView.layer removeAllAnimations];
    }];
}

- (void)logHarvestButtonClick:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"HarvestStoryboard" bundle:nil];
    UIViewController *destination = [sb instantiateInitialViewController];

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];

    [segue perform];
}

- (void)logObservationButtonClick:(id)sender
{
    if (![[RiistaMetadataManager sharedInstance] hasObservationMetadata]) {
        DDLog(@"No metadata");
        return;
    }

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    UIViewController *destination = [sb instantiateInitialViewController];

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];

    [segue perform];
}

- (void)logSrvaButtonClick:(id)sender
{
    if (![[RiistaMetadataManager sharedInstance] hasSrvaMetadata]) {
        DDLog(@"No metadata");
        return;
    }

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    DetailsViewController *destination = (DetailsViewController*)[sb instantiateInitialViewController];
    destination.srvaNew = [NSNumber numberWithBool:YES];

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];
    [segue perform];
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

- (void)tryDisplayAppStartupMessage
{
    RiistaTabBarViewController *tabController = (RiistaTabBarViewController*)self.tabBarController;

    BOOL loggingIn = [tabController isDisplayingLoginScreen];
    if (currentlyVisible == YES && loggingIn == NO) {
        [CrashlyticsHelper logWithMsg:@"Trying to display app startup message"];

        [RiistaSDKHelper displayAppStartupMessageWithParentViewController:self];
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
    // Harvest buttons
    NSArray *quickButtons = @[self.quickHarvestButton1, self.quickHarvestButton2];
    NSMutableArray *defaultItems = [@[@(quickHarvest1Default), @(quickHarvest2Default)] mutableCopy];
    NSArray *latestSpecies = [[RiistaGameDatabase sharedInstance] latestEventSpecies:quickButtons.count];
    [self setupQuickButtonGroup:quickButtons species:latestSpecies defaults:defaultItems isHarvest:YES];

    // Observation buttons
    quickButtons = @[self.quickObservationButton1, self.quickObservationButton2];
    defaultItems = [@[@(quickObservation1Default), @(quickObservation2Default)] mutableCopy];
    latestSpecies = [[RiistaGameDatabase sharedInstance] latestObservationSpecies:quickButtons.count];
    [self setupQuickButtonGroup:quickButtons species:latestSpecies defaults:defaultItems isHarvest:NO];
}

- (void)setupSrvaButton:(UIButton*)button speciesCode:(NSInteger)speciesCode eventName:(NSString*)eventName eventType:(NSString*)eventType
{
    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:speciesCode];
    NSString *name = [RiistaUtils nameWithPreferredLanguage:species.name];

    NSString *text = [NSString stringWithFormat:@"%@ / %@", name, RiistaMappedValueString(eventType, nil)];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button setTitle:text forState:UIControlStateNormal];

    [button addTarget:self action:@selector(logSrvaSpecies:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupQuickButtonGroup:(NSArray*)quickButtons species:(NSArray*)latestSpecies defaults:(NSMutableArray*)defaultItems isHarvest:(BOOL)isHarvest
{
    NSMutableArray *speciesArray = [NSMutableArray new];

    for (int i=0; i<quickButtons.count; i++) {
        NSInteger speciesId = 0;
        if (latestSpecies && (latestSpecies.count > i)) {
            speciesId = [latestSpecies[i] integerValue];
            NSUInteger index =  [defaultItems indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj integerValue] == speciesId) {
                    return YES;
                }
                return NO;
            }];
            if (index != NSNotFound) {
                [defaultItems removeObjectAtIndex:index];
            }
        } else if (defaultItems.count > 0) {
            speciesId = [defaultItems[0] integerValue];
            [defaultItems removeObjectAtIndex:0];
        }
        RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:speciesId];
        if (species) {
            [speciesArray addObject:species];
        } else {
            [speciesArray addObject:[NSNull null]];
        }
    }

    if (isHarvest) {
        self.latestHarvestSpecies = [speciesArray copy];

        for (int i=0; i<quickButtons.count; i++) {
            [self setupQuickButton:quickButtons[i] ordinal:i titleResource:@"LogGameFormat" speciesList:self.latestHarvestSpecies presetSpecies:@selector(logHarvestSpecies:)];
        }
    }
    else {
        self.latestObservationSpecies = [speciesArray copy];

        for (int i=0; i<quickButtons.count; i++) {
            [self setupQuickButton:quickButtons[i] ordinal:i titleResource:@"LogObservationFormat" speciesList:self.latestObservationSpecies presetSpecies:@selector(logObservationSpecies:)];
        }
    }
}

/**
 * Setups quick button using given species id
 * If the species does not exist (could happen with defaults) the button is hidden
 */
- (void)setupQuickButton:(UIButton*)button
                 ordinal:(NSInteger)ordinal
           titleResource:(NSString*)titleResource
             speciesList:(NSArray*)speciesList
           presetSpecies:(SEL)presetSpecies
{
    if (speciesList.count > ordinal && ![speciesList[ordinal] isEqual:[NSNull null]]) {
        RiistaSpecies *species = speciesList[ordinal];
        button.hidden = NO;
        NSString *titleString = [NSString stringWithFormat:RiistaLocalizedString(titleResource, nil), [RiistaUtils nameWithPreferredLanguage:species.name]];
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.tag = ordinal;
        [button setTitle:titleString forState:UIControlStateNormal];
        [button addTarget:self action:presetSpecies forControlEvents:UIControlEventTouchUpInside];
    } else {
        button.hidden = YES;
    }
}

- (void)logHarvestSpecies:(id)sender
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"HarvestStoryboard" bundle:nil];
    DetailsViewController *destination = (DetailsViewController*)[sb instantiateInitialViewController];
    destination.species = self.latestHarvestSpecies[[sender tag]];

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];

    [segue perform];
}

- (void)logObservationSpecies:(id)sender
{
    if (![[RiistaMetadataManager sharedInstance] hasObservationMetadata]) {
        DDLog(@"No metadata");
        return;
    }

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    DetailsViewController *destination = (DetailsViewController*)[sb instantiateInitialViewController];
    destination.species = self.latestObservationSpecies[[sender tag]];

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];

    [segue perform];
}

- (void)logSrvaSpecies:(id)sender
{
    if (![[RiistaMetadataManager sharedInstance] hasSrvaMetadata]) {
        DDLog(@"No metadata");
        return;
    }

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    DetailsViewController *destination = (DetailsViewController*)[sb instantiateInitialViewController];
    destination.srvaNew = [NSNumber numberWithBool:YES];

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];
    [segue perform];
}

- (void)navigateToMap:(id)sender
{
    [self.tabBarController setSelectedIndex:2];
}

- (void)navigateToMyDetails:(id)sender
{
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MyDetailsController"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)navigateToShootingTests:(id)sender
{
//    let dest = self.storyboard?.instantiateViewController(withIdentifier:"ShootingTestsController") as!

    ShootingTestsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ShootingTestsController"];
    controller.user = [RiistaSettings userInfo];

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)navigateToHuntingLicense:(id)sender
{
    HuntingLicenseViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"HuntingLicenseController"];
    controller.user = [RiistaSettings userInfo];

    [self.navigationController pushViewController:controller animated:YES];
}

@end
