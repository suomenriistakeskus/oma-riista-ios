#import <GoogleMaps/GoogleMaps.h>
#import "RiistaLocalization.h"
#import "RiistaMapViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaSettings.h"
#import "RiistaMapUtils.h"
#import "RiistaUtils.h"
#import "RiistaVectorTileLayer.h"
#import "RiistaClubAreaMapManager.h"
#import "GeoCoordinate.h"
#import "Styles.h"
#import "UIColor+ApplicationColor.h"
#import "Oma_riista-Swift.h"

@interface RiistaMapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, GMUClusterManagerDelegate, GMUClusterRendererDelegate, LogFilterDelegate, LogDelegate>

@property (weak, nonatomic) IBOutlet LogFilterView *filterView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *filterHeight;

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;

@property (weak, nonatomic) IBOutlet UIImageView *crosshairImage;
@property (weak, nonatomic) IBOutlet MDCButton *goToGpsButton;
@property (weak, nonatomic) IBOutlet MDCButton *setLocationButton;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *activeMapLabel;

@property (weak, nonatomic) IBOutlet MDCCard *buttonCardContainer;
@property (weak, nonatomic) IBOutlet UIButton *mapCenterButton;
@property (weak, nonatomic) IBOutlet UIButton *mapZoomInButton;
@property (weak, nonatomic) IBOutlet UIButton *mapZoomOutButton;
@property (weak, nonatomic) IBOutlet UIButton *mapMeasureButton;
@property (weak, nonatomic) IBOutlet UIButton *fullscreenButton;

@property (weak, nonatomic) IBOutlet MDCCard *showButtonsCardContainer;
@property (weak, nonatomic) IBOutlet UIButton *mapShowButtons;

@property (weak, nonatomic) IBOutlet UIView *mapScaleView;
@property (weak, nonatomic) IBOutlet UILabel *mapScaleLabel;

@property (weak, nonatomic) IBOutlet UILabel *mapMeasureLabel;
@property (weak, nonatomic) IBOutlet MDCButton *mapMeasureAddButton;
@property (weak, nonatomic) IBOutlet MDCButton *mapMeasureRemoveButton;

@property (strong, nonatomic) CLLocation *gpsLocation;
@property (strong, nonatomic) RiistaMmlTileLayer *tileLayer;
@property (strong, nonatomic) RiistaVectorTileLayer *vectorLayer;

@property (strong, nonatomic) RiistaVectorTileLayer *valtionmaatLayer;
@property (strong, nonatomic) RiistaVectorTileLayer *rhyBordersLayer;
@property (strong, nonatomic) RiistaVectorTileLayer *mooseAreaLayer;
@property (strong, nonatomic) RiistaVectorTileLayer *pienriistaAreaLayer;
@property (strong, nonatomic) RiistaVectorTileLayer *gameTrianglesLayer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toggleCardWidthContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerTrailingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerEditBottomConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topExpandConstraint;

@end

@implementation RiistaMapViewController
{
    CLLocationManager *locationManager;
    GMSMarker *locationMarker;
    GMSCircle *accuracyCircle;

    /**
     * Keep track of view height before entering fullscreen. Allows restoring view back to normal state afterwards.
     */
    CGFloat heightBeforeFullscreen;

    BOOL measureMode;
    NSMutableArray<CLLocation*> *measurePoints;
    GMSPolyline *measureLine;

    RiistaClubAreaMapManager *areaManager;

    GMUClusterManager *_clusterManager;

    HarvestControllerHolder *_harvestControllerHolder;
    ObservationControllerHolder *_observationsControllerHolder;
    SrvaControllerHolder *_srvaControllerHolder;

    NSMutableArray *addedMarkerCache;
    NSMutableArray *removedMarkerCache;

    LogItemService *logItemService;

    UIBarButtonItem *displayPinsButton;

    BOOL isFullscreen;

    /**
     We're setting camera location in viewWillAppear. Prevent setting it multiple times
     with a flag i.e. keep previous location if it has been set previously.
     */
    BOOL _initialCameraLocationHasBeenSet;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    areaManager = [RiistaClubAreaMapManager new];

    measureMode = NO;
    measurePoints = [NSMutableArray new];

    _mapView.delegate = self;
    _mapView.settings.rotateGestures = NO;
    _mapView.settings.tiltGestures = NO;

    _initialCameraLocationHasBeenSet = NO;

    addedMarkerCache = [NSMutableArray new];
    removedMarkerCache = [NSMutableArray new];

    [self setupMapLayers];

    [Styles styleNegativeButton:_goToGpsButton];
    [_goToGpsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [_goToGpsButton applyOutlinedThemeWithScheme:AppTheme.shared.cardButtonScheme];
    [_goToGpsButton setTitleColor:[UIColor applicationColor:TextOnPrimary] forState:UIControlStateNormal];
    [_goToGpsButton addTarget:self action:@selector(goToGpsButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    [Styles styleButton:_setLocationButton];
    [_setLocationButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [_setLocationButton applyOutlinedThemeWithScheme:AppTheme.shared.cardButtonScheme];
    [_setLocationButton setTitleColor:[UIColor applicationColor:TextOnPrimary] forState:UIControlStateNormal];
    [_setLocationButton addTarget:self action:@selector(setLocationButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    id<GMUClusterAlgorithm> algorithm = [[GMUNonHierarchicalDistanceBasedAlgorithm alloc] init];
    id<GMUClusterIconGenerator> iconGenerator = [[GMUDefaultClusterIconGenerator alloc] init];
    GMUDefaultClusterRenderer *renderer = [[GMUDefaultClusterRenderer alloc] initWithMapView:_mapView
                                                                        clusterIconGenerator:iconGenerator];
    renderer.delegate = self;

    _clusterManager = [[GMUClusterManager alloc] initWithMap:_mapView algorithm:algorithm renderer:renderer];
    [_clusterManager setDelegate:self mapDelegate:self];

    [self initFetchedResultsControllers];
    _filterView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.filterView updateTexts];
    [self.filterView setLogTypeWithType:logItemService.selectedLogType];
    [self.filterView setSeasonStartYearWithYear:logItemService.selectedSeasonStart];

    [self.filterView refreshFilteredSpeciesWithSelectedCategory:(logItemService.hasCategory ? logItemService.getCategory : -1)
                                                selectedSpecies:[logItemService selectedSpecies]];

    self.filterHeight.constant = _hidePins ? 0 : _filterView.frame.size.height;
    [self.filterView setHidden:_hidePins];
    LogItemService.shared.logDelegate = self;

    if (!_initialCameraLocationHasBeenSet) {
        _initialCameraLocationHasBeenSet = YES;
        if (_location != nil) {
            [self updateLocation:_location animateCamera:NO];
        }
        else {
            // Initial position center point of Finland
            [_mapView setCamera:[GMSCameraPosition cameraWithLatitude:DefaultMapLocation.Latitude
                                                            longitude:DefaultMapLocation.Longitude
                                                                 zoom:DefaultMapLocation.Zoom]];
        }
    }

    RiistaLanguageRefresh;
    [self.goToGpsButton setTitle:RiistaLocalizedString(@"MapPageGoToCurrentGps", nil) forState:UIControlStateNormal];
    [self.setLocationButton setTitle:RiistaLocalizedString(@"MapPageSetLocation", nil) forState:UIControlStateNormal];

    [self updateTitle];

    [_goToGpsButton setHidden:self.editMode ? NO : YES];
    [_goToGpsButton setEnabled:self.gpsLocation != nil ? YES: NO];
    [_setLocationButton setHidden:self.editMode ? NO : YES];
    [self.buttonContainerEditBottomConstraint setActive:self.editMode];

    [self setupMapLayers];
    [self setupAppBarButtons];
    [self setupMapButtons];

    [self updateMapSettings];
    [self updateMeasurements];
    [self updateMapButtonsVisibility];
    [self updateUserMapMarker];

    //Fetch and cache maps
    [areaManager fetchMaps:^() {
        [self updateMapAreaText];
    }];

    [_filterView setupUserRelatedData];
    [_filterView setLogTypeWithType:LogItemService.shared.selectedLogType];
    [_filterView setSeasonStartYearWithYear:LogItemService.shared.selectedSeasonStart];

    if ([LogItemService.shared hasCategory]) {
        [_filterView setSelectedCategoryWithCategoryCode:[LogItemService.shared getCategory]];
    }
    else {
        [_filterView setSelectedSpeciesWithSpeciesCodes:[LogItemService.shared selectedSpecies]];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshAfterManagedObjectContextChange)
                                                 name:ManagedObjectContextChangedNotification
                                               object:nil];

}

- (void)refreshAfterManagedObjectContextChange {
    [self refreshFilteredItemList];
    [_filterView setupUserRelatedData];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (_editMode || [RiistaSettings showMyMapLocation]) {
        [self setupLocationManager];

    }

    [self refreshFilteredItemList];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIStatusBarStyle fullScreenStyle = UIStatusBarStyleDefault;
    if (@available(iOS 13.0, *)) {
        fullScreenStyle = UIStatusBarStyleDarkContent;
    }
    return isFullscreen ? fullScreenStyle : UIStatusBarStyleLightContent;
}

- (void)refreshFilteredItemList
{
    if (self.hidePins) {
        [_clusterManager clearItems];
    }
    else {
        switch (LogItemService.shared.selectedLogType) {
            case RiistaEntryTypeHarvest: {
                NSFetchedResultsController* harvestController = [_harvestControllerHolder getObject];
                harvestController.fetchRequest.predicate = [LogItemService.shared setupHarvestPredicateWithOnlyWithImage:NO];

                NSError *error;
                [harvestController performFetch:&error];
                if (error != nil) {
                    NSLog(@"Failed to performFetch");
                }
                break;
            }
            case RiistaEntryTypeObservation: {
                NSFetchedResultsController* observationController = [_observationsControllerHolder getObject];
                observationController.fetchRequest.predicate = [LogItemService.shared setupObservationPredicateWithOnlyWithImage:NO];

                NSError *error;
                [observationController performFetch:&error];
                if (error != nil) {
                    NSLog(@"Failed to performFetch");
                }
                break;
            }
            case RiistaEntryTypeSrva: {
                NSFetchedResultsController* srvaController = [_srvaControllerHolder getObject];
                srvaController.fetchRequest.predicate = [LogItemService.shared setupSrvaPredicateWithOnlyWithImage:NO];

                NSError *error;
                [srvaController performFetch:&error];
                if (error != nil) {
                    NSLog(@"Failed to performFetch");
                }
                break;
            }
            default:
                break;
        }

        [self populateVisibleMarkerClusters];
    }
}

- (void)initFetchedResultsControllers
{
    _harvestControllerHolder = [[HarvestControllerHolder alloc] init];
    _observationsControllerHolder = [[ObservationControllerHolder alloc] initWithOnlyWithImages:NO];
    _srvaControllerHolder = [[SrvaControllerHolder alloc] initWithOnlyWithImages:NO];
}

- (void)setupMapLayers
{
    [_mapView setMinZoom:MapConstants.MinZoom maxZoom:MapConstants.MaxZoom];

    if ([RiistaSettings mapType] == GoogleMapType) {
        _mapView.mapType = kGMSTypeNormal;

        if (self.tileLayer) {
            self.tileLayer.map = nil;
            self.tileLayer = nil;
        }
        self.copyrightLabel.hidden = YES;
    }
    else {
        // MML map tiles
        _mapView.mapType = kGMSTypeNone;

        if (!self.tileLayer) {
            self.tileLayer = [RiistaMmlTileLayer new];
        }
        [self.tileLayer setMapType:[RiistaSettings mapType]];
        self.tileLayer.map = _mapView;

        self.copyrightLabel.text = RiistaLocalizedString(@"MapCopyrightMml", nil);
        self.copyrightLabel.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.copyrightLabel.hidden = NO;
    }

    if (!self.vectorLayer) {
        self.vectorLayer = [RiistaVectorTileLayer new];
        [self.vectorLayer setAreaType:AreaTypeSeura];
        self.vectorLayer.zIndex = 10;
        self.vectorLayer.map = _mapView;
    }

    if (!self.valtionmaatLayer) {
        self.valtionmaatLayer = [RiistaVectorTileLayer new];
        [self.valtionmaatLayer setAreaType:AreaTypeValtionmaa];
        self.valtionmaatLayer.zIndex = 20;
        self.valtionmaatLayer.map = _mapView;
    }

    if (!self.rhyBordersLayer) {
        self.rhyBordersLayer = [RiistaVectorTileLayer new];
        [self.rhyBordersLayer setAreaType:AreaTypeRhy];
        self.rhyBordersLayer.zIndex = 30;
        self.rhyBordersLayer.map = _mapView;
    }

    if (!self.mooseAreaLayer) {
        self.mooseAreaLayer = [RiistaVectorTileLayer new];
        [self.mooseAreaLayer setAreaType:AreaTypeMoose];
        self.mooseAreaLayer.zIndex = 40;
        self.mooseAreaLayer.map = _mapView;
    }

    if (!self.pienriistaAreaLayer) {
        self.pienriistaAreaLayer = [RiistaVectorTileLayer new];
        [self.pienriistaAreaLayer setAreaType:AreaTypePienriista];
        self.pienriistaAreaLayer.zIndex = 50;
        self.pienriistaAreaLayer.map = _mapView;
    }

    if (!self.gameTrianglesLayer) {
        self.gameTrianglesLayer = [RiistaVectorTileLayer new];
        [self.gameTrianglesLayer setAreaType:AreaTypeGameTriangles];
        self.gameTrianglesLayer.zIndex = 60;
        self.gameTrianglesLayer.map = _mapView;
    }
}

- (void)setupAppBarButtons
{
    NSMutableArray *buttons = [NSMutableArray new];

    UIImage *settingsImage = [UIImage imageNamed:@"ic_settings.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                         landscapeImagePhone:settingsImage
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(showSettings:)
                                       ];
    [buttons addObject:settingsButton];

    [self.riistaController setRightBarItems:buttons];

    if (!_hidePins) {
        UIImage *toggleImage = [UIImage imageNamed:@"pins_white"];
        displayPinsButton = [[UIBarButtonItem alloc] initWithImage:toggleImage
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(togglePins:)];
        [self.riistaController setLeftBarItem:displayPinsButton];
    }
}

- (void)setupMapButtons
{
    [self.mapCenterButton addTarget:self action:@selector(goToGpsButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapCenterButton setEnabled:[RiistaSettings showMyMapLocation]];

    [self.mapZoomInButton addTarget:self action:@selector(zoomInPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapZoomOutButton addTarget:self action:@selector(zoomOutPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapMeasureButton addTarget:self action:@selector(measurePressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullscreenButton addTarget:self action:@selector(fullscreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapShowButtons addTarget:self action:@selector(showButtonsPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.showButtonsCardContainer.shapeGenerator = [AppTheme.shared leftRoundedTopCutBottomShapegenerator];
    self.buttonCardContainer.shapeGenerator = [AppTheme.shared bottomLeftRoundedShapegenerator];

    [AppTheme.shared setupPrimaryButtonThemeWithButton:self.mapMeasureAddButton];
    self.mapMeasureAddButton.backgroundColor = [UIColor applicationColor:ViewBackground];
    self.mapMeasureAddButton.imageEdgeInsets = UIEdgeInsetsMake(-6.0f, -6.0f, -6.0f, -6.0f);
    [self.mapMeasureAddButton addTarget:self action:@selector(measureAddPressed:) forControlEvents:UIControlEventTouchUpInside];

    [AppTheme.shared setupPrimaryButtonThemeWithButton:self.mapMeasureRemoveButton];
    self.mapMeasureRemoveButton.backgroundColor = [UIColor applicationColor:ViewBackground];
    self.mapMeasureRemoveButton.imageEdgeInsets = UIEdgeInsetsMake(-6.0f, -6.0f, -6.0f, -6.0f);
    [self.mapMeasureRemoveButton addTarget:self action:@selector(measureRemovePressed:) forControlEvents:UIControlEventTouchUpInside];

    // Edit buttons would overlay measurement controls, and measurement is not relevant in edit mode.
    // -> Hide measurement button in edit mode.
    [self.mapMeasureButton setHidden:self.editMode];
}

-(void)animateButtonToolbar:(BOOL)show
{
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:.1 animations:^{
        self.toggleCardWidthContraint.constant = show ? 52 : 48;
        self.buttonContainerTrailingConstraint.constant = show ? 0 : -self.buttonCardContainer.bounds.size.width;

        [self.mapShowButtons setImage:[UIImage imageNamed:show ? @"menu_hide" : @"menu_expand"] forState:UIControlStateNormal];

        [self.view layoutIfNeeded];
    }];
}

-(void)toggleFullscreen
{
    isFullscreen = !isFullscreen;

    BOOL fullscreen = isFullscreen; // used in animations, property may change
    [UIView animateWithDuration:.1 animations:^{
        if (self->heightBeforeFullscreen <= 1.f) {
            self->heightBeforeFullscreen = self.view.frame.size.height;
        }

        if (!fullscreen) {
            // setNeedsStatusBarAppearanceUpdate will only update status bar appearance
            // if navigation bar has been hidden with setNavigationBarHidden:YES
            // -> if exiting fullscreen make the call when we're still in hidden state
            //    or otherwise statusbar appearance won't get updated
            [self setNeedsStatusBarAppearanceUpdate];
        }

        UIViewController *presentingViewController = self.presentingViewController;
        if (presentingViewController) {
            UITabBarController *tabController = presentingViewController.tabBarController;
            [tabController.tabBar setHidden:fullscreen];
            [tabController.tabBar setUserInteractionEnabled:!fullscreen];
            [presentingViewController.navigationController setNavigationBarHidden:fullscreen animated:YES];

            // move bottom only when displaying as a tab i.e. there's a presenting view controller
            CGFloat windowHeight = self.view.window.frame.size.height;
            CGRect frame = self.view.frame;
            frame.size.height = fullscreen ? windowHeight : self->heightBeforeFullscreen;
            [self.view setFrame:frame];
        } else {
            [self.navigationController setNavigationBarHidden:fullscreen animated:YES];
        }

        if (fullscreen) {
            // setNeedsStatusBarAppearanceUpdate will only update status bar appearance
            // if navigation bar has been hidden with setNavigationBarHidden:YES
            [self setNeedsStatusBarAppearanceUpdate];
        } else {
            // exiting fullscreen -> clear height before fullscreen so that it gets reinitialized
            // before when entering fullscreen next time
            self->heightBeforeFullscreen = 0.f;
        }

        [self.fullscreenButton setImage:[UIImage imageNamed:(fullscreen ? @"collapse" : @"expand")] forState:UIControlStateNormal];

        [self.view layoutIfNeeded];
    }];
}

- (void)exitFullscreen
{
    if (isFullscreen) {
        [self toggleFullscreen];
    }
}

- (void)zoomInPressed:(id)sender
{
    [self.mapView animateToZoom:self.mapView.camera.zoom + 1.0f];
}

- (void)zoomOutPressed:(id)sender
{
    [self.mapView animateToZoom:self.mapView.camera.zoom - 1.0f];
}

- (void)measurePressed:(id)sender
{
    measureMode = !measureMode;
    if (measureMode) {
        [self startMeasurement];
    }
    else {
        [self stopMeasurement];
    }
    [self updateMeasurements];
}


- (void)fullscreenPressed:(id)sender
{
    [self toggleFullscreen];
}

- (void)showButtonsPressed:(id)sender
{
    [RiistaSettings setHideMapButtons:![RiistaSettings hideMapButtons]];
    [self updateMapButtonsVisibility];
}

- (void)measureAddPressed:(id)sender
{
    [self addMeasurementPoint];
}

- (void)measureRemovePressed:(id)sender
{
    [self removeMeasurementPoint];
}

- (void)setupLocationManager
{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    // iOS8 location service start fails silently unless authorization is explicitly requested.
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }

    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *newLocation = locations.lastObject;
    _gpsLocation = newLocation;
    [_goToGpsButton setEnabled:YES];

    [self updateUserMapMarker];
}

- (void)startMeasurement
{
    [self addMeasurementPoint];
}

- (void)stopMeasurement
{
    measureMode = NO;
    [measurePoints removeAllObjects];

    if (measureLine) {
        measureLine.map = nil;
        measureLine = nil;
    }

    [self updateMeasurements];
}

- (void)addMeasurementPoint
{
    CLLocationCoordinate2D mapCenterCoord = [self.mapView.camera target];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:mapCenterCoord.latitude
                                                      longitude:mapCenterCoord.longitude];
    [measurePoints addObject:location];

    [self updateMeasurements];
}

- (void)removeMeasurementPoint
{
    if (measurePoints.count > 0) {
        [measurePoints removeLastObject];
    }

    if (measurePoints.count == 0) {
        [self stopMeasurement];
    }
    [self updateMeasurements];
}

- (void)updateMeasurements
{
    if (measureMode) {
        NSMutableArray<CLLocation*> *locations = [[NSMutableArray alloc] initWithArray:measurePoints];

        CLLocationCoordinate2D target = self.mapView.camera.target;
        CLLocation *pos = [[CLLocation alloc] initWithLatitude:target.latitude longitude:target.longitude];
        [locations addObject:pos];

        double total = 0.0;
        for (int i = 1; i < locations.count; i++) {
            CLLocation *a = [locations objectAtIndex:i - 1];
            CLLocation *b = [locations objectAtIndex:i];
            total += [a distanceFromLocation:b];
        }
        self.mapMeasureLabel.text = [self formatDistance:total];

        if (measureLine == nil) {
            measureLine = [GMSPolyline new];
            measureLine.strokeWidth = 3.0f;
            measureLine.strokeColor = [UIColor redColor];
            measureLine.zIndex = 100;
            measureLine.map = self.mapView;
        }

        GMSMutablePath *path = [GMSMutablePath path];
        for (int i = 0; i < locations.count; i++) {
            CLLocation *pos = [locations objectAtIndex:i];
            [path addLatitude:pos.coordinate.latitude longitude:pos.coordinate.longitude];
        }
        measureLine.path = path;
    }

    BOOL hideUi = !measureMode;
    self.mapMeasureLabel.hidden = hideUi;
    self.mapMeasureAddButton.hidden = hideUi;
    self.mapMeasureRemoveButton.hidden = hideUi;

    self.mapMeasureButton.selected = measureMode;
}

- (void)updateMapSettings
{
    NSString *activeArea = [RiistaSettings activeClubAreaMapId];

    if (self.vectorLayer) {
        if (self.overrideAreaExternalId) {
            [self.vectorLayer setExternalId:self.overriddenAreaExternalId];
            [self.vectorLayer setInvertColors:self.overriddenAreaInvertColors];
        } else {
            [self.vectorLayer setExternalId:activeArea];
            [self.vectorLayer setInvertColors:[RiistaSettings invertMapColors]];
        }
    }

    if (self.valtionmaatLayer) {
        [self.valtionmaatLayer setExternalId:([RiistaSettings showStateOwnedLands] ? @"-1" : nil)];
    }

    if (self.rhyBordersLayer) {
        [self.rhyBordersLayer setExternalId:([RiistaSettings showRhyBorders] ? @"-1" : nil)];
    }

    if (self.mooseAreaLayer) {
        AreaMap *map = [RiistaSettings selectedMooseArea];
        [self.mooseAreaLayer setExternalId:(map != nil ? [map getAreaNumberAsString] : nil)];
    }

    if (self.pienriistaAreaLayer) {
        AreaMap *map = [RiistaSettings selectedPienriistaArea];
        [self.pienriistaAreaLayer setExternalId:(map != nil ? [map getAreaNumberAsString] : nil)];
    }

    if (self.gameTrianglesLayer) {
        [self.gameTrianglesLayer setExternalId:([RiistaSettings showGameTriangles] ? @"-1" : nil)];
    }

    [self updateMapAreaText];
}

-(void)updateMapAreaText
{
//    NSString *activeArea = [RiistaSettings activeClubAreaMapId];
//    RiistaClubAreaMap *map = [areaManager findById:activeArea];
//    if (activeArea && map) {
//        self.activeMapLabel.text = [RiistaUtils getLocalizedString:map.name];
//        self.activeMapLabel.hidden = NO;
//    }
//    else {
//        self.activeMapLabel.hidden = YES;
//    }
}

- (void)updateMapButtonsVisibility
{
    BOOL show = ![RiistaSettings hideMapButtons];

    [self animateButtonToolbar:show];
}

- (void)updateLocation:(CLLocation*)newLocation animateCamera:(BOOL)animateCamera
{
    if (animateCamera) {
        [self animateAndZoomCameraTo:newLocation zoom:MapConstants.DefaultZoomToLevel];
    }
    else {
        [_mapView moveCamera:[GMSCameraUpdate setTarget:newLocation.coordinate zoom:MapConstants.DefaultZoomToLevel]];
    }

    [self updateUserMapMarker];
}

- (void)updateUserMapMarker
{
    CLLocation *newLocation = nil;
    BOOL show = NO;

    if (_location) {
        newLocation = _location;
        show = YES;
    }
    else if (_gpsLocation) {
        newLocation = _gpsLocation;
        show = [RiistaSettings showMyMapLocation];
    }

    if (accuracyCircle) {
        accuracyCircle.map = nil;
        accuracyCircle = nil;
    }
    if (show && newLocation.horizontalAccuracy > 0) {
        accuracyCircle = [GMSCircle circleWithPosition:newLocation.coordinate
                                                radius:newLocation.horizontalAccuracy];
        accuracyCircle.map = _mapView;
        accuracyCircle.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0.25 alpha:0.1];
        accuracyCircle.strokeColor = [UIColor redColor];
        accuracyCircle.strokeWidth = 1;
    }

    if (locationMarker) {
        locationMarker.map = nil;
        locationMarker = nil;
    }
    if (show) {
        locationMarker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(newLocation.coordinate.latitude,
                                                                                  newLocation.coordinate.longitude)];
        locationMarker.map = _mapView;
        _mapView.selectedMarker = locationMarker;
    }
}

- (void)animateAndZoomCameraTo:(CLLocation*)targetLocation zoom:(float)zoom
{
    // Move then zoom in separate steps since animate route is unpredictable and may go outside MML tile area if done
    // at the same time.
    [_mapView animateToLocation:targetLocation.coordinate];
    [_mapView animateToZoom:zoom];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    NSLog(@"Location manager failed with error: %@", error);
}

- (void)pageSelected
{
//    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
//    [navController setLeftBarItem:nil];
//    [navController setRightBarItems:nil];
//
//    navController.title = _titlePrimaryText;
}

- (void)updateTitle
{
    [self.riistaController changeTitle:_titlePrimaryText];
}

- (void)goToGpsButtonClick:(id)sender
{
    if (_gpsLocation != nil) {
        [self animateAndZoomCameraTo:_gpsLocation zoom:MapConstants.DefaultZoomToLevel];
    }
}

- (void)setLocationButtonClick:(id)sender
{
    CLLocationCoordinate2D center = _mapView.camera.target;

    [self.delegate locationSetManually:center];
    [self exitFullscreen];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showSettings:(id)sender
{
    MapSettingsViewController* controller = [[MapSettingsViewController alloc] init];
    [self.riistaController pushViewController:controller animated:YES];
}

- (void)togglePins:(id)sender
{
    [_filterView setHidden:!_filterView.isHidden];
    [_filterHeight setConstant:_filterView.isHidden ? 0 : _filterView.frame.size.height];

    if (_filterView.isHidden) {
        [_clusterManager clearItems];

        [displayPinsButton setImage:[UIImage imageNamed:@"pins_disabled_white"]];
    }
    else {
        [self populateVisibleMarkerClusters];

        [displayPinsButton setImage:[UIImage imageNamed:@"pins_white"]];
    }
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position;
{
    [self updateMapScaleText];

    if (measureMode) {
        [self updateMeasurements];
    }

    [self resetMarkerClusters];
}

- (void)updateMapScaleText
{
    CGRect frame = self.mapView.frame;
    int scaleWidth = self.mapScaleView.frame.size.width;

    CLLocationCoordinate2D a = [self.mapView.projection
                                coordinateForPoint:CGPointMake(0, frame.size.height / 2)];
    CLLocationCoordinate2D b = [self.mapView.projection
                                coordinateForPoint:CGPointMake(scaleWidth, frame.size.height / 2)];

    CLLocation *start = [[CLLocation alloc] initWithLatitude:a.latitude longitude:a.longitude];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:b.latitude longitude:b.longitude];

    CLLocationDistance distance = [start distanceFromLocation:end];
    self.mapScaleLabel.text = [self formatDistance:distance];
}

- (NSString*)formatDistance:(double)meters
{
    if (meters > 1000.0) {
        return [NSString stringWithFormat:@"%.1f km", meters / 1000.0];
    }
    else {
        return [NSString stringWithFormat:@"%i m", (int)meters];
    }
}

- (void)populateVisibleMarkerClusters {
    [_clusterManager clearItems];

    switch (LogItemService.shared.selectedLogType) {
        case RiistaEntryTypeHarvest: {
            NSFetchedResultsController *harvestController = [_harvestControllerHolder getObject];
            for (DiaryEntry *item in harvestController.fetchedObjects) {
                WGS84Pair *wgs84Pair = [[RiistaMapUtils sharedInstance] ETRMStoWGS84:[item.coordinates.latitude longValue]
                                                                                   y:[item.coordinates.longitude longValue]];

                [_clusterManager addItem:[[MapMarkerItem alloc] initWithPosition:CLLocationCoordinate2DMake(wgs84Pair.x, wgs84Pair.y)
                                                                            type:RiistaEntryTypeHarvest
                                                                         localId:item.objectID]];
            }
            break;
        }
        case RiistaEntryTypeObservation: {
            NSFetchedResultsController *observationController = [_observationsControllerHolder getObject];
            for (ObservationEntry *item in observationController.fetchedObjects) {
                WGS84Pair *wgs84Pair = [[RiistaMapUtils sharedInstance] ETRMStoWGS84:[item.coordinates.latitude longValue]
                                                                                   y:[item.coordinates.longitude longValue]];

                [_clusterManager addItem:[[MapMarkerItem alloc] initWithPosition:CLLocationCoordinate2DMake(wgs84Pair.x, wgs84Pair.y)
                                                                            type:RiistaEntryTypeObservation
                                                                         localId:item.objectID]];
            }
            break;
        }
        case RiistaEntryTypeSrva: {
            NSFetchedResultsController *srvaController = [_srvaControllerHolder getObject];
            for (SrvaEntry *item in srvaController.fetchedObjects) {
                WGS84Pair *wgs84Pair = [[RiistaMapUtils sharedInstance] ETRMStoWGS84:[item.coordinates.latitude longValue]
                                                                                   y:[item.coordinates.longitude longValue]];

                [_clusterManager addItem:[[MapMarkerItem alloc] initWithPosition:CLLocationCoordinate2DMake(wgs84Pair.x, wgs84Pair.y)
                                                                            type:RiistaEntryTypeSrva
                                                                         localId:item.objectID]];
            }
            break;
        }
        default:
            break;
    }

    [self displayPins:self];
}

- (void)displayPins:(id)sender
{
    [_clusterManager cluster];
}

- (void)onFilterCategorySelectedWithCategoryCode:(NSInteger)categoryCode {
    [_filterView setSelectedCategoryWithCategoryCode:categoryCode];

    NSArray *species = [[RiistaGameDatabase sharedInstance] speciesListWithCategoryId:categoryCode];
    NSMutableArray *speciesCodes = [NSMutableArray new];

    for (RiistaSpecies *item in species) {
        [speciesCodes addObject:@(item.speciesId)];
    }

    [LogItemService.shared setSpeciesCategoryWithCategoryCode:categoryCode];
    [LogItemService.shared setSpeciesListWithSpeciesCodes:speciesCodes];
}

- (void)onFilterSeasonSelectedWithSeasonStartYear:(NSInteger)seasonStartYear {
    [LogItemService.shared setSeasonStartYearWithYear:seasonStartYear];
}

- (void)onFilterSpeciesSelectedWithSpeciesCodes:(NSArray<NSNumber *> * _Nonnull)speciesCodes {
    [_filterView setSelectedSpeciesWithSpeciesCodes:speciesCodes];

    [LogItemService.shared clearSpeciesCategory];
    [LogItemService.shared setSpeciesListWithSpeciesCodes:speciesCodes];
}

- (void)onFilterTypeSelectedWithType:(RiistaEntryType)type {
    [LogItemService.shared setItemTypeWithType:type];

    [_filterView setSeasonStartYearWithYear:[LogItemService.shared selectedSeasonStart]];
}

- (void)presentSpeciesSelect {
    [self exitFullscreen];
    [_filterView presentSpeciesSelectWithNavigationController:self.riistaController delegate:self];
}

- (void)refresh {
    [self refreshFilteredItemList];
}

- (void)expandCluster:(id<GMUCluster>)cluster
{
    int counter = 0;
    float rotateFactor = 360 / [cluster count];

    float MARKER_DEFAULT_RADIUS = 0.0007;

    for (MapMarkerItem *item in [cluster items]) {
        double lat = cluster.position.latitude + (MARKER_DEFAULT_RADIUS * cos(++counter * rotateFactor));
        double lon = cluster.position.longitude + (MARKER_DEFAULT_RADIUS * sin(counter * rotateFactor));
        MapMarkerItem *copy = [[MapMarkerItem alloc] initWithPosition:CLLocationCoordinate2DMake(lat, lon)
                                                                 type:item.type
                                                              localId:item.localId];

        [_clusterManager removeItem:item];
        [_clusterManager addItem:copy];
        [_clusterManager cluster];

        [addedMarkerCache addObject:copy];
        [removedMarkerCache addObject:item];
    }
}

- (void)resetMarkerClusters
{
    for (MapMarkerItem *item in addedMarkerCache) {
        [_clusterManager removeItem:item];
    }
    [_clusterManager addItems:removedMarkerCache];

    [_clusterManager cluster];

    [addedMarkerCache removeAllObjects];
    [removedMarkerCache removeAllObjects];
}

// Mark: - GMUClusterRendererDelegate

- (void)renderer:(id<GMUClusterRenderer>)renderer willRenderMarker:(GMSMarker *)marker {
    if ([marker.userData conformsToProtocol:@protocol(GMUClusterItem)]) {
        MapMarkerItem *mapMarker = (MapMarkerItem*)marker.userData;
        UIImage *image;

        switch (mapMarker.type) {
            case RiistaEntryTypeHarvest:
                image = [UIImage imageNamed:@"pin_harvest.png"];
                marker.icon = image;
                break;
            case RiistaEntryTypeObservation:
                image = [UIImage imageNamed:@"pin_observation.png"];
                marker.icon = image;
                break;
            case RiistaEntryTypeSrva:
                image = [UIImage imageNamed:@"pin_srva.png"];
                marker.icon = image;
                break;
            default:
                break;
        }
    }
}

- (BOOL)clusterManager:(GMUClusterManager *)clusterManager didTapCluster:(id<GMUCluster>)cluster {
    if (_mapView.camera.zoom >= (MapConstants.MaxZoom-0.01)) {
        [self expandCluster:cluster];
    } else {
        [self animateAndZoomCameraTo:[[CLLocation alloc] initWithLatitude:cluster.position.latitude longitude:cluster.position.longitude]
                                zoom:self.mapView.camera.zoom + 1.0];
    }

    return YES;
}

- (BOOL)clusterManager:(GMUClusterManager *)clusterManager didTapClusterItem:(id<GMUClusterItem>)clusterItem {
    MapMarkerItem *item = (MapMarkerItem*)clusterItem;

    if (_mapView.camera.zoom >= (MapConstants.MaxZoom-0.01)) {
        UIStoryboard *sb;
        UIViewController *dest;

        switch (item.type) {
            case RiistaEntryTypeHarvest: {
                sb = [UIStoryboard storyboardWithName:@"HarvestStoryboard" bundle:nil];
                dest = [sb instantiateInitialViewController];
                ((RiistaLogGameViewController*)dest).eventId = item.localId;

                UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@""
                                                                           source:self
                                                                      destination:dest
                                                                   performHandler:^(void) {
                    [self exitFullscreen];
                    [self.presentingViewController.navigationController pushViewController:dest animated:YES];
                }];
                [segue perform];

                break;
            }
            case RiistaEntryTypeObservation: {
                sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
                dest = [sb instantiateInitialViewController];
                ((DetailsViewController*)dest).observationId = item.localId;

                UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@""
                                                                           source:self
                                                                      destination:dest
                                                                   performHandler:^(void) {
                    [self exitFullscreen];
                    [self.presentingViewController.navigationController pushViewController:dest animated:YES];
                }];
                [segue perform];

                break;
            }
            case RiistaEntryTypeSrva: {
                sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
                dest = [sb instantiateInitialViewController];
                ((DetailsViewController*)dest).srvaId = item.localId;

                UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@""
                                                                           source:self
                                                                      destination:dest
                                                                   performHandler:^(void) {
                    [self exitFullscreen];
                    [self.presentingViewController.navigationController pushViewController:dest animated:YES];
                }];
                [segue perform];

                break;
            }
            default:
                break;
        }
    } else {
        [self animateAndZoomCameraTo:[[CLLocation alloc] initWithLatitude:item.position.latitude
                                                                longitude:item.position.longitude]
                                zoom:MapConstants.MaxZoom];
    }

    return YES;
}

@end
