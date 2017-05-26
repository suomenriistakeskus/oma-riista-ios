#import <GoogleMaps/GoogleMaps.h>
#import <RMDateSelectionViewController.h>

#import "DetailsViewController.h"
#import "DetailsViewControllerBase.h"
#import "DiaryImage.h"
#import "GeoCoordinate.h"
#import "ObservationEntry.h"
#import "ObservationValidator.h"
#import "ObservationDetailsViewController.h"
#import "ObservationSpecimensViewController.h"
#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"
#import "RiistaAppDelegate.h"
#import "RiistaDiaryImageManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaLocalization.h"
#import "RiistaMapUtils.h"
#import "RiistaMapViewController.h"
#import "RiistaMetadataManager.h"
#import "RiistaMmlTileLayer.h"
#import "RiistaNavigationController.h"
#import "RiistaSettings.h"
#import "RiistaSpecies.h"
#import "RiistaSpeciesSelectViewController.h"
#import "RiistaUtils.h"
#import "RiistaViewUtils.h"
#import "SrvaEntry.h"
#import "SrvaDetailsViewController.h"
#import "SrvaValidator.h"
#import "Styles.h"
#import "UIColor+ApplicationColor.h"
#import "KeyboardToolbarView.h"

@interface RiistaMarkerInfoWindow : UIView

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *gpsQualityImageView;
@property (weak, nonatomic) IBOutlet UILabel *gpsQualityLabel;

@end

@interface DetailsViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, KeyboardHandlerDelegate, MapPageDelegate, ObservationDetailsDelegate, SrvaDetailsDelegate, RiistaDiaryImageManagerDelegate, UITextViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *dateTimeToolbarButton;
@property (weak, nonatomic) IBOutlet UIButton *editToolbarButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteToolbarButton;

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;

@property (weak, nonatomic) IBOutlet UIView *variableContentContainer;

@property (weak, nonatomic) IBOutlet UIView *backgroundImages;
@property (weak, nonatomic) IBOutlet UILabel *imageLabel;
@property (weak, nonatomic) IBOutlet UIView *imageThumbnailView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageThumbnailHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionTopSeparatorHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomSeparatorHeight;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@property (weak, nonatomic) IBOutlet UIView *buttonArea;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonAreaHeightConstraint;

@property (strong, nonatomic) DetailsViewControllerBase *variableContentViewController;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;
@property (strong, nonatomic) RiistaDiaryImageManager *imageManager;

@property (strong, nonatomic) DiaryEntryBase *entry;

@property (strong, nonatomic) ETRMSPair *selectedCoordinates;
@property (strong, nonatomic) CLLocation *selectedLocation;
@property (strong, nonatomic) NSString *selectedLocationSource;
@property (strong, nonatomic) NSDate *selectedTime;


@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (assign, nonatomic) BOOL editMode;
//@property (assign, nonatomic) BOOL browsingImages;
@property (assign, nonatomic) UIView *activeEditField;

@property (strong, nonatomic) NSManagedObjectContext *moContext;

@end

const NSInteger OBSERVATION_MAX_AMOUNT_VALUE = 999;
const NSInteger OBSERVATION_MAX_AMOUNT_LENGTH = 3;

const NSInteger DIALOG_TAG_DELETE = 10;

@implementation DetailsViewController
{
    CLLocationManager *locationManager;
    BOOL gotGpsLocationFix;
    GMSMarker *locationMarker;
    GMSCircle *accuracyCircle;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.editMode = NO;
        gotGpsLocationFix = NO;
        self.submitButton.enabled = NO;

        RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        self.moContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.moContext.parentContext = delegate.managedObjectContext;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(calendarEntriesUpdated:)
                                                     name:RiistaCalendarEntriesUpdatedKey
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.imageManager = [[RiistaDiaryImageManager alloc] initWithParentController:self
                                                                          andView:self.imageThumbnailView
                                                   andContentViewHeightConstraint:self.contentViewHeightConstraint
                                                     andImageViewHeightConstraint:self.imageThumbnailHeightConstraint
                                                          andManagedObjectContext:self.moContext];


    self.descriptionTextView.delegate = self;
    [RiistaViewUtils setTextViewStyle:self.descriptionTextView];
    self.descriptionTopSeparatorHeight.constant = 1.f/[UIScreen mainScreen].scale;
    self.descriptionBottomSeparatorHeight.constant = 1.f/[UIScreen mainScreen].scale;

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view
                                              andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;
    [self registerForKeyboardNotifications];

    [self setupMapView];

    [Styles styleNegativeButton:self.cancelButton];
    [Styles styleButton:self.submitButton];

    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];

    self.contentViewHeightConstraint.constant = [[UIScreen mainScreen] applicationFrame].size.height - self.navigationController.navigationBar.frame.size.height - self.toolbarView.frame.size.height - self.buttonAreaHeightConstraint.constant;

    if (self.observationId) {
        self.entry = [[RiistaGameDatabase sharedInstance] observationEntryWithObjectId:self.observationId context:self.moContext];
    }
    else if (self.srvaId) {
        self.entry = [[RiistaGameDatabase sharedInstance] srvaEntryWithObjectId:self.srvaId context:self.moContext];
    }

    if (self.entry) {
        if ([self.entry isKindOfClass:[ObservationEntry class]]) {
            [self setupObservationView];
            [self setupWithObservation:(ObservationEntry*)self.entry];
        }
        else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
            [self setupSrvaView];
            [self setupWithSrva:(SrvaEntry*)self.entry];
        }
        [self setEditMode:NO];
    }
    else {
        self.editToolbarButton.hidden = YES;
        self.deleteToolbarButton.hidden = YES;

        if ([self.srvaNew boolValue]) {
            [self setupSrvaView];
            [self setupNewSrva];
        }
        else {
            [self setupObservationView];
            [self setupNewObservation];
        }
        [self setEditMode:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refreshLocalizedTexts];
    [self.variableContentViewController refreshLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateTextViewHeight:self.descriptionTextView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupMapView
{
    self.mapView.delegate = self;
    [self.mapView.settings setAllGesturesEnabled:NO];

    if ([RiistaSettings mapType] == GoogleMapType) {
        self.copyrightLabel.hidden = YES;
    }
    else {
        // MML map tiles
        self.mapView.mapType = kGMSTypeNone;

        RiistaMmlTileLayer *tileLayer = [RiistaMmlTileLayer new];
        [tileLayer setMapType:MmlTopographicMapType];
        tileLayer.map = self.mapView;

        self.copyrightLabel.text = RiistaLocalizedString(@"MapCopyrightMml", nil);
        self.copyrightLabel.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.copyrightLabel.hidden = NO;
    }
}

- (void)setupLocationManager
{
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    // iOS8 location service start fails silently unless authorization is explicitly requested
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }

    gotGpsLocationFix = NO;
    [locationManager startUpdatingLocation];
}

- (void)setupObservationView
{
    ObservationDetailsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ObservationContainer"];
    controller.delegate = self;
    controller.editContext = self.moContext;

    [self.variableContentContainer setNeedsLayout];
    [self.variableContentContainer layoutIfNeeded];

    [self addChildViewController:controller];
    controller.view.frame = self.variableContentContainer.bounds;
    [self.variableContentContainer addSubview:controller.view];
    [controller didMoveToParentViewController:self];

    self.variableContentViewController = controller;

    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
}

- (void)initImageManager:(NSArray*)images
{
    if (self.imageManager) {
        [[self.imageThumbnailView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    [self.imageManager setupWithImages:images];
    self.imageManager.delegate = self;

    [self.backgroundImages.superview sendSubviewToBack:self.backgroundImages];

    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        self.imageManager.entryType = DiaryEntryTypeObservation;
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        self.imageManager.entryType = DiaryEntryTypeSrva;
    }
}

- (void)setupSrvaView
{
    SrvaDetailsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SrvaContainer"];
    controller.delegate = self;
    controller.editContext = self.moContext;

    [self.variableContentContainer setNeedsLayout];
    [self.variableContentContainer layoutIfNeeded];

    [self addChildViewController:controller];
    controller.view.frame = self.variableContentContainer.bounds;
    [self.variableContentContainer addSubview:controller.view];
    [controller didMoveToParentViewController:self];

    self.variableContentViewController = controller;

    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
}

#pragma mark - Public interface

- (void)setObservationId:(NSManagedObjectID*)observationId
{
    _observationId = observationId;
}

- (void)setSrvaId:(NSManagedObjectID*)srvaId
{
    _srvaId = srvaId;
}

#pragma mark - Private

- (void)setupNewObservation
{
    ObservationEntry *entry = (ObservationEntry*)[NSEntityDescription insertNewObjectForEntityForName:@"ObservationEntry" inManagedObjectContext:self.moContext];
    GeoCoordinate *coordinates = (GeoCoordinate*)[NSEntityDescription insertNewObjectForEntityForName:@"GeoCoordinate" inManagedObjectContext:self.moContext];
    entry.coordinates = coordinates;
    entry.canEdit = [NSNumber numberWithBool:YES];
    entry.type = DiaryEntryTypeObservation;
    entry.mobileClientRefId = [RiistaUtils generateMobileClientRefId];
    self.entry = entry;

    [self setupDate:[NSDate date]];

    [entry setSpecimens:[NSOrderedSet new]];

    ObservationDetailsViewController *content = (ObservationDetailsViewController*)self.variableContentViewController;
    if (self.species) {
        content.selectedSpeciesCode = [NSNumber numberWithInteger:self.species.speciesId];
    }
    content.entry = entry;
    CGFloat height = [content refreshViews];

    [self initImageManager:[NSArray new]];

    // Default map position until receiving first location fix
    [self.mapView moveCamera:[GMSCameraUpdate setTarget:CLLocationCoordinate2DMake(62.9f, 25.75f)]];
    [self setupLocationManager];

    [self updateContentSize:height];
}

- (void)updateContentSize:(CGFloat)height
{
    self.contentViewHeightConstraint.constant = MAX(45, height + 45);
}

- (void)setupWithObservation:(ObservationEntry*)entry
{
    [self setupDate:entry.pointOfTime];

    [self setupLocation:entry.coordinates];

    [self initImageManager:[entry.diaryImages array]];

    self.descriptionTextView.text = entry.diarydescription;

    ObservationDetailsViewController *content = (ObservationDetailsViewController*)self.variableContentViewController;
    content.selectedSpeciesCode = entry.gameSpeciesCode;
    content.selectedObservationType = entry.observationType;
    content.selectedWithinMooseHunting = entry.withinMooseHunting;
    content.selectedMooselikeFemaleAmount = entry.mooselikeFemaleAmount;
    content.selectedMooselikeFemale1CalfAmount = entry.mooselikeFemale1CalfAmount;
    content.selectedMooselikeFemale2CalfAmount = entry.mooselikeFemale2CalfsAmount;
    content.selectedMooselikeFemale3CalfAmount = entry.mooselikeFemale3CalfsAmount;
    content.selectedMooselikeFemale4CalfAmount = entry.mooselikeFemale4CalfsAmount;
    content.selectedMooselikeMaleAmount = entry.mooselikeMaleAmount;
    content.selectedMooselikeUnknownAmount = entry.mooselikeUnknownSpecimenAmount;
    content.entry = entry;

    CGFloat height = [content refreshViews];

    [self.cancelButton setTitle:RiistaLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];

    self.editMode = NO;

    [self updateTextViewHeight:self.descriptionTextView];
    [self updateContentSize:height];
}

- (void)setupNewSrva
{
    SrvaEntry *entry = (SrvaEntry*)[NSEntityDescription insertNewObjectForEntityForName:@"SrvaEntry" inManagedObjectContext:self.moContext];
    GeoCoordinate *coordinates = (GeoCoordinate*)[NSEntityDescription insertNewObjectForEntityForName:@"GeoCoordinate" inManagedObjectContext:self.moContext];
    entry.coordinates = coordinates;
    entry.canEdit = [NSNumber numberWithBool:YES];
    entry.type = DiaryEntryTypeSrva;
    entry.mobileClientRefId = [RiistaUtils generateMobileClientRefId];
    entry.pendingOperation = @(DiaryEntryOperationNone);
    entry.totalSpecimenAmount = @(1);
    entry.srvaEventSpecVersion = @(SrvaSpecVersion);

    if (self.species) {
        entry.gameSpeciesCode = [NSNumber numberWithInteger:self.species.speciesId];
        entry.eventName = self.srvaEventName;
        entry.eventType = self.srvaEventType;
    }
    self.entry = entry;

    [self setupDate:[NSDate date]];

    SrvaDetailsViewController *content = (SrvaDetailsViewController*)self.variableContentViewController;
    content.srva = entry;
    CGFloat height = [content refreshViews];

    [self initImageManager:[NSArray new]];

    // Default map position until receiving first location fix
    [self.mapView moveCamera:[GMSCameraUpdate setTarget:CLLocationCoordinate2DMake(62.9f, 25.75f)]];
    [self setupLocationManager];

    [self updateContentSize:height];
}

- (void)setupWithSrva:(SrvaEntry*)srva
{
    [self setupDate:srva.pointOfTime];

    [self setupLocation:srva.coordinates];

    [self initImageManager:[srva.diaryImages array]];

    self.descriptionTextView.text = srva.descriptionText;

    SrvaDetailsViewController *content = (SrvaDetailsViewController*)self.variableContentViewController;
    content.srva = srva;
    CGFloat height = [content refreshViews];

    [self updateTextViewHeight:self.descriptionTextView];
    [self updateContentSize:height];
}

- (void)setupDate:(NSDate*)date
{
    self.selectedTime = date;
    self.dateTimeLabel.text = [self.dateFormatter stringFromDate:self.selectedTime];
}

- (void)setupLocation:(GeoCoordinate*)coordinates
{
    WGS84Pair *pair = [[RiistaMapUtils sharedInstance] ETRMStoWGS84:[coordinates.latitude integerValue] y:[coordinates.longitude integerValue]];
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pair.x, pair.y) altitude:0 horizontalAccuracy:[coordinates.accuracy floatValue] verticalAccuracy:[coordinates.accuracy floatValue] timestamp:[NSDate date]];

    self.selectedLocation = location;
    self.selectedLocationSource = coordinates.source;

    [self updateLocation:location animateCamera:NO];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;

    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        [navController changeTitle:RiistaLocalizedString(@"Observation", nil)];
    }
    else {
        [navController changeTitle:@"SRVA"];
    }
}

- (void)refreshLocalizedTexts
{
    RiistaLanguageRefresh;

    self.imageLabel.text = [RiistaLocalizedString(@"EntryDetailsImage", nil) uppercaseString];
    self.descriptionLabel.text = [RiistaLocalizedString(@"EntryDetailsDescription", nil) uppercaseString];

    [self.cancelButton setTitle:RiistaLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [self.submitButton setTitle:RiistaLocalizedString(@"Save", nil) forState:UIControlStateNormal];

    [self updateTitle];
}

- (void)refreshSaveButtonState
{
    if (!self.editMode) {
        [self.submitButton setEnabled:NO];
        return;
    }

    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        ObservationEntry *entry = (ObservationEntry*)self.entry;
        [self saveEditValuesTo:entry cleanSpecimens:NO];

        BOOL isValid = [ObservationValidator validate:entry metadataManager:[RiistaMetadataManager sharedInstance]];
        [self.submitButton setEnabled:isValid];
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        SrvaEntry *entry = (SrvaEntry*)self.entry;
        [self saveEditValuesToSrva:entry cleanSpecimens:NO];

        BOOL isValid = [SrvaValidator validate:entry];
        [self.submitButton setEnabled:isValid];
    }
}

- (void)updateLocation:(CLLocation*)newLocation animateCamera:(BOOL)animateCamera
{
    if ([self progressViewVisible]) {
        return;
    }

    self.selectedLocation = newLocation;

    if (animateCamera) {
        [_mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:newLocation.coordinate zoom:15]];
    }
    else {
        [_mapView moveCamera:[GMSCameraUpdate setTarget:newLocation.coordinate zoom:15]];
    }

    RiistaMapUtils *mapUtils = [RiistaMapUtils sharedInstance];
    self.selectedCoordinates = [mapUtils WGS84toETRSTM35FIN:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
    self.coordinateLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"CoordinatesFormat", nil), _selectedCoordinates.x, _selectedCoordinates.y];

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
    locationMarker.map = self.mapView;
    self.mapView.selectedMarker = locationMarker;

    [self refreshSaveButtonState];
}

- (void)navigateToDiaryLog
{
    if (locationManager) {
        [locationManager stopUpdatingLocation];
    }

    //Entry should not be touched after this as the managed object context will be released soon
    self.entry = nil;

    if ([self.srvaNew boolValue]) {
        NSNotification *msg = [NSNotification notificationWithName:RiistaLogTypeSelectedKey object:[NSNumber numberWithInt:RiistaEntryTypeSrva]];
        [[NSNotificationCenter defaultCenter] postNotification:msg];
    }
    else if (!self.observationId && !self.srvaId) {
        NSNotification *msg = [NSNotification notificationWithName:RiistaLogTypeSelectedKey object:[NSNumber numberWithInt:RiistaEntryTypeObservation]];
        [[NSNotificationCenter defaultCenter] postNotification:msg];
    }

    NSNotification *savedMsg = [NSNotification notificationWithName:RiistaLogEntrySavedKey object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:savedMsg];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigateToMapPage
{
    RiistaMapViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"mapPageController"];
    controller.delegate = self;
    controller.editMode = self.editMode && [self.entry isEditable];
    controller.location = self.selectedLocation;

    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        controller.titlePrimaryText = RiistaLocalizedString(@"Observation", nil);
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        controller.titlePrimaryText = @"SRVA";
    }

    [self hideKeyboard];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Connections

- (IBAction)dateTimeButtonClick:(id)sender
{
    if (self.editMode) {
        [self showDatePicker];
    }
}

- (IBAction)editButtonClick:(id)sender
{
    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        if (![[RiistaMetadataManager sharedInstance] hasObservationMetadata]) {
            DLog(@"No metadata");
            return;
        }
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        if (![[RiistaMetadataManager sharedInstance] hasSrvaMetadata]) {
            DLog(@"No metadata");
            return;
        }
    }

    [self setEditMode:YES];
    [self refreshSaveButtonState];
}

- (IBAction)deleteButtonClick:(id)sender
{
    if (self.editMode) {
        [self hideKeyboard];

        UIAlertView *confirmDialog = [[UIAlertView alloc] initWithTitle:RiistaLocalizedString(@"DeleteEntryCaption", nil)
                                                                message:RiistaLocalizedString(@"DeleteEntryText", nil)
                                                               delegate:self
                                                      cancelButtonTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                      otherButtonTitles:RiistaLocalizedString(@"OK", nil), nil];
        confirmDialog.tag = DIALOG_TAG_DELETE;
        [confirmDialog show];
    }
}

- (IBAction)cancelButtonClick:(id)sender
{
    if (self.observationId || self.srvaId) {
        [self setEditMode:NO];
        [self.moContext rollback];

        if ([self.entry isKindOfClass:[ObservationEntry class]]) {
            [self setupWithObservation:(ObservationEntry*)self.entry];
        }
        else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
            [self setupWithSrva:(SrvaEntry*)self.entry];
        }
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)saveButtonClick:(id)sender
{
    [self disableUserControls];

    if (self.observationId || self.srvaId) {
        if ([self.entry isKindOfClass:[ObservationEntry class]]) {
            [self saveEditObservation];
        }
        else {
            [self saveEditSrva];
        }
    }
    else {
        if ([self.entry isKindOfClass:[ObservationEntry class]]) {
            [self saveNewObservation];
        }
        else {
            [self saveNewSrva];
        }
    }
}

#pragma mark -

- (void)disableUserControls
{
    [self hideKeyboard];

    self.imageThumbnailView.userInteractionEnabled = NO;
    self.mapView.userInteractionEnabled = NO;
    self.cancelButton.userInteractionEnabled = NO;
    self.submitButton.userInteractionEnabled = NO;

    [self.variableContentViewController disableUserControls];
}

- (void)setEditMode:(BOOL)value
{
    _editMode = value;

    bool fullEdit = value && [self.entry isEditable];

    self.descriptionTextView.userInteractionEnabled = value;
    self.imageThumbnailView.userInteractionEnabled = value || [self.imageManager hasImages];

    self.imageManager.editMode = value;

    self.cancelButton.userInteractionEnabled = value;
    self.submitButton.userInteractionEnabled = value;
    self.buttonAreaHeightConstraint.constant = value ? 70.f : 0.f;

    self.dateTimeToolbarButton.enabled = fullEdit;
    self.deleteToolbarButton.enabled = fullEdit;
    self.editToolbarButton.enabled = !value;

    self.variableContentViewController.editMode = fullEdit;
}

- (void)showDatePicker
{
    [self hideKeyboard];

    RMAction *selectAction = [RMAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                 style:RMActionStyleDone
                                            andHandler:^(RMActionController * controller) {
        NSDate *selecteDate = ((UIDatePicker*)controller.contentView).date;

        self.selectedTime = selecteDate;
        self.dateTimeLabel.text = [self.dateFormatter stringFromDate:self.selectedTime];

        [self updateTitle];
        [self refreshSaveButtonState];
    }];

    RMAction *cancelAction = [RMAction actionWithTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                 style:RMActionStyleCancel
                                            andHandler:^(RMActionController * controller) {
        // Do nothing
    }];

    RMDateSelectionViewController *dateSelectionVC = [RMDateSelectionViewController actionControllerWithStyle:RMActionControllerStyleDefault
                                                                                                 selectAction:selectAction
                                                                                              andCancelAction:cancelAction];

    dateSelectionVC.datePicker.date = self.selectedTime;
    dateSelectionVC.datePicker.maximumDate = [NSDate date];
    dateSelectionVC.datePicker.locale = [RiistaSettings locale];
    dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDateAndTime;

    [self presentViewController:dateSelectionVC animated:YES completion:nil];
}

- (void)deleteConfirmed
{
    if (!self.entry.managedObjectContext) {
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:409 userInfo:nil];
        [self showEditError:error];
        return;
    }

    [self disableUserControls];

    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        ObservationEntry *item = (ObservationEntry*)self.entry;
        item.sent = @(NO);
        item.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationDelete];

        if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
            [self doDeleteObservationNow];
        }
        else {
            [[RiistaGameDatabase sharedInstance] deleteLocalObservation:item];
            [self doDeleteObservationIfLocalOnly];
            [self navigateToDiaryLog];
        }
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        SrvaEntry *item = (SrvaEntry*)self.entry;

        if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
            [self doDeleteSrvaNow];
        }
        else {
            [[RiistaGameDatabase sharedInstance] deleteLocalSrva:item];
            [self doDeleteSrvaIfLocalOnly];
            [self navigateToDiaryLog];
        }
    }
}

- (void)doDeleteSrvaNow
{
    SrvaEntry *editItem = (SrvaEntry*)self.entry;
    [[RiistaGameDatabase sharedInstance] deleteLocalSrva:editItem];

    __weak DetailsViewController *weakSelf = self;

    // Just delete local copy if not sent to server yet
    if ([self doDeleteSrvaIfLocalOnly]) {
        [weakSelf navigateToDiaryLog];
        return;
    }

    [self showProgressView];

    [[RiistaGameDatabase sharedInstance] deleteSrvaEntry:editItem completion:^(NSError *error) {
        if (weakSelf) {
            if (!error) {
                [weakSelf doDeleteLocalEntry:editItem];
                [weakSelf navigateToDiaryLog];
            }
            else {
                [weakSelf showEditError:error];
                if (weakSelf.editMode) {
                    weakSelf.editMode = YES;
                }
            }
        }
    }];
}

- (void)doDeleteObservationNow
{
    ObservationEntry *editItem = (ObservationEntry*)self.entry;
    [[RiistaGameDatabase sharedInstance] deleteLocalObservation:editItem];

    __weak DetailsViewController *weakSelf = self;

    // Just delete local copy if not sent to server yet
    if ([self doDeleteObservationIfLocalOnly]) {
        [weakSelf navigateToDiaryLog];
        return;
    }

    [self showProgressView];

    [[RiistaGameDatabase sharedInstance] deleteObservationEntry:editItem completion:^(NSError *error) {
        if (weakSelf) {
            if (!error) {
                [weakSelf doDeleteLocalEntry:editItem];
                [weakSelf navigateToDiaryLog];
            }
            else {
                [weakSelf showEditError:error];
                if (weakSelf.editMode) {
                    weakSelf.editMode = YES;
                }
            }
        }
    }];
}

- (BOOL)doDeleteObservationIfLocalOnly
{
    ObservationEntry *editItem = (ObservationEntry*)self.entry;
    if ([editItem.remote boolValue] == NO) {
        [self doDeleteLocalEntry:editItem];
        return YES;
    }
    return NO;
}

- (BOOL)doDeleteSrvaIfLocalOnly
{
    SrvaEntry *editItem = (SrvaEntry*)self.entry;
    if (editItem.remoteId == nil) {
        [self doDeleteLocalEntry:editItem];
        return YES;
    }
    return NO;
}

- (void)doDeleteLocalEntry:(DiaryEntryBase*)entry
{
    [entry.managedObjectContext performBlock:^(void) {
        [entry.managedObjectContext deleteObject:entry];
        [entry.managedObjectContext performBlock:^(void) {
            NSError *err;
            if ([entry.managedObjectContext save:&err]) {

                RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                [delegate.managedObjectContext performBlock:^(void) {
                    NSError *Err;
                    [delegate.managedObjectContext save:&Err];
                }];
            }
        }];
    }];
}

//If the progress view is visible we shouldn't modify any context object data because they
//are currently being saved and/or sent to server.
- (BOOL)progressViewVisible
{
    return self.progressView.hidden == NO;
}

- (void)showProgressView
{
    //User can't leave before the operation completes because managed object context goes away otherwise
    [self.navigationItem setHidesBackButton:YES animated:YES];

    self.progressView.hidden = NO;

    UIActivityIndicatorView *spinner = self.progressView.subviews[0];
    [spinner startAnimating];
}

- (void)hideProgressView
{
    [self.navigationItem setHidesBackButton:NO animated:YES];

    self.progressView.hidden = YES;
}

- (void)saveNewObservation
{
    ObservationEntry *item = (ObservationEntry*)self.entry;
    [self saveEditValuesTo:item cleanSpecimens:YES];

    if (![ObservationValidator validate:item metadataManager:[RiistaMetadataManager sharedInstance]]) {
        NSLog(@"Validation failed");
        [self setEditMode:YES];

        return;
    }

    NSArray *images = [self.imageManager diaryImages];
    for (int i=0; i<images.count; i++) {
            ((DiaryImage*)images[i]).status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
            [item addDiaryImagesObject:images[i]];
    }

    [self showProgressView];

    [[RiistaGameDatabase sharedInstance] addLocalObservation:item];
    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        __weak DetailsViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editObservationEntry:item completion:^(NSDictionary *response, NSError *error) {
            [weakSelf navigateToDiaryLog];
        }];
    }
    else {
        [self navigateToDiaryLog];
    }
}

- (void)saveEditObservation
{
    if (!self.entry.managedObjectContext) {
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:409 userInfo:nil];
        [self showEditError:error];
        return;
    }

    ObservationEntry *item = (ObservationEntry*)self.entry;
    [self saveEditValuesTo:item cleanSpecimens:YES];

    if (![ObservationValidator validate:item metadataManager:[RiistaMetadataManager sharedInstance]]) {
        NSLog(@"Validation failed");
        [self setEditMode:YES];

        return;
    }

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {

        ObservationEntry *currentEntry = [[RiistaGameDatabase sharedInstance] observationEntryWithId:[item.remoteId integerValue]];

        // Check for changes locally
        if ([currentEntry.rev integerValue] > [item.rev integerValue]) {
            NSError *error = [NSError errorWithDomain:@"EventEditing" code:409 userInfo:nil];
            [self showEditError:error];
            return;
        }

        [self showProgressView];

        [[RiistaGameDatabase sharedInstance] editLocalObservation:item newImages:[self.imageManager diaryImages]];

        __weak DetailsViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editObservationEntry:item completion:^(NSDictionary *response, NSError *error) {
            if (weakSelf) {
                if (!error) {
                    [item.managedObjectContext performBlock:^(void) {
                        // Save local changes
                        NSError *err;
                        if ([item.managedObjectContext save:&err]) {
                            // Save to persistent store
                            RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                            [delegate.managedObjectContext performBlock:^(void) {
                                NSError *mErr;
                                [delegate.managedObjectContext save:&mErr];
                            }];
                        }

                    }];
                    [weakSelf navigateToDiaryLog];
                } else {
                    [weakSelf showEditError:error];
                    if (weakSelf.editMode)
                        [weakSelf setEditMode:YES];
                }
            }
        }];
    } else {
        [self showProgressView];

        [[RiistaGameDatabase sharedInstance] editLocalObservation:item newImages:[self.imageManager diaryImages]];
        [self navigateToDiaryLog];
    }
}

- (void)saveEditValuesTo:(ObservationEntry*)item cleanSpecimens:(BOOL)cleanSpecimens
{
    item.sent = @(NO);
    item.observationSpecVersion = [NSNumber numberWithInteger:ObservationSpecVersion];
    item.diarydescription = self.descriptionTextView.text;

    item.pointOfTime = self.selectedTime;

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:item.pointOfTime];
    item.year = @([components year]);
    item.month = @([components month]);

    item.coordinates.latitude = [NSNumber numberWithInteger:self.selectedCoordinates.x];
    item.coordinates.longitude = [NSNumber numberWithInteger:self.selectedCoordinates.y];
    item.coordinates.accuracy = [NSNumber numberWithDouble:self.selectedLocation.horizontalAccuracy];
    item.coordinates.source = self.selectedLocationSource;

    ObservationDetailsViewController *vc = (ObservationDetailsViewController*)self.variableContentViewController;
    [vc saveValuesTo:item cleanSpecimens:cleanSpecimens];
}

- (void)saveEditSrva
{
    SrvaEntry *item = (SrvaEntry*)self.entry;

    [self.moContext refreshObject:item mergeChanges:YES];
    if (item.isDeleted) {
        //Entry has been deleted from persistent storage, can't really do anything.
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:0 userInfo:nil];
        [self showEditError:error];
        return;
    }

    [self saveEditValuesToSrva:item cleanSpecimens:YES];

    if (![SrvaValidator validate:item]) {
        NSLog(@"Srva validation failed");
        [self setEditMode:YES];
        return;
    }

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        [self showProgressView];

        [[RiistaGameDatabase sharedInstance] editLocalSrva:item newImages:[self.imageManager diaryImages]];

        __weak DetailsViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editSrvaEntry:item completion:^(NSDictionary *response, NSError *error) {
            if (weakSelf) {
                if (!error) {
                    [weakSelf navigateToDiaryLog];
                }
                else {
                    [weakSelf showEditError:error];
                    if (weakSelf.editMode)
                        [weakSelf setEditMode:YES];
                }
            }
        }];
    }
    else {
        [self showProgressView];

        [[RiistaGameDatabase sharedInstance] editLocalSrva:item newImages:[self.imageManager diaryImages]];
        [self navigateToDiaryLog];
    }
}

- (void)saveNewSrva
{
    SrvaEntry *item = (SrvaEntry*)self.entry;
    [self saveEditValuesToSrva:item cleanSpecimens:YES];

    if (![SrvaValidator validate:item]) {
        NSLog(@"Srva validation failed");
        [self setEditMode:YES];
        return;
    }

    NSArray *images = [self.imageManager diaryImages];
    for (int i=0; i<images.count; i++) {
        ((DiaryImage*)images[i]).status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
        [item addDiaryImagesObject:images[i]];
    }

    [self showProgressView];

    [[RiistaGameDatabase sharedInstance] addLocalSrva:item];
    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        __weak DetailsViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editSrvaEntry:item completion:^(NSDictionary *response, NSError *error) {
            [weakSelf navigateToDiaryLog];
        }];
    }
    else {
        [self navigateToDiaryLog];
    }
}

- (void)saveEditValuesToSrva:(SrvaEntry*)srva cleanSpecimens:(BOOL)cleanSpecimens
{
    srva.sent = @(NO);
    srva.srvaEventSpecVersion = @(SrvaSpecVersion);
    srva.descriptionText = self.descriptionTextView.text;

    srva.pointOfTime = self.selectedTime;

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:srva.pointOfTime];
    srva.year = @([components year]);
    srva.month = @([components month]);

    srva.coordinates.latitude = [NSNumber numberWithInteger:self.selectedCoordinates.x];
    srva.coordinates.longitude = [NSNumber numberWithInteger:self.selectedCoordinates.y];
    srva.coordinates.accuracy = [NSNumber numberWithDouble:self.selectedLocation.horizontalAccuracy];
    srva.coordinates.source = self.selectedLocationSource;

    SrvaDetailsViewController *vc = (SrvaDetailsViewController*)self.variableContentViewController;
    [vc saveValues];
}

- (void)showEditError:(NSError*)error
{
    [self hideProgressView];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:RiistaLocalizedString(@"Error", nil)
                                                    message:RiistaLocalizedString(@"DiaryEditFailed", nil)
                                                   delegate:self
                                          cancelButtonTitle:RiistaLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil, nil];
    if (error.code == 409) {
        alert.message = RiistaLocalizedString(@"OutdatedDiaryEntry", nil);
    }

    [alert show];
}

#pragma mark - Keyboard handling

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height - self.buttonArea.frame.size.height, 0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect rect = self.view.frame;
    rect.size.height -= kbSize.height;

    [self.scrollView scrollRectToVisible:self.activeEditField.frame animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    if (![self.selectedLocationSource isEqual:DiaryEntryLocationManual]) {
        self.selectedLocationSource = DiaryEntryLocationGps;

        if (!gotGpsLocationFix) {
            // Avoid unnecessary tile requests
            gotGpsLocationFix = YES;

            [self updateLocation:[locations lastObject] animateCamera:NO];
        }
        else {
            [self updateLocation:[locations lastObject] animateCamera:YES];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location manager failed with error %@", error);
}

#pragma mark - GMSMapViewDelegate

- (UIView*)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker
{
    if (self.entry || [self.selectedLocationSource isEqual:DiaryEntryLocationManual]) {
        return [UIView new];
    }

    RiistaMarkerInfoWindow *view = [[[NSBundle mainBundle] loadNibNamed:@"RiistaMarkerInfoWindow" owner:self options:nil] firstObject];
    view.containerView.layer.cornerRadius = 4.0f;
    if (self.selectedLocation && self.selectedLocation.horizontalAccuracy <= GOOD_ACCURACY_IN_METERS) {
        view.gpsQualityImageView.image = [UIImage imageNamed:@"ic_small_gps_good"];
        view.gpsQualityLabel.text = RiistaLocalizedString(@"GPSGood", nil);
    }
    else if (self.selectedLocation && self.selectedLocation.horizontalAccuracy <= AVERAGE_ACCURACY_IN_METERS) {
        view.gpsQualityImageView.image = [UIImage imageNamed:@"ic_small_gps_average"];
        view.gpsQualityLabel.text = RiistaLocalizedString(@"GPSAverage", nil);
    }
    else {
        view.gpsQualityImageView.image = [UIImage imageNamed:@"ic_small_gps_bad"];
        view.gpsQualityLabel.text = RiistaLocalizedString(@"GPSBad", nil);
    }

    return view;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self navigateToMapPage];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    [self navigateToMapPage];
}

#pragma mark - KeyboardHandlerDelegate

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - MapPageDelegate

- (void)locationSetManually:(CLLocationCoordinate2D)coordinates
{
    self.selectedLocationSource = DiaryEntryLocationManual;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinates.latitude longitude:coordinates.longitude];

    [self updateLocation:location animateCamera:NO];
}

#pragma mark - ObservationDetailsDelegate

- (void)navigateToSpecimens
{
    ObservationSpecimensViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"observationSpecimensPageController"];
    controller.editMode = self.editMode && [self.entry isEditable];
    controller.editContext = self.moContext;

    ObservationDetailsViewController *contentVc = (ObservationDetailsViewController*)self.variableContentViewController;
    RiistaSpecies *selectedSpecies = [[RiistaGameDatabase sharedInstance] speciesById:[contentVc.selectedSpeciesCode integerValue]];
    controller.species = selectedSpecies;

    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:[contentVc.selectedSpeciesCode integerValue]];
    ObservationContextSensitiveFieldSets *fieldset = [metadata findFieldSetByType:contentVc.selectedObservationType withinMooseHunting:[contentVc.selectedWithinMooseHunting boolValue]];
    controller.metadata = fieldset;

    [controller setContent:(ObservationEntry*)self.entry];
    controller.editContext = self.moContext;

    [self hideKeyboard];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)valuesUpdated:(DetailsViewControllerBase*)sender
{
    [self refreshSaveButtonState];

    CGFloat height = [sender refreshViews];
    [self updateContentSize:height];
}

#pragma mark - RiistaDiaryImageManager

- (void)imageBrowserOpenStatusChanged:(BOOL)open
{
    if (!open) {
        if (self.observationId != nil) {
            self.entry = [[RiistaGameDatabase sharedInstance] observationEntryWithObjectId:self.observationId context:self.moContext];
            [self setupWithObservation:(ObservationEntry*)self.entry];
        }
        else if (self.srvaId != nil) {
            self.entry = [[RiistaGameDatabase sharedInstance] srvaEntryWithObjectId:self.srvaId context:self.moContext];
            [self setupWithSrva:(SrvaEntry*)self.entry];
        }
    }
}

- (void)RiistaDiaryImageManager:(RiistaDiaryImageManager*)manager selectedEntry:(DiaryEntryBase*)entry;
{
    if ([entry isKindOfClass:[ObservationEntry class]]) {
        self.observationId = entry.objectID;
    }
    else if ([entry isKindOfClass:[SrvaEntry class]]) {
        self.srvaId = entry.objectID;
    }
}

#pragma mark - NSNotificationCenter

- (void)calendarEntriesUpdated:(NSNotification*)notification
{
//    NSDictionary *userInfo = notification.userInfo;
//    NSArray *entries = userInfo[@"entries"];
//    for (int i=0; i<entries.count; i++) {
//        RiistaDiaryEntryUpdate *update = entries[i];
//        if ([update.entry.objectID isEqual:self.eventId]) {
//            self.eventInvalid = YES;
//        }
//    }
}

# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DIALOG_TAG_DELETE) {
        if (buttonIndex == 1) { // "Yes/OK"
            [self deleteConfirmed];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeEditField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeEditField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;

    NSUInteger newLength = oldLength - rangeLength + replacementLength;

    return newLength <= OBSERVATION_MAX_AMOUNT_LENGTH || ([string rangeOfString: @"\n"].location != NSNotFound);
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.activeEditField = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.activeEditField = nil;
}

- (void)textViewDidChange:(UITextView*)textView
{
    [self updateTextViewHeight:textView];
}

- (void)updateTextViewHeight:(UITextView*)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    if (newSize.height > self.imageThumbnailHeightConstraint.constant) {
        self.imageThumbnailHeightConstraint.constant += (newSize.height - self.imageThumbnailHeightConstraint.constant);
    }

    [self.backgroundImages.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

#pragma mark - Orientation handling

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
