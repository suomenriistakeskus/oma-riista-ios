#import "RiistaMapSettingsViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaNetworkManager.h"
#import "RiistaClubAreaMap.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "RiistaLocalization.h"
#import "Styles.h"
#import "Oma_riista-Swift.h"

#import "MaterialButtons.h"

@interface SelectedAreaMapCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet MDCButton *deleteAreaButton;
@property (assign, nonatomic) AreaType type;

@end

@implementation SelectedAreaMapCell
@end

@interface SelectedAreaMapItem : NSObject

@property (assign, nonatomic) AreaType type;
@property (weak, nonatomic) NSString *title;
@property (weak, nonatomic) NSString *name;

@end

@implementation SelectedAreaMapItem
@end

@interface RiistaMapSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *settingsLabel;

@property (weak, nonatomic) IBOutlet UILabel *mapTypeLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;

@property (weak, nonatomic) IBOutlet UISwitch *showLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *showLocationLabel;

@property (weak, nonatomic) IBOutlet UISwitch *invertSwitch;
@property (weak, nonatomic) IBOutlet UILabel *invertLabel;

@property (weak, nonatomic) IBOutlet UISwitch *stateLandsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *stateLandsLabel;

@property (weak, nonatomic) IBOutlet UISwitch *rhyBordersSwitch;
@property (weak, nonatomic) IBOutlet UILabel *rhyBordersLabel;

@property (weak, nonatomic) IBOutlet UISwitch *gameTrianglesSwitch;
@property (weak, nonatomic) IBOutlet UILabel *gameTrianglesLabel;

@property (weak, nonatomic) IBOutlet UILabel *areaBordersLabel;

@property (weak, nonatomic) IBOutlet UILabel *addAreasLabel;
@property (weak, nonatomic) IBOutlet MDCButton *clubAreasButton;
@property (weak, nonatomic) IBOutlet MDCButton *mooseAreasButton;
@property (weak, nonatomic) IBOutlet MDCButton *pienriistaAreasButton;

@end

@implementation RiistaMapSettingsViewController
{
    RiistaClubAreaMapManager *clubAreaManager;
    NSMutableArray<SelectedAreaMapItem*> *selectedAreaItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    selectedAreaItems = [NSMutableArray new];

    //Make button press highlights work better
    self.tableView.delaysContentTouches = NO;

    [self setupUi];
}

- (void)viewWillAppear:(BOOL)animated {
    //Fetch and cache maps
    if (clubAreaManager == nil) {
        clubAreaManager = [RiistaClubAreaMapManager new];
    }
    [clubAreaManager fetchMaps:^() {
    }];

    [self loadSelectedMaps];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadSelectedMaps
{
    [selectedAreaItems removeAllObjects];

    NSString *clubAreaId = [RiistaSettings activeClubAreaMapId];
    if (clubAreaId != nil && [clubAreaId length] > 0) {
        RiistaClubAreaMap *area = [clubAreaManager findById:clubAreaId];
        SelectedAreaMapItem* selected = [SelectedAreaMapItem new];
        selected.type = AreaTypeSeura;
        selected.title = [RiistaUtils getLocalizedString:area.club];
        selected.name = [RiistaUtils getLocalizedString:area.name];
        [selectedAreaItems addObject:selected];
    }

    AreaMap *pienriistaAreaMap = [RiistaSettings selectedPienriistaArea];
    if (pienriistaAreaMap != nil) {
        SelectedAreaMapItem* selected = [SelectedAreaMapItem new];
        selected.type = AreaTypePienriista;
        selected.title = [pienriistaAreaMap getAreaNumberAsString];
        selected.name = [pienriistaAreaMap getAreaName];
        [selectedAreaItems addObject:selected];
    }

    AreaMap *mooseAreaMap = [RiistaSettings selectedMooseArea];
    if (mooseAreaMap != nil) {
        SelectedAreaMapItem* selected = [SelectedAreaMapItem new];
        selected.type = AreaTypeMoose;
        selected.title = [mooseAreaMap getAreaNumberAsString];
        selected.name = [mooseAreaMap getAreaName];
        [selectedAreaItems addObject:selected];
    }

    [self refreshSelectedAreaTypes];
    [self.tableView reloadData];
}

- (void)refreshSelectedAreaTypes
{
    NSString *selectedClubAreaId = [RiistaSettings activeClubAreaMapId];
    AreaMap *selectedPienriistaAreaMap = [RiistaSettings selectedPienriistaArea];
    AreaMap *selectedMooseAreaMap = [RiistaSettings selectedMooseArea];

    self.clubAreasButton.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    self.pienriistaAreasButton.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    self.mooseAreasButton.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);

    [self.clubAreasButton setImage:(selectedClubAreaId != nil ? [UIImage imageNamed:@"ic_pass_white.png"] : nil)
                          forState:UIControlStateNormal];
    [self.pienriistaAreasButton setImage:(selectedPienriistaAreaMap != nil ? [UIImage imageNamed:@"ic_pass_white.png"] : nil)
                                forState:UIControlStateNormal];
    [self.mooseAreasButton setImage:(selectedMooseAreaMap != nil ? [UIImage imageNamed:@"ic_pass_white.png"] : nil)
                           forState:UIControlStateNormal];
}

- (void)setupUi
{
    self.mapTypeLabel.text = RiistaLocalizedString(@"MapTypeSelect", nil);

    [AppTheme.shared setupSegmentedControllerWithSegmentedController:self.mapTypeSegmentedControl];

    [self.mapTypeSegmentedControl setImage:[[UIImage imageNamed:@"map_type_mml_topographic.jpg"]
                                            imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forSegmentAtIndex:0];
    [self.mapTypeSegmentedControl setImage:[[UIImage imageNamed:@"map_type_mml_background.jpg"]
                                            imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forSegmentAtIndex:1];
    [self.mapTypeSegmentedControl setImage:[[UIImage imageNamed:@"map_type_mml_aerial.jpg"]
                                            imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forSegmentAtIndex:2];
    [self.mapTypeSegmentedControl setImage:[[UIImage imageNamed:@"map_type_google.jpg"]
                                            imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forSegmentAtIndex:3];
//    [self.mapTypeSegmentedControl setTitle:RiistaLocalizedString(@"MapTypeTopographic", nil) forSegmentAtIndex:0];
//    [self.mapTypeSegmentedControl setTitle:RiistaLocalizedString(@"MapTypeBackgound", nil) forSegmentAtIndex:1];
//    [self.mapTypeSegmentedControl setTitle:RiistaLocalizedString(@"MapTypeAerial", nil) forSegmentAtIndex:2];
//    [self.mapTypeSegmentedControl setTitle:RiistaLocalizedString(@"MapTypeGoogle", nil) forSegmentAtIndex:3];
    [self setupMapTypeSelect];

    self.settingsLabel.text = RiistaLocalizedString(@"MapSettingGeneralTitle", nil);
    self.showLocationLabel.text = RiistaLocalizedString(@"MapSettingShowLocation", nil);
    self.invertLabel.text = RiistaLocalizedString(@"MapSettingInvertColors", nil);
    self.stateLandsLabel.text = RiistaLocalizedString(@"MapSettingStateLands", nil);
    self.rhyBordersLabel.text = RiistaLocalizedString(@"MapSettingRhyBorders", nil);
    self.gameTrianglesLabel.text = RiistaLocalizedString(@"MapSettingGameTriangles", nil);
    self.areaBordersLabel.text = RiistaLocalizedString(@"MapSettingSelectedAreas", nil);
    self.addAreasLabel.text = RiistaLocalizedString(@"MapAddArea", nil);

    self.showLocationSwitch.on = [RiistaSettings showMyMapLocation];
    [self.showLocationSwitch addTarget:self action:@selector(showLocationSwitched:) forControlEvents:UIControlEventValueChanged];

    self.invertSwitch.on = [RiistaSettings invertMapColors];
    [self.invertSwitch addTarget:self action:@selector(invertColorsSwitched:) forControlEvents:UIControlEventValueChanged];

    self.stateLandsSwitch.on = [RiistaSettings showStateOwnedLands];
    [self.stateLandsSwitch addTarget:self action:@selector(showStateLandsSwitched:) forControlEvents:UIControlEventValueChanged];

    self.rhyBordersSwitch.on = [RiistaSettings showRhyBorders];
    [self.rhyBordersSwitch addTarget:self action:@selector(showRhyBordersSwitched:) forControlEvents:UIControlEventValueChanged];

    self.gameTrianglesSwitch.on = [RiistaSettings showGameTriangles];
    [self.gameTrianglesSwitch addTarget:self action:@selector(showGameTrianglesSwitched:) forControlEvents:UIControlEventValueChanged];

    [self.clubAreasButton setTitle:RiistaLocalizedString(@"MapSettingAddAreaClub", nil) forState:UIControlStateNormal];
    [self setupButtonStyle:self.clubAreasButton];
    [self.clubAreasButton addTarget:self action:@selector(areasListClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self.mooseAreasButton setTitle:RiistaLocalizedString(@"MapSettingAddAreaMoose", nil) forState:UIControlStateNormal];
    [self setupButtonStyle:self.mooseAreasButton];
    [self.mooseAreasButton addTarget:self action:@selector(areasListClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self.pienriistaAreasButton setTitle:RiistaLocalizedString(@"MapSettingAddAreaPienriista", nil) forState:UIControlStateNormal];
    [self setupButtonStyle:self.pienriistaAreasButton];
    [self.pienriistaAreasButton addTarget:self action:@selector(areasListClicked:) forControlEvents:UIControlEventTouchUpInside];

    RiistaNavigationController *controller = (RiistaNavigationController*)self.navigationController;
    [controller setTitle:RiistaLocalizedString(@"Map", nil)];
    [controller setRightBarItems:@[]];
}

- (void)setupButtonStyle:(MDCButton*)button
{
    [button applyTextThemeWithScheme:AppTheme.shared.cardButtonScheme];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    [button setTitleEdgeInsets:UIEdgeInsetsZero];
}

- (void)setupMapTypeSelect
{
    RiistaMapType mapTypeSetting = [RiistaSettings mapType];
    if (mapTypeSetting == MmlTopographicMapType) {
        [self.mapTypeSegmentedControl setSelectedSegmentIndex:0];
    }
    else if (mapTypeSetting == MmlBackgroundMapType) {
        [self.mapTypeSegmentedControl setSelectedSegmentIndex:1];
    }
    else if (mapTypeSetting == MmlAerialMapType) {
        [self.mapTypeSegmentedControl setSelectedSegmentIndex:2];
    }
    else if (mapTypeSetting == GoogleMapType) {
        [self.mapTypeSegmentedControl setSelectedSegmentIndex:3];
    }
    else {
        [self.mapTypeSegmentedControl setSelectedSegmentIndex:0];
    }

    [self.mapTypeSegmentedControl addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)mapTypeChanged:(id)sender
{
    if (self.mapTypeSegmentedControl) {
        NSInteger selectedIndex = self.mapTypeSegmentedControl.selectedSegmentIndex;

        if (selectedIndex == 0) {
            [RiistaSettings setMapTypeSetting:MmlTopographicMapType];
        }
        else if (selectedIndex == 1) {
            [RiistaSettings setMapTypeSetting:MmlBackgroundMapType];
        }
        else if (selectedIndex == 2) {
            [RiistaSettings setMapTypeSetting:MmlAerialMapType];
        }
        else if (selectedIndex == 3) {
            [RiistaSettings setMapTypeSetting:GoogleMapType];
        }
    }
}

- (void)showLocationSwitched:(id)sender
{
    [RiistaSettings setShowMyMapLocation:[sender isOn]];
}

- (void)invertColorsSwitched:(id)sender
{
    [RiistaSettings setInvertMapColors:[sender isOn]];
}

- (void)showStateLandsSwitched:(id)sender
{
    [RiistaSettings setShowStateOwnedLands:[sender isOn]];
}

- (void)showRhyBordersSwitched:(id)sender
{
    [RiistaSettings setShowRhyBorders:[sender isOn]];
}

- (void)showGameTrianglesSwitched:(id)sender
{
    [RiistaSettings setShowGameTriangles:[sender isOn]];
}

- (void)areasListClicked:(id)sender
{
    if (sender == self.clubAreasButton) {
        RiistaMapAreaListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MapAreaListController"];
        [controller setAreaTypeWithType:AreaTypeSeura];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else if (sender == self.mooseAreasButton) {
        RiistaMapAreaListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MapAreaListController"];
        [controller setAreaTypeWithType:AreaTypeMoose];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else if (sender == self.pienriistaAreasButton) {
        RiistaMapAreaListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MapAreaListController"];
        [controller setAreaTypeWithType:AreaTypePienriista];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)deleteAreaClicked:(id)sender
{
    NSInteger tag = ((UIButton*)sender).tag;
    SelectedAreaMapItem *item = [selectedAreaItems objectAtIndex:tag];

    if (item.type == AreaTypeSeura) {
        [RiistaSettings setActiveClubAreaMapId:nil];
    }
    else if (item.type == AreaTypeMoose) {
        [RiistaSettings setSelectedMooseArea:nil];
    }
    else if (item.type == AreaTypePienriista) {
        [RiistaSettings setSelectedPienriistaArea:nil];
    }

    [self loadSelectedMaps];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return selectedAreaItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SelectedAreaMapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    SelectedAreaMapItem *map = [selectedAreaItems objectAtIndex:indexPath.row];

    cell.titleLabel.text = map.title;
    cell.nameLabel.text = map.name;

    [cell.deleteAreaButton applyTextThemeWithScheme:AppTheme.shared.buttonContainerScheme];
    cell.deleteAreaButton.backgroundColor = UIColor.clearColor;
    cell.deleteAreaButton.tag = indexPath.row;
    [cell.deleteAreaButton addTarget:self action:@selector(deleteAreaClicked:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

@end
