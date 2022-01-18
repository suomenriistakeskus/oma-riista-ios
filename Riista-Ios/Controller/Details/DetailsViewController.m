#import <GoogleMaps/GoogleMaps.h>
#import "RMDateSelectionViewController.h"

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
#import "RiistaGameDatabase.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaLocalization.h"
#import "RiistaMapUtils.h"
#import "RiistaMapViewController.h"
#import "RiistaMetadataManager.h"
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
#import "NSDateformatter+Locale.h"
#import "Oma_riista-Swift.h"

@interface DetailsViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, RiistaKeyboardHandlerDelegate, MapPageDelegate, ObservationDetailsDelegate, SrvaDetailsDelegate, UITextViewDelegate, UITextFieldDelegate, RiistaImagePickerDelegate>

@property (strong, nonatomic) UIBarButtonItem *deleteBarButton;
@property (strong, nonatomic) UIBarButtonItem *editBarButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;

@property (weak, nonatomic) IBOutlet UIView *variableContentContainer;

@property (weak, nonatomic) IBOutlet MDCMultilineTextField *descriptionTextView;

@property (weak, nonatomic) IBOutlet UIView *buttonArea;
@property (weak, nonatomic) IBOutlet MDCButton *cancelButton;
@property (weak, nonatomic) IBOutlet MDCButton *submitButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentEditBottomConstraint;

@property (strong, nonatomic) DetailsViewControllerBase *variableContentViewController;

@property (strong, nonatomic) MDCTextInputControllerUnderline *descriptionInputController;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;

@property (strong, nonatomic) DiaryEntryBase *entry;

@property (strong, nonatomic) ETRMSPair *selectedCoordinates;
@property (strong, nonatomic) CLLocation *selectedLocation;
@property (strong, nonatomic) NSString *selectedLocationSource;
@property (strong, nonatomic) NSDate *selectedTime;

@property (strong, nonatomic) DiaryImage *addedImage;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (assign, nonatomic) BOOL editMode;
@property (assign, nonatomic) UIView *activeEditField;

@property (strong, nonatomic) NSManagedObjectContext *moContext;

@end

@implementation DetailsViewController
{
    CLLocationManager *locationManager;
    BOOL gotGpsLocationFix;
    GMSMarker *locationMarker;
    GMSCircle *accuracyCircle;

    ImageEditUtil *imageUtil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.editMode = NO;
        gotGpsLocationFix = NO;
        self.submitButton.enabled = NO;

        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.moContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.moContext.parentContext = delegate.managedObjectContext;

        imageUtil = [[ImageEditUtil alloc] initWithParentController:self];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.descriptionInputController = [AppTheme.shared setupDescriptionTextFieldWithTextField:self.descriptionTextView delegate:self];
    [AppTheme.shared setupValueFontWithMultilineTextField:self.descriptionTextView];

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;

    [self registerForKeyboardNotifications];

    [self setupMapView];

    [AppTheme.shared setupEditButtonAreaWithView:self.buttonArea];
    [AppTheme.shared setupEditSaveButtonWithButton:self.submitButton];
    [AppTheme.shared setupEditCancelButtonWithButton:self.cancelButton];

    self.dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
    [self.dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];

    [self setupNavBarButtons];

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
            [self refreshSaveButtonState];
        }
        [self setEditMode:NO];
    }
    else {
        if ([self.srvaNew boolValue]) {
            [self setupSrvaView];
            [self setupNewSrva];
            [self refreshSaveButtonState];
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

    [self updateBarButtons];

    [self refreshLocalizedTexts];
    [self.variableContentViewController refreshLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupNavBarButtons
{
    _editBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_white"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(editButtonClick:)];
    _deleteBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete_white"]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(deleteButtonClick:)];
}

- (void)updateBarButtons
{
    NSMutableArray *barItems = [[NSMutableArray alloc] initWithCapacity:2];

    if (self.entry && [self.entry isEditable]) {
        [barItems addObject:self.deleteBarButton];

        if (!self.editMode) {
            [barItems addObject:self.editBarButton];
        }
    }

    [((RiistaNavigationController*)self.navigationController) setRightBarItems:barItems];
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

    [self addChildViewController:controller];

    self.variableContentContainer.translatesAutoresizingMaskIntoConstraints = false;
    [self.variableContentContainer addSubview:controller.view];

    [self addEqualEdgeConstraintsTo:self.variableContentContainer second:controller.view];

    [controller didMoveToParentViewController:self];

    self.variableContentViewController = controller;

    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
}

- (void)setupSrvaView
{
    SrvaDetailsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SrvaContainer"];
    controller.delegate = self;
    controller.editContext = self.moContext;

    [self addChildViewController:controller];

    self.variableContentContainer.translatesAutoresizingMaskIntoConstraints = false;
    [self.variableContentContainer addSubview:controller.view];

    [self addEqualEdgeConstraintsTo:self.variableContentContainer second:controller.view];

    [controller didMoveToParentViewController:self];

    self.variableContentViewController = controller;

    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
}

- (void)addEqualEdgeConstraintsTo:(UIView*)first second:(UIView*)second
{
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:first
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:second
                                                                     attribute:NSLayoutAttributeTop multiplier:1.0
                                                                      constant:0];

    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:first
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:second
                                                                     attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                      constant:0];

    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:first
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:second
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];

    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:first
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:second
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];

    [first addConstraint:topConstraint];
    [first addConstraint:bottomConstraint];
    [first addConstraint:leftConstraint];
    [first addConstraint:rightConstraint];
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

    content.selectedObservationCategory = [content selectObservationCategoryForSpecies:content.selectedSpeciesCode
                                                           preferredCategoryIfMultiple:ObservationCategoryUnknown];
    content.selectedDeerHuntingType = DeerHuntingTypeNone;
    content.selectedDeerHuntingTypeDescription = nil;
    content.entry = entry;
    [content refreshViews];

    // Default map position until receiving first location fix
    [self.mapView moveCamera:[DefaultMapLocation toGMSCameraUpdate]];
    [self setupLocationManager];
}

- (void)setupWithObservation:(ObservationEntry*)entry
{
    [self setupDate:entry.pointOfTime];

    [self setupLocation:entry.coordinates];

    self.descriptionTextView.text = entry.diarydescription;

    ObservationDetailsViewController *content = (ObservationDetailsViewController*)self.variableContentViewController;
    content.selectedSpeciesCode = entry.gameSpeciesCode;
    content.selectedObservationType = entry.observationType;
    // treat unknown observation categories as normal. This _should_ futureproof the behaviour at least a bit
    content.selectedObservationCategory = [ObservationCategoryHelper parseWithCategoryString:entry.observationCategory fallback:ObservationCategoryNormal];
    content.selectedDeerHuntingType = [DeerHuntingTypeHelper parseWithHuntingTypeString:entry.deerHuntingType fallback:DeerHuntingTypeNone];
    content.selectedDeerHuntingTypeDescription = entry.deerHuntingTypeDescription;
    content.selectedMooselikeFemaleAmount = entry.mooselikeFemaleAmount;
    content.selectedMooselikeFemale1CalfAmount = entry.mooselikeFemale1CalfAmount;
    content.selectedMooselikeFemale2CalfAmount = entry.mooselikeFemale2CalfsAmount;
    content.selectedMooselikeFemale3CalfAmount = entry.mooselikeFemale3CalfsAmount;
    content.selectedMooselikeFemale4CalfAmount = entry.mooselikeFemale4CalfsAmount;
    content.selectedMooselikeMaleAmount = entry.mooselikeMaleAmount;
    content.selectedMooselikeCalfAmount = entry.mooselikeCalfAmount;
    content.selectedMooselikeUnknownAmount = entry.mooselikeUnknownSpecimenAmount;

    content.selectedObserverName = entry.observerName;
    content.selectedObserverPhoneNumber = entry.observerPhoneNumber;
    content.selectedOfficialAdditionalInfo = entry.officialAdditionalInfo;
    content.selectedInYardsDistanceFromResidence = entry.inYardDistanceToResidence;
    content.selectedPack = entry.pack;
    content.selectedLitter = entry.litter;

    content.diaryImage = [entry.diaryImages count] > 0 ? [ImageUtils selectDisplayedImage:entry.diaryImages.array] : nil;

    content.entry = entry;

    [content refreshViews];

    [self.cancelButton setTitle:RiistaLocalizedString(@"Undo", nil) forState:UIControlStateNormal];

    self.editMode = NO;
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
    [content refreshViews];

    // Default map position until receiving first location fix
    [self.mapView moveCamera:[DefaultMapLocation toGMSCameraUpdate]];
    [self setupLocationManager];
}

- (void)setupWithSrva:(SrvaEntry*)srva
{
    [self setupDate:srva.pointOfTime];

    [self setupLocation:srva.coordinates];

    self.descriptionTextView.text = srva.descriptionText;

    SrvaDetailsViewController *content = (SrvaDetailsViewController*)self.variableContentViewController;

    content.diaryImage = [srva.diaryImages count] > 0 ? [ImageUtils selectDisplayedImage:srva.diaryImages.array] : nil;

    content.srva = srva;
    [content refreshViews];
}

- (void)setupDate:(NSDate*)date
{
    self.selectedTime = date;
    [self.variableContentViewController refreshDateTime:[self.dateFormatter stringFromDate:self.selectedTime]];
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

    [self.descriptionInputController setPlaceholderText:RiistaLocalizedString(@"AddDescription", nil)];

    [self.cancelButton setTitle:RiistaLocalizedString(@"Undo", nil) forState:UIControlStateNormal];
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
    controller.hidePins = YES;
    controller.riistaController = (RiistaNavigationController*)self.navigationController;

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

- (IBAction)editButtonClick:(id)sender
{
    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        if (![[RiistaMetadataManager sharedInstance] hasObservationMetadata]) {
            DDLog(@"No metadata");
            return;
        }
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        if (![[RiistaMetadataManager sharedInstance] hasSrvaMetadata]) {
            DDLog(@"No metadata");
            return;
        }
    }

    [self setEditMode:YES];
    [self refreshSaveButtonState];
}

- (IBAction)deleteButtonClick:(id)sender
{
    [self hideKeyboard];

    MDCAlertController *alert = [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"DeleteEntryCaption", nil)
                                                                     message:RiistaLocalizedString(@"DeleteEntryText", nil)];
    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                       handler:^(MDCAlertAction * _Nonnull action) {
        [self deleteConfirmed];
    }];
    MDCAlertAction *cancelAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                           handler:^(MDCAlertAction * _Nonnull action) {
        // Do nothing
    }];

    [alert addAction:cancelAction];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cancelButtonClick:(id)sender
{
    if (self.observationId || self.srvaId) {
        [self setEditMode:NO];

        self.addedImage = nil;

        [self.moContext rollback];

        if ([self.entry isKindOfClass:[ObservationEntry class]]) {
            [self setupWithObservation:(ObservationEntry*)self.entry];
        }
        else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
            [self setupWithSrva:(SrvaEntry*)self.entry];
        }

        [self updateBarButtons];
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

    self.mapView.userInteractionEnabled = NO;
    self.cancelButton.enabled = NO;
    self.submitButton.enabled = NO;

    [self.variableContentViewController disableUserControls];
}

- (void)setEditMode:(BOOL)value
{
    _editMode = value;

    bool fullEdit = value && [self.entry isEditable];

    self.descriptionTextView.userInteractionEnabled = value;

    self.cancelButton.enabled = value;
    self.submitButton.enabled = value;
    [self.buttonArea setHidden:!value];
    self.contentEditBottomConstraint.constant = value ? self.buttonArea.bounds.size.height : 0;

    self.deleteBarButton.enabled = [self.entry isEditable];
    self.editBarButton.isHidden = _editMode;

    self.variableContentViewController.editMode = fullEdit;
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

                RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
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

    [self showProgressView];

    if (self.addedImage) {
        [item addDiaryImages:[NSOrderedSet orderedSetWithObject:self.addedImage]];
    }

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

        NSArray *newImages = self.addedImage ? [NSArray arrayWithObject:self.addedImage] : [item.diaryImages array];
        [[RiistaGameDatabase sharedInstance] editLocalObservation:item newImages:newImages];

        __weak DetailsViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editObservationEntry:item completion:^(NSDictionary *response, NSError *error) {
            if (weakSelf) {
                if (!error) {
                    [item.managedObjectContext performBlock:^(void) {
                        // Save local changes
                        NSError *err;
                        if ([item.managedObjectContext save:&err]) {
                            // Save to persistent store
                            RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
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

        NSArray *newImages = self.addedImage ? [NSArray arrayWithObject:self.addedImage] : [item.diaryImages array];
        [[RiistaGameDatabase sharedInstance] editLocalObservation:item newImages:newImages];
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

        NSArray *newImages = self.addedImage ? [NSArray arrayWithObject:self.addedImage] : [item.diaryImages array];
        [[RiistaGameDatabase sharedInstance] editLocalSrva:item newImages:newImages];

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

        NSArray *newImages = self.addedImage ? [NSArray arrayWithObject:self.addedImage] : [item.diaryImages array];
        [[RiistaGameDatabase sharedInstance] editLocalSrva:item newImages:newImages];
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

    [self showProgressView];

    if (self.addedImage) {
        [item addDiaryImages:[NSOrderedSet orderedSetWithObject:self.addedImage]];
    }

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

    MDCAlertController *alert = [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"Error", nil)
                                                                     message:error.code == 409 ? RiistaLocalizedString(@"OutdatedDiaryEntry", nil) : RiistaLocalizedString(@"DiaryEditFailed", nil)];
    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                       handler:^(MDCAlertAction * _Nonnull action) {
        // Do nothing
    }];

    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
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
    // Use end frame to for size calculations since adding input accessory view happens during animation
    NSValue *kbEndFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize kbSize = [kbEndFrame CGRectValue].size;

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

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self navigateToMapPage];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    [self navigateToMapPage];
}

#pragma mark - RiistaKeyboardHandlerDelegate

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

- (void)showDateTimePicker
{
    [self hideKeyboard];

    RMAction *selectAction = [RMAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                 style:RMActionStyleDone
                                            andHandler:^(RMActionController * controller) {
        NSDate *selecteDate = ((UIDatePicker*)controller.contentView).date;

        self.selectedTime = selecteDate;

        [self.variableContentViewController refreshDateTime:[self.dateFormatter stringFromDate:self.selectedTime]];
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
    dateSelectionVC.datePicker.timeZone = RiistaDateTimeUtils.finnishTimezone;
    dateSelectionVC.datePicker.maximumDate = [NSDate date];
    dateSelectionVC.datePicker.locale = [RiistaSettings locale];
    dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    if (@available(iOS 13.4, *)) {
        dateSelectionVC.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }

    [self presentViewController:dateSelectionVC animated:YES completion:nil];}

- (void)navigateToSpecimens
{
    ObservationSpecimensViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"observationSpecimensPageController"];
    controller.editMode = self.editMode && [self.entry isEditable];
    controller.editContext = self.moContext;

    ObservationDetailsViewController *contentVc = (ObservationDetailsViewController*)self.variableContentViewController;
    RiistaSpecies *selectedSpecies = [[RiistaGameDatabase sharedInstance] speciesById:[contentVc.selectedSpeciesCode integerValue]];
    controller.species = selectedSpecies;

    ObservationSpecimenMetadata *metadata = [[RiistaMetadataManager sharedInstance] getObservationMetadataForSpecies:[contentVc.selectedSpeciesCode integerValue]];
    ObservationContextSensitiveFieldSets *fieldset = [metadata findFieldSetByType:contentVc.selectedObservationType observationCategory:contentVc.selectedObservationCategory];
    controller.specimenMeta = metadata;
    controller.metadata = fieldset;

    [controller setContent:(ObservationEntry*)self.entry];
    controller.editContext = self.moContext;

    [self hideKeyboard];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)valuesUpdated:(DetailsViewControllerBase*)sender
{
    [self refreshSaveButtonState];

    [sender refreshViews];
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

    return newLength <= [AppConstants ObservationMaxAmountLength] || ([string rangeOfString: @"\n"].location != NSNotFound);
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

#pragma mark - RiistaImagePickerDelegate

- (void)imagePickedWithImage:(IdentifiableImage *)image
{
    // reuse addedImage if one exists. addedImage will not be persisted unless data is submitted
    if (self.addedImage == nil) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryImage" inManagedObjectContext:self.moContext];

        self.addedImage = (DiaryImage*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.moContext];

        // setup rest of the image data. These won't be updated before submit is pressed and
        // thus it is safe to setup them just once
        self.addedImage.imageid = [[NSUUID UUID] UUIDString];
        self.addedImage.status = [NSNumber numberWithInteger:DiaryEntryOperationInsert];
        self.addedImage.type = [NSNumber numberWithInteger:DiaryImageTypeLocal];
    }

    [image.imageIdentifier saveIdentifierTo:self.addedImage];

    if ([self.entry isKindOfClass:[ObservationEntry class]]) {
        ObservationDetailsViewController *content = (ObservationDetailsViewController*)self.variableContentViewController;
        content.diaryImage = self.addedImage;

        dispatch_async(dispatch_get_main_queue(), ^{
            [content refreshViews];
        });
    }
    else if ([self.entry isKindOfClass:[SrvaEntry class]]) {
        SrvaDetailsViewController *content = (SrvaDetailsViewController*)self.variableContentViewController;
        content.diaryImage = self.addedImage;

        dispatch_async(dispatch_get_main_queue(), ^{
            [content refreshViews];
        });
    }
}

- (void)imagePickCancelled
{
    NSLog(@"imagePickCancelled");
}

- (void)imagePickFailed:(enum PhotoAccessFailureReason)reason loadRequest:(ImageLoadRequest *)loadRequest
{
    if (self.editMode) {
        // user may have edited photo permissions during photo pick process. Ensure we can still
        // load the current image
        [self.variableContentViewController refreshImage];

        [imageUtil displayImageLoadFailedDialog:self reason:reason imageLoadRequest:loadRequest allowAnotherPhotoSelection:YES];
    }
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
