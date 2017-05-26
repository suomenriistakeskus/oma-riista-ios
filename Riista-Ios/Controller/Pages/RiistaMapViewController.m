#import <GoogleMaps/GoogleMaps.h>
#import "RiistaLocalization.h"
#import "RiistaMapViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaSettings.h"
#import "RiistaMmlTileLayer.h"
#import "GeoCoordinate.h"
#import "Styles.h"
#import "UIColor+ApplicationColor.h"

NSInteger const TILE_TYPE_DIALOG_TAG = 1;
float const MIN_ZOOM = 4.0f;
float const MAX_ZOOM = 16.0f;

// Custom button overriding pressed hilight
@interface MapPageButton : UIButton

@property (assign, nonatomic) int hilightColor;

@end

@interface RiistaMapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *crosshairImage;
@property (weak, nonatomic) IBOutlet MapPageButton *goToGpsButton;
@property (weak, nonatomic) IBOutlet MapPageButton *setLocationButton;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;

@property (strong, nonatomic) UIAlertView *tileTypeAlertView;

@property (strong, nonatomic) CLLocation *gpsLocation;
@property (strong, nonatomic) RiistaMmlTileLayer *tileLayer;

@end

@implementation RiistaMapViewController
{
    CLLocationManager *locationManager;
    GMSMarker *locationMarker;
    GMSCircle *accuracyCircle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _mapView.delegate = self;
    _mapView.settings.rotateGestures = NO;
    _mapView.settings.tiltGestures = NO;

    if ([RiistaSettings mapType] == GoogleMapType) {
        self.copyrightLabel.hidden = YES;
    }
    else {
        // MML map tiles
        _mapView.mapType = kGMSTypeNone;
        [_mapView setMinZoom:MIN_ZOOM maxZoom:MAX_ZOOM];

        self.tileLayer = [RiistaMmlTileLayer new];
        [self.tileLayer setMapType:[RiistaSettings mapType]];
        self.tileLayer.map = _mapView;

        self.copyrightLabel.text = RiistaLocalizedString(@"MapCopyrightMml", nil);
        self.copyrightLabel.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.copyrightLabel.hidden = NO;
    }

    [Styles styleNegativeButton:_goToGpsButton];
    [_goToGpsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [_goToGpsButton setImageEdgeInsets:UIEdgeInsetsMake(17, 75, 17, 175)];
//    [_goToGpsButton setHilightColor:RiistaApplicationColorNegativeButtonBackgroundHighlightedAlpha];
    [_goToGpsButton addTarget:self action:@selector(goToGpsButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    [Styles styleButton:_setLocationButton];
    [_setLocationButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [_setLocationButton setImageEdgeInsets:UIEdgeInsetsMake(17, 75, 17, 175)];
//    [_setLocationButton setHilightColor:RiistaApplicationColorButtonBackgroundHighlightedAlpha];
    [_setLocationButton addTarget:self action:@selector(setLocationButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    [self.goToGpsButton setTitle:RiistaLocalizedString(@"MapPageGoToCurrentGps", nil) forState:UIControlStateNormal];
    [self.setLocationButton setTitle:RiistaLocalizedString(@"MapPageSetLocation", nil) forState:UIControlStateNormal];

    [self updateTitle];

    [_crosshairImage setHidden:self.editMode ? NO : YES];
    [_goToGpsButton setHidden:self.editMode ? NO : YES];
    [_goToGpsButton setEnabled:self.gpsLocation != nil ? YES: NO];
    [_setLocationButton setHidden:self.editMode ? NO : YES];

    if (_location != nil) {
        [self updateLocation:_location animateCamera:NO];
    }
    else {
        // Initial position center point of Finland
        [_mapView setCamera:[GMSCameraPosition cameraWithLatitude:64.10 longitude:25.48 zoom:4]];
    }

    [self setupBarLayersButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (_editMode) {
        [self setupLocationManager];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (locationManager != nil)
    {
        [locationManager stopUpdatingLocation];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.tileTypeAlertView) {
        [self.tileTypeAlertView dismissWithClickedButtonIndex:self.tileTypeAlertView.cancelButtonIndex animated:YES];
    }
}

- (void)dealloc
{
    if (self.tileTypeAlertView) {
        self.tileTypeAlertView.delegate = nil;
    }
}

- (void)setupBarLayersButton
{
    if ([RiistaSettings mapType] == GoogleMapType) {
        [((RiistaNavigationController*)self.navigationController) setRightBarItems:nil];
    }
    else {
        UIImage *layersImage = [UIImage imageNamed:@"ic_menu_layers.png"];
        UIBarButtonItem *layersButton = [[UIBarButtonItem alloc] initWithImage:layersImage
                                                           landscapeImagePhone:layersImage
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(selectMapTileType:)
                                         ];
        [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[layersButton]];
    }
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

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
    _gpsLocation = newLocation;
    [_goToGpsButton setEnabled:YES];

//    [self updateLocation:newLocation animateCamera:YES];
}

- (void)updateLocation:(CLLocation*)newLocation animateCamera:(BOOL)animateCamera
{

    if (animateCamera) {
        [self animateAndZoomCameraTo:newLocation];
    }
    else {
        [_mapView moveCamera:[GMSCameraUpdate setTarget:newLocation.coordinate zoom:15]];
    }

    if (accuracyCircle) {
        accuracyCircle.map = nil;
        accuracyCircle = nil;
    }
    if (newLocation.horizontalAccuracy > 0) {
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
    locationMarker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)];
    locationMarker.map = _mapView;
    _mapView.selectedMarker = locationMarker;
}

- (void)animateAndZoomCameraTo:(CLLocation*)targetLocation
{
    // Move then zoom in separate steps since animate route is unpredictable and may go outside MML tile area if done at the same time.
    [_mapView animateToLocation:targetLocation.coordinate];
    [_mapView animateToZoom:15];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    NSLog(@"Location manager failed with error: %@", error);
}

- (void)pageSelected
{
//    [((RiistaNavigationController*)self.navigationController) setRightBarItems:nil];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle:_titlePrimaryText];
}

- (void)goToGpsButtonClick:(id)sender
{
    if (_gpsLocation != nil) {
        [self animateAndZoomCameraTo:_gpsLocation];
    }
}

- (void)setLocationButtonClick:(id)sender
{
    CLLocationCoordinate2D center = _mapView.camera.target;

    [self.delegate locationSetManually:center];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectMapTileType:(id)sender
{
    self.tileTypeAlertView = [UIAlertView new];
    self.tileTypeAlertView.title = RiistaLocalizedString(@"MapTypeSelect", nil);
    self.tileTypeAlertView.delegate = self;
    self.tileTypeAlertView.tag = TILE_TYPE_DIALOG_TAG;

    [self.tileTypeAlertView addButtonWithTitle:RiistaLocalizedString(@"MapTypeTopographic", nil)];
    [self.tileTypeAlertView addButtonWithTitle:RiistaLocalizedString(@"MapTypeBackgound", nil)];
    [self.tileTypeAlertView addButtonWithTitle:RiistaLocalizedString(@"MapTypeAerial", nil)];
    [self.tileTypeAlertView addButtonWithTitle:RiistaLocalizedString(@"CancelRemove", nil)];
    self.tileTypeAlertView.cancelButtonIndex = 3;

    [self.tileTypeAlertView show];
}

# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == TILE_TYPE_DIALOG_TAG) {
        switch (buttonIndex) {
            case 0:
                [self.tileLayer setMapType:MmlTopographicMapType];
                [self.tileLayer clearTileCache];
                [RiistaSettings setMapTypeSetting:MmlTopographicMapType];
                break;
            case 1:
                [self.tileLayer setMapType:MmlBackgroundMapType];
                [self.tileLayer clearTileCache];
                [RiistaSettings setMapTypeSetting:MmlBackgroundMapType];
                break;
            case 2:
                [self.tileLayer setMapType:MmlAerialMapType];
                [self.tileLayer clearTileCache];
                [RiistaSettings setMapTypeSetting:MmlAerialMapType];
                break;
            default:
                break;
        }
    }
}

@end

@implementation MapPageButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
}

@end
