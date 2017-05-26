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
#import "RiistaSettings.h"
#import "RiistaGameLogViewController.h"
#import "RiistaLocalization.h"
#import "RiistaMetadataManager.h"
#import "DetailsViewController.h"
#import "UIColor+ApplicationColor.h"
#import "UserInfo.h"

@interface RiistaMyGameViewController ()

@property (weak, nonatomic) IBOutlet UIButton *logHarvestButton;
@property (weak, nonatomic) IBOutlet UIButton *quickHarvestButton1;
@property (weak, nonatomic) IBOutlet UIButton *quickHarvestButton2;

@property (weak, nonatomic) IBOutlet UIButton *logObservationButton;
@property (weak, nonatomic) IBOutlet UIButton *quickObservationButton1;
@property (weak, nonatomic) IBOutlet UIButton *quickObservationButton2;

@property (weak, nonatomic) IBOutlet UIButton *logSrvaButton;
@property (weak, nonatomic) IBOutlet UIButton *quickSrvaButton1;
@property (weak, nonatomic) IBOutlet UIButton *quickSrvaButton2;

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

    [self setupButtonStyle:_logHarvestButton textResource:@"Loggame" imageResource:@"ic_button_saalis.png" onClick:@selector(logHarvestButtonClick:)];
    [Styles styleButton:_quickHarvestButton1];
    [Styles styleButton:_quickHarvestButton2];

    [self setupButtonStyle:_logObservationButton textResource:@"LogObservation" imageResource:@"ic_button_observation.png" onClick:@selector(logObservationButtonClick:)];
    [Styles styleButton:_quickObservationButton1];
    [Styles styleButton:_quickObservationButton2];

    [self setupButtonStyle:_logSrvaButton textResource:@"LogSrva" imageResource:@"ic_srva.png" onClick:@selector(logSrvaButtonClick:)];
    [Styles styleButton:_quickSrvaButton1];
    [Styles styleButton:_quickSrvaButton2];

    previousLanguage = LocalizationGetLanguage;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarEntriesUpdated:) name:RiistaCalendarEntriesUpdatedKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userInfoUpdated:) name:RiistaUserInfoUpdatedKey object:nil];

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

- (void)setupButtonStyle:(UIButton*)button textResource:(NSString*)textResource imageResource:(NSString*)imageResource onClick:(SEL)onClick
{
    [Styles styleButton:button];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [button setTitle:RiistaLocalizedString(textResource, nil) forState:UIControlStateNormal];
    [button setImage:[[UIImage imageNamed:imageResource] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button setImage:[[UIImage imageNamed:imageResource] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    [button setTintColor:[UIColor whiteColor]];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(17, 0, 17, 0)];
    [button addTarget:self action:onClick forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupLocalizedTexts];
    [self updateSrvaVisibility];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self pageSelected];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pageSelected
{
    self.navigationController.title = RiistaLocalizedString(@"Frontpage", nil);
    [self setupSyncButton];
    [self setupLocalizedTexts];
}

- (void)setupLocalizedTexts
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

        [self calendarEntriesUpdated:nil];
    }

    self.navigationController.title = RiistaLocalizedString(@"Frontpage", nil);
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
        DLog(@"No metadata");
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
        DLog(@"No metadata");
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

- (void)updateSrvaVisibility
{
    BOOL hide = YES;
    UserInfo *userInfo = [RiistaSettings userInfo];
    if ([userInfo.enableSrva boolValue]) {
        hide = NO;
    }
    self.logSrvaButton.hidden = hide;
    self.quickSrvaButton1.hidden = hide;
    self.quickSrvaButton2.hidden = hide;
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

    // Srva buttons
    [self setupSrvaQuickButtons];
}

- (void)setupSrvaQuickButtons
{
    [self setupSrvaButton:_quickSrvaButton1 speciesCode:quickSrva1Default eventName:@"ACCIDENT" eventType:@"TRAFFIC_ACCIDENT"];
    [self setupSrvaButton:_quickSrvaButton2 speciesCode:quickSrva2Default eventName:@"ACCIDENT" eventType:@"TRAFFIC_ACCIDENT"];

    NSArray *results = [[RiistaGameDatabase sharedInstance] latestSrvaSpecies:2];
    if (results.count > 0) {
        SrvaEntry* first = results[0];
        [self setupSrvaButton:_quickSrvaButton1 speciesCode:[first.gameSpeciesCode integerValue] eventName:first.eventName eventType:first.eventType];

        if (results.count > 1) {
            SrvaEntry* second = results[1];
            [self setupSrvaButton:_quickSrvaButton2 speciesCode:[second.gameSpeciesCode integerValue] eventName:second.eventName eventType:second.eventType];
        }
        else if ([first.gameSpeciesCode integerValue] == quickSrva2Default) {
            //Only one valid user created entry and it's species is the same as our second default, so move default 2 to use default 1
            [self setupSrvaButton:_quickSrvaButton2 speciesCode:quickSrva1Default eventName:@"ACCIDENT" eventType:@"TRAFFIC_ACCIDENT"];
        }
    }
}

- (void)setupSrvaButton:(UIButton*)button speciesCode:(NSInteger)speciesCode eventName:(NSString*)eventName eventType:(NSString*)eventType
{
    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:speciesCode];
    NSString *name = [RiistaUtils nameWithPreferredLanguage:species.name];

    NSString *text = [NSString stringWithFormat:@"%@ / %@", name, RiistaMappedValueString(eventType, nil)];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button setTitle:text forState:UIControlStateNormal];

    if (button == _quickSrvaButton1) {
        self.srvaQuick1SpeciesCode = [NSNumber numberWithInteger:speciesCode];
        self.srvaQuick1EventName = eventName;
        self.srvaQuick1EventType = eventType;
    }
    else if (button == _quickSrvaButton2) {
        self.srvaQuick2SpeciesCode = [NSNumber numberWithInteger:speciesCode];
        self.srvaQuick2EventName = eventName;
        self.srvaQuick2EventType = eventType;
    }
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
        DLog(@"No metadata");
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
        DLog(@"No metadata");
        return;
    }

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    DetailsViewController *destination = (DetailsViewController*)[sb instantiateInitialViewController];
    destination.srvaNew = [NSNumber numberWithBool:YES];

    if (sender == _quickSrvaButton1) {
        destination.species = [[RiistaGameDatabase sharedInstance] speciesById:[self.srvaQuick1SpeciesCode integerValue]];
        destination.srvaEventName = self.srvaQuick1EventName;
        destination.srvaEventType = self.srvaQuick1EventType;
    }
    else if (sender == _quickSrvaButton2) {
        destination.species = [[RiistaGameDatabase sharedInstance] speciesById:[self.srvaQuick2SpeciesCode integerValue]];
        destination.srvaEventName = self.srvaQuick2EventName;
        destination.srvaEventType = self.srvaQuick2EventType;
    }

    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:destination performHandler:^(void) {
        [self.navigationController pushViewController:destination animated:YES];
    }];
    [segue perform];
}

@end
