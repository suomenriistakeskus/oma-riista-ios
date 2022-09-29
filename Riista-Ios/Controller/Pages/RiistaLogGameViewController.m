#import <GoogleMaps/GoogleMaps.h>
#import "RiistaLogGameViewController.h"
#import "RiistaHeaderLabel.h"
#import "Styles.h"
#import "RiistaMapUtils.h"
#import "RiistaSpeciesSelectViewController.h"
#import "RiistaSpecimenListViewController.h"
#import "RiistaGameDatabase.h"
#import "RiistaUtils.h"
#import "RiistaSpeciesCategory.h"
#import "RiistaSpecies.h"
#import "RiistaSpecimen.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaAppDelegate.h"
#import "DiaryEntry.h"
#import "GeoCoordinate.h"
#import "RiistaSettings.h"
#import "UIColor+ApplicationColor.h"
#import "DiaryImage.h"
#import "RiistaDiaryEntryUpdate.h"
#import "RiistaLocalization.h"
#import "RiistaSpecimenView.h"
#import "RMDateSelectionViewController.h"
#import "RiistaPermitListViewController.h"
#import "Permit.h"
#import "PermitSpeciesAmounts.h"
#import "RiistaPermitManager.h"
#import "M13Checkbox.h"
#import "RiistaViewUtils.h"
#import "RiistaValueListButton.h"
#import "RiistaValueListTextField.h"
#import "ValueListViewController.h"
#import "KeyboardToolbarView.h"
#import "NSDateformatter+Locale.h"
#import "Oma_riista-Swift.h"
#import "NSManagedObject+RiistaCopying.h"

@interface RiistaLogGameViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate, SpeciesSelectionDelegate, RiistaKeyboardHandlerDelegate, UITextFieldDelegate, UITextViewDelegate, SpecimensUpdatedDelegate, PermitPageDelegate, ValueSelectionDelegate, RiistaImagePickerDelegate, RiistaImagePickerDelegate, LocationSelectionListener, InstructionsButtonDelegate>

@property (strong, nonatomic) UIBarButtonItem *deleteBarButton;
@property (strong, nonatomic) UIBarButtonItem *editBarButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;
@property (weak, nonatomic) IBOutlet UIView *amountContainer;
@property (weak, nonatomic) IBOutlet UILabel *amountTitle;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet MDCButton *speciesButton;

@property (weak, nonatomic) IBOutlet MDCUnderlinedTextField *amountTextField;

@property (weak, nonatomic) IBOutlet UIView *statusContainer;
@property (weak, nonatomic) IBOutlet UIView *statusIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet RiistaSpecimenView *specimenDetail;
@property (weak, nonatomic) IBOutlet MDCButton *specimenButton;
@property (weak, nonatomic) IBOutlet UIView *specimenButtonContainer;

// A constraint used for hiding the specimen button container. In addition to this
// constraint there should be a second constraint in the UI which dictates the actual
// height for the view (it's priority should be set to UILayoutPriorityDefaultHigh (750).
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideSpecimenButtonContainerConstraint;
@property (weak, nonatomic) IBOutlet MDCButton *imagesButton;
@property (weak, nonatomic) IBOutlet MDCFilledTextArea *descriptionField;
@property (weak, nonatomic) IBOutlet UIView *buttonArea;
@property (weak, nonatomic) IBOutlet MDCButton *cancelButton;
@property (weak, nonatomic) IBOutlet MDCButton *submitButton;

@property (weak, nonatomic) IBOutlet UIView *permitView;
@property (weak, nonatomic) IBOutlet M13Checkbox *permitCheckbox;
@property (weak, nonatomic) IBOutlet UILabel *permitPrompt;
@property (weak, nonatomic) IBOutlet UILabel *permitType;
@property (weak, nonatomic) IBOutlet UILabel *permitNumber;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *permitNumberHeight;
@property (strong, nonatomic) UITapGestureRecognizer *permitTypeTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *permitNumberTapRecognizer;
@property (weak, nonatomic) IBOutlet UILabel *permitRequiredLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *permitRequiredHeightConstraint;

@property (weak, nonatomic) IBOutlet MDCButton *dateButton;
@property (weak, nonatomic) IBOutlet MDCButton *timeButton;

@property (weak, nonatomic) IBOutlet UIView *deerHuntingTypeFields;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deerHuntingTypeFieldsHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *mooseFields;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mooseFieldsHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *speciesExtraFields;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *speciesExtraFieldsHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentEditBottomConstraint;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;

@property (strong, nonatomic) ETRMSPair *selectedCoordinates;
@property (strong, nonatomic) CLLocation *selectedLocation;
@property (strong, nonatomic) NSString *locationSource;
@property (strong, nonatomic) NSDate *startTime;
@property (nonatomic, assign) DeerHuntingType selectedDeerHuntingType;
@property (strong, nonatomic) NSString *selectedDeerHuntingTypeDescription;
@property (strong, nonatomic) NSMutableOrderedSet *specimenData;
@property (strong, nonatomic) NSString *selectedPermitNumber;
@property (strong, nonatomic) NSString *selectedPermitType;

@property (strong, nonatomic) NSString *harvestHuntingType;
// Nullable bool
@property (strong, nonatomic) NSNumber *harvestFeedingPlace;
// Nullable bool
@property (strong, nonatomic) NSNumber *harvestTaigaBeanGoose;

@property (strong, nonatomic) NSMutableArray *categoryList;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDateFormatter *timeFormatter;

@property (strong, nonatomic) MDCDialogTransitionController *dialogTransitionController;

@property (assign, nonatomic) BOOL editMode;
@property (assign, nonatomic) UIView *activeEditField;

@property (strong, nonatomic) DiaryEntry *event;

// AppDelegate context when creating entry. Child context when editing
@property (strong, nonatomic) NSManagedObjectContext *editContext;
@property (assign, nonatomic) BOOL eventInvalid;

@end

static const CGFloat CONTENT_BOTTOM_MARGIN = 16;
static const CGFloat LEFT_MARGIN = 12.0;
static const CGFloat RIGHT_MARGIN = 12.0;

// reduce the extra height until UI elements properly support multiline text
static const NSInteger MOOSE_INFO_EXTRA_HEIGHT = 0;

static const NSInteger DEER_HUNTING_TYPE = 60;
static const NSInteger DEER_HUNTING_TYPE_DESCRIPTION = 61;

static const NSInteger MOOSE_WEIGHT_ESTIMATED_TAG = 101;
static const NSInteger MOOSE_WEIGHT_MEASURED_TAG = 102;
static const NSInteger MOOSE_FITNESS_TAG = 103;
static const NSInteger MOOSE_ANTLERS_TYPE_TAG = 104;
static const NSInteger MOOSE_ANTLERS_WIDTH_TAG = 105;
static const NSInteger MOOSE_ANTLERS_POINTS_LEFT_TAG = 106;
static const NSInteger MOOSE_ANTLERS_POINTS_RIGHT_TAG = 107;
static const NSInteger MOOSE_ADDITIONAL_INFO_TAG = 108;

static const NSInteger MOOSE_ANTLERS_GIRTH_TAG = 110;
static const NSInteger MOOSE_ANTLERS_LENGTH_TAG = 111;
static const NSInteger MOOSE_ANTLERS_INNER_WIDTH_TAG = 112;
static const NSInteger MOOSE_ANTLERS_SHAFT_WIDTH_TAG = 113;

static const NSInteger HARVEST_FEEDING_PLACE_TAG = 120;
static const NSInteger HARVEST_TAIGA_BEAN_GOOSE_TAG = 121;
static const NSInteger HARVEST_HUNTING_TYPE_TAG = 122;


static NSString * const DEER_HUNTING_TYPE_KEY = @"DeerHuntingTypeKey";
static NSString * const MOOSE_FITNESS_KEY = @"MooseFitnessKey";
static NSString * const MOOSE_ANTLERS_TYPE_KEY = @"MooseAntlersTypeKey";
static NSString * const HARVEST_HUNTING_TYPE_KEY = @"HarvestHuntingTypeKey";

static NSString * const CLEAR_SELECTION_TEXT = @"-";

NSString* RiistaEditDomain = @"RiistaEdit";

@implementation RiistaLogGameViewController
{
    CLLocationManager *locationManager;
    BOOL gotGpsLocationFix;
    GMSMarker *locationMarker;
    GMSCircle *accuracyCircle;

    DiaryImage *addedImage;
    ImageEditUtil *imageUtil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _editMode = NO;
        gotGpsLocationFix = NO;
        _submitButton.enabled = NO;
        _categoryList = [NSMutableArray new];
        _specimenData = [NSMutableOrderedSet new];
        NSDictionary *categories = [RiistaGameDatabase sharedInstance].categories;
        NSArray *categoryKeys = [categories allKeys];
        NSSortDescriptor *categorySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        NSArray *sortedCategoryKeys = [categoryKeys sortedArrayUsingDescriptors:@[categorySortDescriptor]];
        for (int i=0; i<categories.count; i++) {
            [_categoryList addObject:categories[sortedCategoryKeys[i]]];
        }
        RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
        _editContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _editContext.parentContext = delegate.managedObjectContext;
        _eventInvalid = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amountTextFieldDidBeginEditing:)
                                                     name:UITextFieldTextDidBeginEditingNotification object:_amountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amountTextFieldDidEndEditing:)
                                                     name:UITextFieldTextDidEndEditingNotification object:_amountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarEntriesUpdated:)
                                                     name:RiistaCalendarEntriesUpdatedKey object:nil];

        imageUtil = [[ImageEditUtil alloc] initWithParentController:self];
    }
    return self;
}

- (void)setEventId:(NSManagedObjectID*)eventId
{
    _eventId = eventId;
    self.event = [[RiistaGameDatabase sharedInstance] diaryEntryWithObjectId:eventId context:self.editContext];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    RiistaAppDelegate *delegate = (RiistaAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    if (self.event) {
        context = self.editContext;
    }
    else {
        self.editContext = context;
    }

    [AppTheme.shared setupDescriptionTextArea:self.descriptionField delegate:self];

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;
    [self registerForKeyboardNotifications];

    _mapView.delegate = self;
    [_mapView.settings setAllGesturesEnabled:NO];

    if ([RiistaSettings mapType] == GoogleMapType) {
        self.copyrightLabel.hidden = YES;
    }
    else {
        // MML map tiles
        _mapView.mapType = kGMSTypeNone;

        RiistaMmlTileLayer *tileLayer = [RiistaMmlTileLayer new];
        [tileLayer setMapType:MmlTopographicMapType];
        tileLayer.map = _mapView;

        self.copyrightLabel.text = RiistaLocalizedString(@"MapCopyrightMml", nil);
        self.copyrightLabel.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.copyrightLabel.hidden = NO;
    }

    [AppTheme.shared setupSpeciesButtonThemeWithButton:self.speciesButton];
    [AppTheme.shared setupImagesButtonThemeWithButton:self.imagesButton];

    [AppTheme.shared setupPrimaryButtonThemeWithButton:self.specimenButton];
    self.specimenButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [self setupPermitInfo];
    [self setupGestureRecognizers];

    [self setupAmountInput:self.amountTextField];

    [self setupDateTimeButtons];

    [AppTheme.shared setupEditButtonAreaWithView:self.buttonArea];
    [AppTheme.shared setupEditSaveButtonWithButton:self.submitButton];
    [AppTheme.shared setupEditCancelButtonWithButton:self.cancelButton];

    _startTime = [NSDate date];

    self.dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
    [self.dateFormatter setDateFormat:@"dd.MM.yyyy"];

    self.timeFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
    [self.timeFormatter setDateFormat:@"HH:mm"];

    __weak RiistaLogGameViewController *weakSelf = self;
    self.specimenDetail.genderAndAgeListener = ^{
        if (weakSelf) {
            [weakSelf specimenGenderOrAgeChanged:nil];
        }
    };

    if (self.event) {
        [self initForEdit:self.event];
    } else {
        [self initForNewEvent];
    }
}

- (void)setupDateTimeButtons
{
    [AppTheme.shared setupTextButtonThemeWithButton:_dateButton];
    [AppTheme.shared setupTextButtonThemeWithButton:_timeButton];

    [self.dateButton addTarget:self action:@selector(dateTimeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.timeButton addTarget:self action:@selector(dateTimeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initializeDeerHuntingTypeFields
{
    self.selectedDeerHuntingType = DeerHuntingTypeNone;
    self.selectedDeerHuntingTypeDescription = nil;

    [self setupDeerHuntingTypeFields];
}

- (void)initializeDeerHuntingTypeFieldsWithEntry:(DiaryEntry*)entry
{
    self.selectedDeerHuntingType = [DeerHuntingTypeHelper parseWithHuntingTypeString:entry.deerHuntingType
                                                                            fallback:DeerHuntingTypeNone];
    self.selectedDeerHuntingTypeDescription = entry.deerHuntingTypeDescription;

    [self setupDeerHuntingTypeFields];
}

- (void)setupDeerHuntingTypeFields
{
    // nothing to do if no species selected
    if (self.species == nil) {
        return;
    }

    Required deerHuntingRequired = [[self getReport] getDeerHuntingType];

    // we'll be updating fields no matter what -> remove previous entries
    [self.deerHuntingTypeFields removeAllSubviews];

    const int VIEW_HEIGHT = RiistaDefaultValueElementHeight;

    if (deerHuntingRequired == RequiredYES || deerHuntingRequired == RequiredVOLUNTARY) {
        NSString *deerHuntingTypeString = @"";
        if (self.selectedDeerHuntingType != DeerHuntingTypeNone) {
            deerHuntingTypeString = RiistaMappedValueString([DeerHuntingTypeHelper stringForDeerHuntingType:self.selectedDeerHuntingType], nil);
        }
        RiistaValueListButton *deerHuntingTypeView = [self createValueListButton:RiistaLocalizedString(@"DeerHuntingType", nil)
                                                                           value:deerHuntingTypeString
                                                                               y:0
                                                                           width:self.deerHuntingTypeFields.frame.size.width];
        deerHuntingTypeView.tag = DEER_HUNTING_TYPE;
        [deerHuntingTypeView addTarget:self
                                action:@selector(onDeerHuntingTypeClicked)
                      forControlEvents:UIControlEventTouchUpInside];
        [self.deerHuntingTypeFields addSubview:deerHuntingTypeView];

        if (self.selectedDeerHuntingType == DeerHuntingTypeOther) {
            RiistaValueListTextField *descriptionView = [self createValueListTextField:RiistaLocalizedString(@"DeerHuntingTypeDescription", nil)
                                                                                 value:self.selectedDeerHuntingTypeDescription
                                                                                     y:VIEW_HEIGHT
                                                                                  grow:0
                                                                                 width:self.deerHuntingTypeFields.frame.size.width];
            descriptionView.textField.tag = DEER_HUNTING_TYPE_DESCRIPTION;
            descriptionView.textField.keyboardType = UIKeyboardTypeDefault;
            descriptionView.maxTextLength = [NSNumber numberWithInt:255];
            descriptionView.delegate = self;
            [self.deerHuntingTypeFields addSubview:descriptionView];
        }
    }

    [self.deerHuntingTypeFields setUserInteractionEnabled:(self.editMode && (self.event == nil || [self.event isEditable]))];
    [self updateDeerHuntingTypeFieldsVisibility:VIEW_HEIGHT];
}

- (void)updateDeerHuntingTypeFieldsVisibility:(int)singleFieldHeight
{
    NSUInteger subviewCount = [[self.deerHuntingTypeFields subviews] count];
    if (subviewCount == 0) {
        [self.deerHuntingTypeFields setHidden:YES];
        [self.deerHuntingTypeFieldsHeightConstraint setConstant:0.f];
    }
    else {
        CGFloat totalHeight = subviewCount * singleFieldHeight;
        [self.deerHuntingTypeFields setHidden:NO];
        [self.deerHuntingTypeFieldsHeightConstraint setConstant:totalHeight];
    }
}

- (void)onDeerHuntingTypeClicked
{
    UIStoryboard* valueListControllerStoryboard = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    ValueListViewController *controller = [valueListControllerStoryboard instantiateViewControllerWithIdentifier:@"valueListController"];
    controller.delegate = self;
    controller.fieldKey = [NSString stringWithString:DEER_HUNTING_TYPE_KEY];
    controller.titlePrompt = RiistaLocalizedString(@"DeerHuntingType", nil);

    NSMutableArray *valueList = [[NSMutableArray alloc] init];
    [valueList addObject:[DeerHuntingTypeHelper stringForDeerHuntingType:DeerHuntingTypeStandHunting]];
    [valueList addObject:[DeerHuntingTypeHelper stringForDeerHuntingType:DeerHuntingTypeDogHunting]];
    [valueList addObject:[DeerHuntingTypeHelper stringForDeerHuntingType:DeerHuntingTypeOther]];
    [valueList addObject:CLEAR_SELECTION_TEXT];

    controller.values = valueList;

    [self.navigationController pushViewController:controller animated:YES];
}

- (void)setupAmountInput:(MDCUnderlinedTextField*)input
{
    [AppTheme.shared setupAmountTextFieldWithTextField:input delegate:self];

    self.amountTextField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:self.amountTextField];
    [input addTarget:self action:@selector(amountTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    _amountTitle.text = RiistaLocalizedString(@"Amount", nil);
    _amountLabel.text = RiistaLocalizedString(@"EntryDetailsAmountShort", nil);
    _permitRequiredLabel.text = RiistaLocalizedString(@"PermitNumberRequired", nil);

    [_specimenButton setTitle:RiistaLocalizedString(@"SpecimenDetailsTitle", nil) forState:UIControlStateNormal];

    [self.descriptionField setPlaceholder:RiistaLocalizedString(@"AddDescription", nil)];

    [self updateTitle];
    [_submitButton setTitle:RiistaLocalizedString(@"Save", nil) forState:UIControlStateNormal];

    [self setupNavBarButtons];

    [self updateBarButtonStates];

    [self saveSpecimenExtraFieldsTo:self.event];
    [self setupAmountInfo];
    [self setupSpecimenInfo];
    [self updatePermitInfo];
    [self listenLocationIfNeeded];
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

    [self saveSpecimenExtraFieldsTo:self.event];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initForNewEvent
{
    if (!self.species) {
        [_speciesButton setTitle:RiistaLocalizedString(@"ChooseSpecies", nil) forState:UIControlStateNormal];
        [self updateSpeciesButton];
    } else {
        [self setSelectedSpecies:self.species];
    }

    self.statusContainer.hidden = YES;

    [_cancelButton setTitle:RiistaLocalizedString(@"Dismiss", nil) forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(dismissButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton addTarget:self action:@selector(submitButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_specimenButton addTarget:self action:@selector(specimenButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    self.editMode = YES;

    [self initializeDeerHuntingTypeFields];
    self.amountTextField.text = @"1";
    self.amountTextField.userInteractionEnabled = NO;
    [self.imagesButton setEnabled:YES];

    [self updateSubmitButton];

    // Default map position until receiving first location fix
    [self.mapView moveCamera:[DefaultMapLocation toGMSCameraUpdate]];
    [self setupLocationListeningForNewEvent];
}

- (void)initForEdit:(DiaryEntry*)event
{
    if (!self.event.managedObjectContext) {
        // If the event doesn't exist any more, go back to previous screen
        [self.navigationController popViewControllerAnimated:YES];
    }

    self.specimenData = [NSMutableOrderedSet orderedSetWithOrderedSet:event.specimens];
    self.selectedPermitNumber = event.permitNumber != nil ? [NSString stringWithString:event.permitNumber] : nil;
    [self updateSelectedPermitType];

    self.startTime = event.pointOfTime;
    self.harvestHuntingType = event.huntingMethod;
    self.harvestFeedingPlace = event.feedingPlace;
    self.harvestTaigaBeanGoose = event.taigaBeanGoose;

    [self initializeDeerHuntingTypeFieldsWithEntry:event];

    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.event.gameSpeciesCode integerValue]];
    [self setSelectedSpecies:species];

    [_cancelButton setTitle:RiistaLocalizedString(@"Undo", nil) forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(editCancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton addTarget:self action:@selector(saveChangesButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_specimenButton addTarget:self action:@selector(specimenButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self refreshImage];

    [self setupAmountInfo];

    if (self.event.stateAcceptedToHarvestPermit != nil || self.event.harvestReportState != nil || [self.event.harvestReportRequired boolValue]) {
        [self setupHarvestState:self.event.stateAcceptedToHarvestPermit harvest:self.event.harvestReportState];
    } else {
        self.statusContainer.hidden = YES;
    }

    self.amountTextField.text = [self.event.amount stringValue];
    self.amountTextField.userInteractionEnabled = NO;

    [self.imagesButton setEnabled:YES];

    self.descriptionField.textView.text = self.event.diarydescription;
    self.descriptionField.enabled = NO;

    self.contentEditBottomConstraint.constant = self.buttonArea.bounds.size.height + CONTENT_BOTTOM_MARGIN;
    self.buttonArea.userInteractionEnabled = NO;
    [self.buttonArea setHidden:YES];

    GeoCoordinate *coordinates = self.event.coordinates;
    WGS84Pair *pair = [[RiistaMapUtils sharedInstance] ETRMStoWGS84:[coordinates.latitude integerValue] y:[coordinates.longitude integerValue]];
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pair.x, pair.y) altitude:0 horizontalAccuracy:[coordinates.accuracy floatValue] verticalAccuracy:[coordinates.accuracy floatValue] timestamp:[NSDate date]];
    self.locationSource = coordinates.source;
    [self updateLocation:location animateCamera:NO];

    [self.speciesButton setEnabled:NO animated:YES];

    if (self.permitTypeTapRecognizer) {
        [self.permitTypeTapRecognizer setEnabled:NO];
    }
    if (self.permitNumberTapRecognizer) {
        [self.permitNumberTapRecognizer setEnabled:NO];
    }

    self.permitCheckbox.enabled = NO;

    [self updatePermitInfo];
    [self refreshPermitViewVisibility];
}

- (void)disableUserControls
{
    [self hideKeyboard];

    [self.speciesButton setEnabled:NO animated:YES];

    if (self.permitTypeTapRecognizer) {
        [self.permitTypeTapRecognizer setEnabled:NO];
    }
    if (self.permitNumberTapRecognizer) {
        [self.permitNumberTapRecognizer setEnabled:NO];
    }

    self.permitCheckbox.enabled = NO;
    [self.imagesButton setEnabled:NO animated:YES];
    self.specimenDetail.userInteractionEnabled = NO;
    self.specimenButton.enabled = NO;
    self.mapView.userInteractionEnabled = NO;
    self.cancelButton.enabled = NO;
    self.submitButton.enabled = NO;
}

- (void)refreshImage
{
    DiaryImage *displayImage = nil;
    if (addedImage != nil) {
        displayImage = addedImage;
    } else {
        displayImage = [self selectDisplayedImage];
    }

    if (displayImage != nil) {
        [ImageUtils loadDiaryImage:displayImage
                           options:[ImageLoadOptions aspectFilledWithSize:CGSizeMake(50.0f, 50.0f)]
                         onSuccess:^(UIImage * _Nonnull image) {
            [self.imagesButton setImageLoadedSuccessfully];

            [self.imagesButton setBackgroundImage:image forState:UIControlStateNormal];
            [self.imagesButton setImage:nil forState:UIControlStateNormal];
            [self.imagesButton setBorderWidth:0 forState:UIControlStateNormal];
        }
                          onFailure:^(PhotoAccessFailureReason reason) {
            // currently selected image cnnot be loaded. Indicate this to the user
            UIImage *displayedIcon = nil;
            if (!self.editMode) {
                displayedIcon = [[UIImage imageNamed:@"missing-image-error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            } else {
                displayedIcon = [[UIImage imageNamed:@"camera"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            [self.imagesButton setImage:displayedIcon forState:UIControlStateNormal];
            [self.imagesButton setImageTintColor:[UIColor whiteColor] forState:UIControlStateNormal];

            [self.imagesButton setBackgroundImage:nil forState:UIControlStateNormal];
            [self.imagesButton setImageLoadFailedWithReason:reason];
        }];
    }
}

- (DiaryImage*)selectDisplayedImage
{
    if (self.event.diaryImages != nil && [self.event.diaryImages count] > 0) {
        return [ImageUtils selectDisplayedImage:self.event.diaryImages.allObjects];
    }

    return nil;
}

- (void)setupAmountInfo
{
    if (!self.species || !self.species.multipleSpecimenAllowedOnHarvests) {
        [self.amountContainer setHidden:YES];
        self.amountTextField.text = @"1";
        [self.amountTextField setUserInteractionEnabled:NO];
    }
    else {
        [self.amountContainer setHidden:NO];
        [self.amountTextField setUserInteractionEnabled:self.editMode && (self.event == nil || [self.event isEditable])];
    }
}

- (void)setupHarvestState:(NSString*)permitState harvest:(NSString*)harvestState
{
    self.statusIndicatorView.hidden = NO;
    self.statusIndicatorView.layer.cornerRadius = self.statusIndicatorView.frame.size.width/2;

    if ([harvestState isEqual:DiaryEntryHarvestStateProposed]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusProposed];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestStateProposed", nil);
    } else if ([harvestState isEqual:DiaryEntryHarvestStateSentForApproval]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusSentForApproval];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestStateSentForApproval", nil);
    } else if ([harvestState isEqual:DiaryEntryHarvestStateApproved]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusApproved];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestStateApproved", nil);
    } else if ([harvestState isEqual:DiaryEntryHarvestStateRejected]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusRejected];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestStateRejected", nil);
    } else if ([DiaryEntryHarvestPermitProposed isEqual:permitState]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusProposed];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestPermitStateProposed", nil);
    } else if ([DiaryEntryHarvestPermitAccepted isEqual:permitState]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusAccepted];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestPermitStateAccepted", nil);
    } else if ([DiaryEntryHarvestPermitRejected isEqual:permitState]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusRejected];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestPermitStateRejected", nil);
    } else {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestStatusCreateReport];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestStateCreateReport", nil);
    }
}

- (void)setupSpecimenInfo
{
    NSInteger amount = [self.amountTextField.text integerValue];

    [self fixSpecimenDataToAmount:_specimenData toAmount:amount];

    [self.specimenDetail updateLocalizedTexts];
    [self.specimenDetail updateValueSelections];
    [self.specimenDetail setUserInteractionEnabled:self.editMode && (self.event == nil || [self.event isEditable])];
    if ([self.specimenData count] > 0) {
        [self.specimenDetail setSpecimen:self.specimenData[0]];
    }

    if (self.species != nil && !self.species.multipleSpecimenAllowedOnHarvests) {
        [self.specimenDetail setHidden:NO];
        [self setSpecimenButtonHidden:YES];
    }
    else if (self.species != nil
             && [self.amountTextField.text integerValue] > 0
             && [self.amountTextField.text integerValue] <= DiaryEntrySpecimenDetailsMax) {
        [self.specimenDetail setHidden:YES];
        [self setSpecimenButtonHidden:NO];
    }
    else {
        [self.specimenDetail setHidden:YES];
        [self setSpecimenButtonHidden:YES];
    }

    [self setupMooseInfo];
    [self setupSpeciesExtraFields];
}

- (void)setSpecimenButtonHidden:(BOOL)hidden
{
    [self.hideSpecimenButtonContainerConstraint setConstrainedViewHiddenWithHidden:hidden];
    [self.specimenButtonContainer setHidden:hidden];
    [self.specimenButton setHidden:hidden];
    [self.specimenButton setEnabled:!hidden animated:NO];
}

- (void)specimenGenderOrAgeChanged:(UISegmentedControl*)sender
{
    if (self.species) {
        [self setupMooseInfo];

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }

    [self updateSubmitButton];
}

- (void)setupSpeciesExtraFields
{
    NSArray *views = [self.speciesExtraFields subviews];
    for (UIView *v in views) {
        [v removeFromSuperview];
    }

    Report *report = [self getReport];

    if (report.getFeedingPlace == RequiredYES || report.getFeedingPlace == RequiredVOLUNTARY) {
        UIView *view = [self createFeedingPlaceChoice:self.harvestFeedingPlace.boolValue y:0];
        [self.speciesExtraFields addSubview:view];
    }

    if (report.getHuntingMethod == RequiredYES || report.getHuntingMethod == RequiredVOLUNTARY) {
        UIView *view = [self createHuntingMethodItem:self.harvestHuntingType y:0];
        [self.speciesExtraFields addSubview:view];
    }

    if (report.getTaigaBeanGoose == RequiredYES || report.getTaigaBeanGoose == RequiredVOLUNTARY) {
        UIView *view = [self createTaigaBeanGooseChoice:self.harvestTaigaBeanGoose.boolValue y:0];
        [self.speciesExtraFields addSubview:view];
    }

    if ([[self.speciesExtraFields subviews] count] == 0) {
        [self.speciesExtraFields setHidden:YES];
        [self.speciesExtraFieldsHeightConstraint setConstant:0.f];
    }
    else {
        CGFloat height = ([[self.speciesExtraFields subviews] count] * RiistaDefaultValueElementHeight);
        [self.speciesExtraFields setHidden:NO];
        [self.speciesExtraFieldsHeightConstraint setConstant:height];
    }

    [self.speciesExtraFields setUserInteractionEnabled:(self.editMode && (self.event == nil || [self.event isEditable]))];
    [self updatePermitRequiredLabelState:report];
}

- (Report*)getReport
{
    NSInteger huntingYear = [RiistaUtils startYearFromDate:self.startTime];
    bool insideSeason = [HarvestSeasonUtil isInsideHuntingSeasonWithDay:self.startTime
                                                        gameSpeciesCode:self.species.speciesId];

    HarvestReportingType reportingType = HarvestReportingTypeBASIC;

    if (self.selectedPermitNumber != nil) {
        reportingType = HarvestReportingTypePERMIT;
    } else if (insideSeason) {
        reportingType = HarvestReportingTypeSEASON;
    }

    BOOL deerHuntingTypeEnabled = [FeatureAvailabilityChecker.shared isEnabled:FeatureDisplayDeerHuntingType];

    Report *report = [RequiredHarvestFields getFormFieldsWithHuntingYear:huntingYear
                                                         gameSpeciesCode:self.species.speciesId
                                                           reportingType:reportingType
                                                  deerHuntingTypeEnabled:deerHuntingTypeEnabled];

    return report;
}

- (void)updatePermitRequiredLabelState:(Report*)report
{
    BOOL permitSet = [self.selectedPermitNumber length] > 0;
    BOOL permitRequired = report.getPermitNumber == RequiredYES;

    [self.permitRequiredLabel setHidden:(!permitRequired || permitSet || !self.editMode)];
    [self.permitRequiredHeightConstraint setConstant:(!permitRequired || permitSet || !self.editMode ? 0 : 24)];
}

- (void)setupMooseInfo
{
    [self.mooseFields removeAllSubviews];

    RiistaSpecimen *specimen = nil;
    if (self.specimenData.count > 0) {
        specimen = self.specimenData[0];
    }

    RiistaSpecies* species = self.species;
    if (!species || !specimen) {
        [self.specimenDetail hideWeightInput:NO];

        [self.mooseFields setHidden:YES];
        [self.mooseFieldsHeightConstraint setConstant:0.f];

        [self.mooseFields setUserInteractionEnabled:(self.editMode && (self.event == nil || [self.event isEditable]))];
        return;
    }

    // moose or mooselike
    HarvestContext *harvestContext = [HarvestContext createWithSpeciesId:species.speciesId
                                                      harvestPointOfTime:self.startTime
                                                                specimen:specimen];
    HarvestSpecimenFields *fields = [HarvestSpecimenFieldsProvider getFieldsForHarvestContext:harvestContext];

    // display the fields according to visibility settings. Clear the corresponding specimen
    // value if field is not visible --> this ensures we're not going to send invalid data to the backend

    if ([fields contains:HarvestSpecimenFieldTypeWeight]) {
        [self.specimenDetail hideWeightInput:NO];
    } else {
        [self.specimenDetail hideWeightInput:YES];
        specimen.weight = nil;
    }

    // dynamic mooselike fields
    CGFloat accumulatedHeight = 8; // little bit of top margin here
    if ([fields contains:HarvestSpecimenFieldTypeLoneCalf]) {
        [self.mooseFields addSubview:[self createMooseLoneCalfChoice:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaCheckboxElementHeight;
    } else {
        specimen.alone = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeNotEdible]) {
        [self.mooseFields addSubview:[self createMooseNotEdibleChoice:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaCheckboxElementHeight;
    } else {
        specimen.notEdible = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeWeightEstimated]) {
        [self.mooseFields addSubview:[self createMooseWeightEstimatedItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.weightEstimated = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeWeightMeasured]) {
        [self.mooseFields addSubview:[self createMooseWeightMeasuredItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.weightMeasured = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeFitnessClass]) {
        [self.mooseFields addSubview:[self createMooseFitnessClassItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.fitnessClass = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersLost]) {
        [self.mooseFields addSubview:[self createMooseAntlersLostChoice:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaCheckboxElementHeight;
    } else {
        specimen.antlersLost = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersInstructions] && self.editMode) {
        UIView *instructionsView = [self createAntlersInstructions:species.speciesId y:accumulatedHeight];
        if (instructionsView != nil) {
            [self.mooseFields addSubview:instructionsView];
            accumulatedHeight += RiistaInstructionsViewHeight;
        }
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersType]) {
        [self.mooseFields addSubview:[self createMooseAntlersTypeItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlersType = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersWidth]) {
        [self.mooseFields addSubview:[self createMooseAntlersWidthItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlersWidth = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlerPointsLeft]) {
        [self.mooseFields addSubview:[self createMooseAntlersPointsLeft:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlerPointsLeft = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlerPointsRight]) {
        [self.mooseFields addSubview:[self createMooseAntlersPointsRight:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlerPointsRight = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersGirth]) {
        [self.mooseFields addSubview:[self createMooseAntlersGirthItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlersGirth = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersLength]) {
        [self.mooseFields addSubview:[self createMooseAntlersLengthItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlersLength = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersInnerWidth]) {
        [self.mooseFields addSubview:[self createMooseAntlersInnerWidthItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.antlersInnerWidth = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAntlersShaftWidth]) {
        [self.mooseFields addSubview:[self createMooseAntlersShaftWidthItem:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
       specimen.antlersShaftWidth = nil;
    }

    if ([fields contains:HarvestSpecimenFieldTypeAdditionalInfo]) {
        [self.mooseFields addSubview:[self createMooseAdditionalInfoField:specimen y:accumulatedHeight]];
        accumulatedHeight += RiistaDefaultValueElementHeight;
    } else {
        specimen.additionalInfo = nil;
    }

    [self.mooseFields setHidden:NO];
    [self.mooseFieldsHeightConstraint setConstant:accumulatedHeight];

    [self.mooseFields setUserInteractionEnabled:(self.editMode && (self.event == nil || [self.event isEditable]))];
}

- (RiistaValueListButton*)createSpeciesExtraItem:(NSString*)name value:(NSString*)value y:(int)y
{
    RiistaValueListButton *control = [[RiistaValueListButton alloc]
                                      initWithFrame:CGRectMake(0, y, self.speciesExtraFields.frame.size.width,
                                                               RiistaDefaultValueElementHeight)];
    control.backgroundColor = [UIColor whiteColor];
    control.enabled = self.editMode;
    control.titleText = name;
    if (value == nil) {
        control.valueText = @"";
    }
    else {
        control.valueText = value;
    }
    return control;
}

- (RiistaValueListButton*)createMooseItem:(NSString*)name value:(NSString*)value y:(int)y
{
    return [self createValueListButton:name value:value y:y width:self.mooseFields.frame.size.width];
}

- (RiistaValueListTextField*)createNumericMooseTextField:(NSString*)name value:(NSNumber*)value maxValue:(NSNumber*)maxValue y:(int)y grow:(int)grow
{
    NSNumber *safeValue = value != nil ? value : [NSNumber numberWithInt:0];
    NSNumber *displayedValue = [safeValue compare:maxValue] == NSOrderedDescending ? maxValue : value;
    RiistaValueListTextField *item = [self createMooseTextField:name
                                                           value:[displayedValue stringValue]
                                                               y:y
                                                            grow:grow];
    item.textField.keyboardType = UIKeyboardTypeNumberPad;
    item.maxNumberValue = maxValue;
    item.nonNegativeIntNumberOnly = YES;
    return item;
}

- (RiistaValueListTextField*)createMooseTextField:(NSString*)name value:(NSString*)value y:(int)y grow:(int)grow
{
    return [self createValueListTextField:name value:value y:y grow:grow width:self.mooseFields.frame.size.width];
}

- (RiistaValueListButton*)createValueListButton:(NSString*)name value:(NSString*)value y:(int)y width:(int)width
{
    RiistaValueListButton *control = [[RiistaValueListButton alloc] initWithFrame:CGRectMake(0, y, width, RiistaDefaultValueElementHeight)];
    control.backgroundColor = [UIColor whiteColor];
    control.enabled = self.editMode;
    control.titleText = name;
    control.valueText = (value != nil) ? value : @"";
    return control;
}

- (RiistaValueListTextField*)createValueListTextField:(NSString*)name value:(NSString*)value y:(int)y grow:(int)grow width:(int)width
{
    RiistaValueListTextField *control = [[RiistaValueListTextField alloc]
                                         initWithFrame:CGRectMake(0, y, width, RiistaDefaultValueElementHeight + grow)];
    control.backgroundColor = [UIColor whiteColor];
    control.textField.enabled = self.editMode;
    control.textField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:control.textField];
    control.titleTextLabel.text = name;
    control.textField.text = (value != nil) ? value : @"";
    return control;
}

- (UIView*)createCheckbox:(BOOL)checked
               frameWidth:(CGFloat)frameWidth
                        y:(int)y
                    title:(NSString*)title
                      tag:(NSInteger)tag
                   action:(SEL)action
{
    UIView *item = [[UIView alloc] initWithFrame: CGRectMake (0, y, frameWidth, RiistaCheckboxElementHeight)];
    item.backgroundColor = [UIColor whiteColor];

    M13Checkbox* box = [[M13Checkbox alloc] initWithFrame:CGRectMake (LEFT_MARGIN, 0, item.frame.size.width - LEFT_MARGIN - RIGHT_MARGIN, RiistaCheckboxElementHeight)
                                                    title:title];
    box.titleLabel.font = [UIFont fontWithName:AppFont.Name size:AppFont.LabelMedium];
    box.tag = tag;
    box.checkState = checked ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;
    box.enabled = self.editMode;
    [RiistaViewUtils setCheckboxStyle:box];
    [box addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [item addSubview:box];

    return item;
}

- (UIView*)createMooseLoneCalfChoice:(RiistaSpecimen*)specimen y:(int)y
{
    BOOL alone = (specimen.alone != nil) ? [specimen.alone boolValue] : false;

    return [self createCheckbox:alone
                     frameWidth:self.mooseFields.frame.size.width
                              y:y
                          title:RiistaLocalizedString(@"ObservationDetailsMooseCalf", nil)
                            tag:0
                         action:@selector(loneCalfCheckboxDidChange:)];
}

- (void)loneCalfCheckboxDidChange:(id)sender
{
    RiistaSpecimen *specimen = self.specimenData[0];
    specimen.alone = [self resolveCheckboxValue:sender];
}

- (NSNumber*)resolveCheckboxValue:(id)checkbox
{
    M13Checkbox *box = (M13Checkbox*)checkbox;
    if (box.checkState == M13CheckboxStateChecked) {
        return [NSNumber numberWithBool:YES];
    }
    else if (box.checkState == M13CheckboxStateUnchecked) {
        return [NSNumber numberWithBool:NO];
    }
    else {
        return nil;
    }
}

- (UIView*)createMooseNotEdibleChoice:(RiistaSpecimen*)specimen y:(int)y
{
    BOOL notEdible = (specimen.notEdible != nil) ? [specimen.notEdible boolValue] : false;

    return [self createCheckbox:notEdible
                     frameWidth:self.mooseFields.frame.size.width
                              y:y
                          title:RiistaLocalizedString(@"MooseNotEdible", nil)
                            tag:0
                         action:@selector(notEdibleCheckboxDidChange:)];
}

- (void)notEdibleCheckboxDidChange:(id)sender
{
    RiistaSpecimen *specimen = self.specimenData[0];
    specimen.notEdible = [self resolveCheckboxValue:sender];
}

- (UIView*)createMooseAntlersLostChoice:(RiistaSpecimen*)specimen y:(int)y
{
    BOOL antlersLost = (specimen.antlersLost != nil) ? [specimen.antlersLost boolValue] : false;

    return [self createCheckbox:antlersLost
                     frameWidth:self.mooseFields.frame.size.width
                              y:y
                          title:RiistaLocalizedString(@"AntlersLost", nil)
                            tag:0
                         action:@selector(antlersLostCheckboxDidChange:)];
}

- (void)antlersLostCheckboxDidChange:(id)sender
{
    RiistaSpecimen *specimen = self.specimenData[0];
    specimen.antlersLost = [self resolveCheckboxValue:sender];

    [self setupMooseInfo];

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (UIView*)createAntlersInstructions:(NSInteger)speciesId y:(int)y
{
    InstructionsButton *instructionsButton =
        [[InstructionsButton alloc] initWithFrame:CGRectMake(0, y, self.mooseFields.frame.size.width, RiistaInstructionsViewHeight)];
    instructionsButton.titleLabel.text = RiistaLocalizedString(@"Instructions", nil);
    instructionsButton.delegate = self;
    return instructionsButton;
}

- (void)onInstructionsRequested
{
    NSArray *instructions = [AntlerInstructions getInstructionsForSpeciesCode:self.species.speciesId];
    if (instructions.count == 0) {
        DDLog(@"No instructions for the current species, doing nothing");
        return;
    }

    UINavigationController *containerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"InstructionsControllerContainer"];

    InstructionsViewController *instructionsVC = (InstructionsViewController*)containerVC.rootViewController;
    [instructionsVC setInstructionsItems:instructions];
    NSString *instructionsFormat = RiistaLocalizedString(@"InstructionsFormat", nil);
    NSString *speciesName = [RiistaUtils nameWithPreferredLanguage:self.species.name];
    [instructionsVC setTitle:[NSString stringWithFormat:instructionsFormat, speciesName]];
    instructionsVC.modalPresentationStyle = UIModalPresentationPopover;

    [self presentViewController:containerVC animated:YES completion:nil];
}

- (RiistaValueListTextField*)createMooseWeightEstimatedItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseWeightEstimated", nil) value:[self formatMooseValue: specimen.weightEstimated] y:y grow:0];
    item.textField.tag = MOOSE_WEIGHT_ESTIMATED_TAG;
    item.textField.keyboardType = UIKeyboardTypeNumberPad;
    item.minNumberValue = [NSNumber numberWithInt:1];
    item.maxNumberValue = [NSNumber numberWithInt:999];
    item.nonNegativeIntNumberOnly = YES;
    item.delegate = self;

    return item;
}

- (RiistaValueListTextField*)createMooseWeightMeasuredItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseWeightWeighted", nil) value:[self formatMooseValue: specimen.weightMeasured] y:y grow:0];
    item.textField.tag = MOOSE_WEIGHT_MEASURED_TAG;
    item.textField.keyboardType = UIKeyboardTypeNumberPad;
    item.minNumberValue = [NSNumber numberWithInt:1];
    item.maxNumberValue = [NSNumber numberWithInt:999];
    item.nonNegativeIntNumberOnly = YES;
    item.delegate = self;
    return item;
}

- (RiistaValueListButton*)createMooseFitnessClassItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListButton *item = [self createMooseItem:RiistaLocalizedString(@"MooseFitnessClass", nil) value:RiistaMappedValueString(specimen.fitnessClass, nil) y:y];
    item.tag = MOOSE_FITNESS_TAG;
    [item addTarget:self action:@selector(mooseFitnessClassClicked:) forControlEvents:UIControlEventTouchUpInside];
    return item;
}

- (void)mooseFitnessClassClicked:(id)sender
{
    NSArray *values = @[@"ERINOMAINEN", @"NORMAALI", @"LAIHA", @"NAANTYNYT"];

    ValueListViewController* controller = [self loadListViewController:values];
    controller.fieldKey = MOOSE_FITNESS_KEY;
    controller.titlePrompt = RiistaLocalizedString(@"MooseFitnessClass", nil);
    [self.navigationController pushViewController:controller animated:YES];
}

- (RiistaValueListButton*)createMooseAntlersTypeItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListButton *item = [self createMooseItem:RiistaLocalizedString(@"MooseAntlersType", nil) value:RiistaMappedValueString(specimen.antlersType, nil) y:y];
    item.tag = MOOSE_ANTLERS_TYPE_TAG;
    [item addTarget:self action:@selector(mooseAntlersTypeClicked:) forControlEvents:UIControlEventTouchUpInside];
    return item;
}

- (void)mooseAntlersTypeClicked:(id)sender
{
    NSArray *values = @[@"HANKO", @"LAPIO", @"SEKA"];

    ValueListViewController* controller = [self loadListViewController:values];
    controller.fieldKey = MOOSE_ANTLERS_TYPE_KEY;
    controller.titlePrompt = RiistaLocalizedString(@"MooseAntlersType", nil);
    [self.navigationController pushViewController:controller animated:YES];
}

- (RiistaValueListButton*)createHuntingMethodItem:(NSString*)value y:(int)y
{
    RiistaValueListButton *item = [self createSpeciesExtraItem:RiistaLocalizedString(@"HarvestHuntingTypeTitle", nil)
                                                         value:RiistaMappedValueString(value, nil) y:y];
    item.tag = HARVEST_HUNTING_TYPE_TAG;
    [item addTarget:self action:@selector(huntingMethodClicked:) forControlEvents:UIControlEventTouchUpInside];
    return item;
}

- (void)huntingMethodClicked:(id)sender
{
    NSArray *values = @[@"SHOT", @"CAPTURED_ALIVE", @"SHOT_BUT_LOST"];

    ValueListViewController* controller = [self loadListViewController:values];
    controller.fieldKey = HARVEST_HUNTING_TYPE_KEY;
    controller.titlePrompt = RiistaLocalizedString(@"HarvestHuntingTypeTitle", nil);
    [self.navigationController pushViewController:controller animated:YES];
}

- (UIView*)createFeedingPlaceChoice:(BOOL)value y:(int)y
{
    return [self createCheckbox:value
                     frameWidth:self.speciesExtraFields.frame.size.width
                              y:y
                          title:RiistaLocalizedString(@"HarvestFeedingPlaceTitle", nil)
                            tag:HARVEST_FEEDING_PLACE_TAG
                         action:@selector(feedingPlaceCheckboxDidChange:)];

}

- (void)feedingPlaceCheckboxDidChange:(id)sender
{
    self.harvestFeedingPlace = [self resolveCheckboxValue:sender];
}

- (UIView*)createTaigaBeanGooseChoice:(BOOL)value y:(int)y
{
    return [self createCheckbox:value
                     frameWidth:self.speciesExtraFields.frame.size.width
                              y:y
                          title:RiistaLocalizedString(@"HarvestTaigaBeanGooseTitle", nil)
                            tag:HARVEST_TAIGA_BEAN_GOOSE_TAG
                         action:@selector(taigaBeanGooseCheckboxDidChange:)];
}

- (void)taigaBeanGooseCheckboxDidChange:(id)sender
{
    self.harvestTaigaBeanGoose = [self resolveCheckboxValue:sender];
}

- (ValueListViewController*)loadListViewController:(NSArray*)values
{
    UIStoryboard* details = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    ValueListViewController* controller = [details instantiateViewControllerWithIdentifier:@"valueListController"];
    controller.delegate = self;

    NSMutableArray *valueList = [[NSMutableArray alloc] init];
    for (NSString* value in values) {
        [valueList addObject:value];
    }
    controller.values = valueList;

    return controller;
}

- (void)valueSelectedForKey:(NSString*)key value:(NSString*)value
{
    if (self.specimenData.count > 0) {
        if ([key isEqualToString:DEER_HUNTING_TYPE_KEY]) {
            if ([CLEAR_SELECTION_TEXT isEqualToString:value]) {
                self.selectedDeerHuntingType = DeerHuntingTypeNone;
            } else {
                self.selectedDeerHuntingType = [DeerHuntingTypeHelper parseWithHuntingTypeString:value
                                                                                        fallback:DeerHuntingTypeNone];
            }
        }
        else if ([key isEqualToString:MOOSE_FITNESS_KEY]) {
            RiistaSpecimen *specimen = self.specimenData[0];
            specimen.fitnessClass = value;
        }
        else if ([key isEqualToString:MOOSE_ANTLERS_TYPE_KEY]) {
            RiistaSpecimen *specimen = self.specimenData[0];
            specimen.antlersType = value;
        }
        else if ([key isEqualToString:HARVEST_HUNTING_TYPE_KEY]) {
            self.harvestHuntingType = value;
        }
        [self setupDeerHuntingTypeFields];
        [self setupMooseInfo];
        [self setupSpeciesExtraFields];
        [self updateSubmitButton];
    }
}

- (RiistaValueListTextField*)createMooseAntlersWidthItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"MooseAntlersWidth", nil)
                                                                 value:specimen.antlersWidth
                                                              maxValue:[NSNumber numberWithInt:200]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_WIDTH_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersPointsLeft:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"MooseAntlersPointsLeft", nil)
                                                                 value:specimen.antlerPointsLeft
                                                              maxValue:[NSNumber numberWithInt:30]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_POINTS_LEFT_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersPointsRight:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"MooseAntlersPointsRight", nil)
                                                                 value:specimen.antlerPointsRight
                                                              maxValue:[NSNumber numberWithInt:30]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_POINTS_RIGHT_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersGirthItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"AntlersGirth", nil)
                                                                 value:specimen.antlersGirth
                                                              maxValue:[NSNumber numberWithInt:50]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_GIRTH_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersLengthItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"AntlersLength", nil)
                                                                 value:specimen.antlersLength
                                                              maxValue:[NSNumber numberWithInt:100]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_LENGTH_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersInnerWidthItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"AntlersInnerWidth", nil)
                                                                 value:specimen.antlersInnerWidth
                                                              maxValue:[NSNumber numberWithInt:100]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_INNER_WIDTH_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersShaftWidthItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createNumericMooseTextField:RiistaLocalizedString(@"AntlerShaftDiameter", nil)
                                                                 value:specimen.antlersShaftWidth
                                                              maxValue:[NSNumber numberWithInt:10]
                                                                     y:y
                                                                  grow:0];
    item.textField.tag = MOOSE_ANTLERS_SHAFT_WIDTH_TAG;
    item.delegate = self;
    return item;
}

- (RiistaValueListTextField*)createMooseAdditionalInfoField:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseAdditionalInfo", nil) value:specimen.additionalInfo y:y grow:MOOSE_INFO_EXTRA_HEIGHT];
    item.textField.tag = MOOSE_ADDITIONAL_INFO_TAG;
    item.textField.keyboardType = UIKeyboardTypeDefault;
    item.textField.returnKeyType = UIReturnKeyDone;
    item.textField.inputAccessoryView = nil;
    item.delegate = self;
    return item;
}

- (void)setupPermitInfo
{
    [self.permitPrompt setText:RiistaLocalizedString(@"PermitDescription", nil)];
    [RiistaViewUtils setCheckboxStyle:self.permitCheckbox];

    [self.permitCheckbox addTarget:self action:@selector(permitCheckboxDidChange:) forControlEvents:UIControlEventValueChanged];
    self.permitCheckbox.enabled = YES;
}

- (void)refreshPermitViewVisibility
{
    [self showPermitView:(self.editMode || [self.event.permitNumber length] > 0)];
}

- (void)showPermitView:(BOOL)show
{
    if (show) {
        self.permitView.hidden = NO;
    }
    else {
        self.permitView.hidden = YES;
    }
}

- (void)permitCheckboxDidChange:(id)sender
{
    if (self.permitCheckbox.checkState == M13CheckboxStateChecked) {
        [self navigateToPermitList:nil];
    }
    else {
        self.selectedPermitNumber = nil;
        self.selectedPermitType = nil;
    }

    [self updatePermitInfo];
}

- (void)permitTapped:(id)sender
{
    if (self.editMode) {
        [self navigateToPermitList:[self.permitNumber text]];
    }
}

- (void)updateSpeciesButton
{
    self.speciesButton.imageEdgeInsets = UIEdgeInsetsMake(self.speciesButton.imageEdgeInsets.top,
                                                          self.species != nil ? -12: 0,
                                                          self.speciesButton.imageEdgeInsets.bottom,
                                                          self.speciesButton.imageEdgeInsets.right);
    self.speciesButton.titleEdgeInsets = UIEdgeInsetsMake(self.speciesButton.titleEdgeInsets.top,
                                                          self.species != nil ? 0: 16,
                                                          self.speciesButton.titleEdgeInsets.bottom,
                                                          self.speciesButton.titleEdgeInsets.right);
    self.speciesButton.imageView.layer.cornerRadius = 3;
}

- (void)updatePermitInfo
{
    [self updateSelectedPermitType];

    CGFloat originalConstant = self.permitNumberHeight.constant;

    // Displayed data
    if ([self.selectedPermitNumber length] > 0) {
        [self.permitCheckbox setCheckState:M13CheckboxStateChecked];

        [self.permitType setText:self.selectedPermitType];
        [self.permitType setHidden:NO];
        [self.permitType sizeToFit]; // can be multiline

        [self.permitNumber setText:self.selectedPermitNumber];
        [self.permitNumber setHidden:NO];
        self.permitNumberHeight.constant = 20.f;
    }
    else {
        [self.permitCheckbox setCheckState:M13CheckboxStateUnchecked];

        [self.permitType setText:nil];
        [self.permitType setHidden:YES];
        [self.permitNumber setText:nil];
        [self.permitNumber setHidden:YES];

        self.permitNumberHeight.constant = 0.f;
    }

    if (originalConstant != self.permitNumberHeight.constant) {
        [self.permitNumber setNeedsLayout];
    }

    // Control enabled status
    if (self.editMode && (self.event == nil || [self.event isEditable])) {
        self.permitType.textColor = [UIColor blackColor];
        self.permitNumber.textColor = [UIColor blackColor];
        self.permitType.userInteractionEnabled = YES;
        self.permitNumber.userInteractionEnabled = YES;

        self.permitCheckbox.enabled = YES;
    }
    else {
        self.permitType.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.permitNumber.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.permitType.userInteractionEnabled = NO;
        self.permitNumber.userInteractionEnabled = NO;

        self.permitCheckbox.enabled = NO;
    }

    [self updateRequiredSpecimenDetails];
    [self updatePermitRequiredLabelState:[self getReport]];
    [self updateSubmitButton];
}

- (void)updateRequiredSpecimenDetails
{
    RiistaPermitManager *permitManager = [RiistaPermitManager sharedInstance];
    Permit *selectedPermit = [permitManager getPermit:self.selectedPermitNumber];

    Specimen *requiredFields = [self getRequiredSpecimenFields];

    if (selectedPermit != nil && self.species != nil) {
        PermitSpeciesAmounts *speciesAmount = [permitManager getSpeciesAmountFromPermit:selectedPermit forSpecies:(int)self.species.speciesId];
        [self.specimenDetail setRequiresGender:speciesAmount.genderRequired
                                        andAge:speciesAmount.ageRequired
                                     andWeight:speciesAmount.weightRequired];
    }
    else {
        [self.specimenDetail setRequiresGender:[requiredFields getGender] == RequiredYES
                                        andAge:[requiredFields getAge] == RequiredYES
                                     andWeight:[requiredFields getWeight] == RequiredYES];
    }
}

- (void)updateSelectedPermitType
{
    if (self.selectedPermitNumber != nil) {
        RiistaPermitManager *permitManager = [RiistaPermitManager sharedInstance];
        Permit *selectedPermit = [permitManager getPermit:self.selectedPermitNumber];

        self.selectedPermitType = selectedPermit.permitType;
    } else {
        self.selectedPermitType = nil;
    }
}

- (Specimen*)getRequiredSpecimenFields {
    NSInteger huntingYear = [RiistaUtils startYearFromDate:self.startTime];
    bool insideSeason = [HarvestSeasonUtil isInsideHuntingSeasonWithDay:self.startTime
                                                        gameSpeciesCode:self.species.speciesId];

    HarvestReportingType reportingType = HarvestReportingTypeBASIC;
    if (self.selectedPermitNumber != nil) {
        reportingType = HarvestReportingTypePERMIT;
    } else if (insideSeason) {
        reportingType = HarvestReportingTypeSEASON;
    }

    Specimen *specimen = [RequiredHarvestFields getSpecimenFieldsWithHuntingYear:huntingYear
                                                                 gameSpeciesCode:self.species.speciesId
                                                                   huntingMethod:[RequiredHarvestFields huntingMethodFromStringWithString:self.harvestHuntingType]
                                                                   reportingType:reportingType];

    return specimen;
}

/**
 * Generate new or remove existing items until list size matches amount
 * @param specimenList List to fix
 * @param amount Target amount
 */
- (void)fixSpecimenDataToAmount:(NSMutableOrderedSet*)specimenList toAmount:(NSInteger)amount
{
    NSEntityDescription *specimenEntity = [NSEntityDescription entityForName:@"Specimen" inManagedObjectContext:_editContext];

    if (amount > 0 && amount < [specimenList count]) {
        [self purgeEmptySpecimenItems:specimenList];

        while ([specimenList count] > amount) {
            RiistaSpecimen *specimen = specimenList[[specimenList count] - 1];
            [self didRemoveSpecimen:specimen];
        }
    }

    while ([_specimenData count] < amount) {
        RiistaSpecimen *specimen = (RiistaSpecimen*)[[NSManagedObject alloc] initWithEntity:specimenEntity
                                                             insertIntoManagedObjectContext:_editContext];
        [self didAddSpecimen:specimen];
    }
}

/**
 * Prepare specimen items for saving.
 * Get rid of all empty items.
 */
- (void)purgeEmptySpecimenItems:(NSMutableOrderedSet*)specimenList
{
    NSMutableArray *discardedItems = [NSMutableArray array];

    for (RiistaSpecimen *specimen in _specimenData) {
        if ([specimen isEmpty]) {
            [discardedItems addObject:specimen];
            [self.event removeSpecimensObject:specimen];
            [self.editContext deleteObject:specimen];
        }
    }

    [specimenList removeObjectsInArray:discardedItems];
}

- (void)setupNavBarButtons
{
    _editBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_white"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(enableEditMode:)];
    _deleteBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete_white"]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(deleteButtonClicked:)];
}

- (void)updateBarButtonStates
{
    [self refreshDateTimeButtonState];

    NSMutableArray *barItems = [[NSMutableArray alloc] initWithCapacity:2];

    if (self.event && !self.editMode) {
        if ([self.event isEditable]) {
            [barItems addObject:self.deleteBarButton];
        }
        [barItems addObject:self.editBarButton];
    }
    else if (self.event && self.editMode) {
        if ([self.event isEditable]) {
            [barItems addObject:self.deleteBarButton];
        }
    }

    [self.navigationItem setRightBarButtonItems:barItems];
}

- (void)refreshDateTimeButtonState
{
    if (self.editMode && (self.event == nil || (self.event && [self.event isEditable]))) {
        [self.dateButton setEnabled:YES animated:YES];
        [self.timeButton setEnabled:YES animated:YES];
    }
    else {
        [self.dateButton setEnabled:NO animated:YES];
        [self.timeButton setEnabled:NO animated:YES];
    }
}

- (void)updateTitle
{
    NSDate *dateValue = self.event ? self.event.pointOfTime : _startTime;

    NSString *dateString = [self.dateFormatter stringFromDate:dateValue];
    [self.dateButton setTitle:dateString forState:UIControlStateNormal];

    NSString *timeString = [self.timeFormatter stringFromDate:dateValue];
    [self.timeButton setTitle:timeString forState:UIControlStateNormal];

    self.title = RiistaLocalizedString(@"Harvest", nil);
}

- (void)setupGestureRecognizers
{
    self.permitTypeTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(permitTapped:)];
    self.permitNumberTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(permitTapped:)];

    [self.permitTypeTapRecognizer setDelegate:self];
    [self.permitNumberTapRecognizer setDelegate:self];

    [self.permitType setUserInteractionEnabled:YES];
    [self.permitType addGestureRecognizer:self.permitTypeTapRecognizer];

    [self.permitNumber setUserInteractionEnabled:YES];
    [self.permitNumber addGestureRecognizer:self.permitNumberTapRecognizer];
}

- (void)setupLocationListeningForNewEvent
{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    // iOS8 location service start fails silently unless authorization is explicitly requested.
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }

    gotGpsLocationFix = NO;
}

- (void)listenLocationIfNeeded
{
    // location manager only exists if we need to listen location changes
    if (locationManager == nil) {
        return;
    }

    [locationManager startUpdatingLocation];
}

- (void)dismissButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editCancelButtonClicked:(id)sender {
    self.harvestHuntingType = nil;
    self.harvestFeedingPlace = nil;
    self.harvestTaigaBeanGoose = nil;

    addedImage = nil;

    self.editMode = NO;
    [self.editContext rollback];
    [self initForEdit:self.event];
    [self updateTitle];
    [self updateBarButtonStates];
}

- (void)enableEditMode:(id)sender
{
    self.editMode = YES;

    [self updateTitle];
    [self setupAmountInfo];
    [self setupDeerHuntingTypeFields];
    [self setupSpecimenInfo];
    [self updateBarButtonStates];

    [self refreshPermitViewVisibility];
    [self updatePermitInfo];
    // try to load the image. Will indicate load failure to the user appropriately
    [self refreshImage];

    self.descriptionField.enabled = YES;
    [self.imagesButton setEnabled:YES animated:YES];
    self.mapView.userInteractionEnabled = YES;

    self.contentEditBottomConstraint.constant = CONTENT_BOTTOM_MARGIN;
    self.buttonArea.userInteractionEnabled = YES;
    [self.buttonArea setHidden:NO];
    self.cancelButton.enabled = YES;
    [self updateSubmitButton];

    [self.buttonArea setNeedsLayout];
    [self.buttonArea layoutIfNeeded];

    [self.speciesButton setEnabled:(self.event && [self.event isEditable]) animated:YES];

    if (self.event && [self.event isEditable]) {
        if (self.permitTypeTapRecognizer) {
            [self.permitTypeTapRecognizer setEnabled:YES];
        }
        if (self.permitNumberTapRecognizer) {
            [self.permitNumberTapRecognizer setEnabled:YES];
        }
        self.permitType.textColor = [UIColor blackColor];
        self.permitNumber.textColor = [UIColor blackColor];
    }
}

- (void)submitButtonClicked:(id)sender
{
    [self disableUserControls];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryEntry" inManagedObjectContext:self.editContext];
    DiaryEntry *diaryEntry = (DiaryEntry*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.editContext];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.startTime];
    diaryEntry.year = @([components year]);
    diaryEntry.month = @([components month]);
    diaryEntry.pointOfTime = self.startTime;
    diaryEntry.gameSpeciesCode = @(self.species.speciesId);
    diaryEntry.amount = [NSNumber numberWithInteger:[self.amountTextField.text integerValue]];
    diaryEntry.diarydescription = self.descriptionField.textView.text;
    diaryEntry.type = DiaryEntryTypeHarvest;
    diaryEntry.remote = @(NO);
    diaryEntry.sent = @(NO);
    diaryEntry.mobileClientRefId = [RiistaUtils generateMobileClientRefId];
    diaryEntry.permitNumber = self.selectedPermitNumber;
    [self saveHarvestSpecVersionToDiaryEntry:diaryEntry];

    [self saveDeerHuntingTypeTo:diaryEntry];
    [self saveSpecimenExtraFieldsTo:diaryEntry];

    [self purgeEmptySpecimenItems:_specimenData];
    [diaryEntry addSpecimens:_specimenData];

    NSEntityDescription *coordinatesEntity = [NSEntityDescription entityForName:@"GeoCoordinate" inManagedObjectContext:self.editContext];
    GeoCoordinate *coordinates = (GeoCoordinate*)[[NSManagedObject alloc] initWithEntity:coordinatesEntity insertIntoManagedObjectContext:self.editContext];

    coordinates.latitude = [NSNumber numberWithFloat:_selectedCoordinates.x];
    coordinates.longitude = [NSNumber numberWithFloat:_selectedCoordinates.y];
    coordinates.accuracy = [NSNumber numberWithFloat:self.selectedLocation.horizontalAccuracy];
    coordinates.source = _locationSource;

    diaryEntry.coordinates = coordinates;

    if (addedImage != nil) {
        [diaryEntry addDiaryImages:[NSSet setWithObject:addedImage]];
    }

    if (![HarvestValidator isValidWithHarvest:diaryEntry]) {
        NSLog(@"Harvest validation failed");
        return;
    }

    [[RiistaGameDatabase sharedInstance] addLocalEvent:diaryEntry];
    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        [[RiistaGameDatabase sharedInstance] sendAndNotifyUnsentDiaryEntries:nil];
    }
    [self navigateToDiaryLog];
}

- (void)specimenButtonClicked:(id)sender
{
    NSInteger amount = [self.amountTextField.text integerValue];

    if (amount > 0 && amount <= DiaryEntrySpecimenDetailsMax)
    {
        RiistaSpecimenListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"specimenListController"];

        BOOL genderRequired = false;
        BOOL ageRequired = false;
        BOOL weightRequired = false;
        [self getRequiredFieldsGender:&genderRequired andAge:&ageRequired andWeight:&weightRequired];
        [controller setRequiredFields:genderRequired ageREquired:ageRequired weightRequired:weightRequired];

        [controller setContent:_specimenData];
        controller.editMode = self.editMode && (self.event == nil || [self.event isEditable]);
        controller.editContext = self.editContext;
        controller.species = self.species;
        controller.delegate = self;

        [self hideKeyboard];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)getRequiredFieldsGender:(BOOL*)genderReq andAge:(BOOL*)ageReq andWeight:(BOOL*)weightReq
{
    if ([self.selectedPermitNumber length] > 0) {
        RiistaPermitManager *permitManager = [RiistaPermitManager sharedInstance];
        Permit *permit = [permitManager getPermit:self.selectedPermitNumber];
        PermitSpeciesAmounts *speciesAmounts = [permitManager getSpeciesAmountFromPermit:permit forSpecies:(int)self.species.speciesId];

        if (speciesAmounts != nil) {
            *genderReq = speciesAmounts.genderRequired;
            *ageReq = speciesAmounts.ageRequired;
            *weightReq = speciesAmounts.weightRequired;
        }
    }
}

- (void)saveChangesButtonClicked:(id)sender
{
    if (self.eventInvalid) {
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:0 userInfo:nil];
        [self showEditError:error];
        return;
    }
    
    if (!self.event.managedObjectContext) {
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:409 userInfo:nil];
        [self showEditError:error];
        return;
    }
    
    // Do not let user start anything before a page change
    [self disableUserControls];

    self.event.sent = @(NO);
    self.event.gameSpeciesCode = @(self.species.speciesId);
    self.event.amount = [NSNumber numberWithInteger:[self.amountTextField.text integerValue]];
    self.event.diarydescription = self.descriptionField.textView.text;
    self.event.permitNumber = self.selectedPermitNumber;
    [self saveHarvestSpecVersionToDiaryEntry:self.event];
    [self saveDeerHuntingTypeTo:self.event];

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.event.pointOfTime];
    self.event.year = @([components year]);
    self.event.month = @([components month]);

    [self saveSpecimenExtraFieldsTo:self.event];

    [self purgeEmptySpecimenItems:_specimenData];

    self.event.coordinates.latitude = [NSNumber numberWithFloat:_selectedCoordinates.x];
    self.event.coordinates.longitude = [NSNumber numberWithFloat:_selectedCoordinates.y];
    self.event.coordinates.accuracy = [NSNumber numberWithFloat:self.selectedLocation.horizontalAccuracy];
    self.event.coordinates.source = _locationSource;

    if (![HarvestValidator isValidWithHarvest:self.event]) {
        NSLog(@"Harvest validation failed");
        return;
    }

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        DiaryEntry *currentEntry = [[RiistaGameDatabase sharedInstance] diaryEntryWithId:[self.event.remoteId integerValue]];

        // Check for changes locally
        if ([currentEntry.rev integerValue] > [self.event.rev integerValue]) {
            NSError *error = [NSError errorWithDomain:RiistaEditDomain code:409 userInfo:nil];
            [self showEditError:error];
            return;
        }

        [[RiistaGameDatabase sharedInstance] editLocalEvent:self.event
                                                  newImages:addedImage ? [NSArray arrayWithObject:addedImage] : [self.event.diaryImages allObjects]];

        __weak RiistaLogGameViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editDiaryEntry:self.event completion:^(NSDictionary *response, NSError *error) {
            if (weakSelf) {
                if (!error) {
                    [self.event.managedObjectContext performBlock:^(void) {
                        // Save local changes
                        NSError *err;
                        if ([self.event.managedObjectContext save:&err]) {
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
                        [weakSelf enableEditMode:weakSelf];
                }
            }
        }];
    } else {
        [[RiistaGameDatabase sharedInstance] editLocalEvent:self.event
                                                  newImages:addedImage ? [NSArray arrayWithObject:addedImage] : [self.event.diaryImages allObjects]];
        [self navigateToDiaryLog];
    }
}

- (void)saveHarvestSpecVersionToDiaryEntry:(DiaryEntry*)diaryEntry
{
    diaryEntry.harvestSpecVersion = [NSNumber numberWithInteger:HarvestSpecVersion];
}

- (NSNumber*)parseMooseValue:(NSString*)text
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.locale = [NSLocale currentLocale];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter numberFromString:text];
}

- (NSString*)formatMooseValue:(NSNumber*)value
{
    if (value == nil) {
        return @"";
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setPositiveFormat:@"0.#"];
    return [formatter stringFromNumber:value];
}

- (void)saveDeerHuntingTypeTo:(DiaryEntry*)entry
{
    entry.deerHuntingType = self.selectedDeerHuntingType != DeerHuntingTypeNone ?
    [DeerHuntingTypeHelper stringForDeerHuntingType:self.selectedDeerHuntingType] : nil;
    // description only used when hunting type == other
    entry.deerHuntingTypeDescription = self.selectedDeerHuntingType == DeerHuntingTypeOther ? self.selectedDeerHuntingTypeDescription : nil;
}

- (void)saveSpecimenExtraFieldsTo:(DiaryEntry*)harvest
{
    M13Checkbox *box = [self.view viewWithTag:HARVEST_FEEDING_PLACE_TAG];
    if (box) {
        harvest.feedingPlace = [NSNumber numberWithBool:(box.checkState == M13CheckboxStateChecked) ? YES : NO];
    }
    else {
        harvest.feedingPlace = nil;
    }

    box = [self.view viewWithTag:HARVEST_TAIGA_BEAN_GOOSE_TAG];
    if (box) {
        harvest.taigaBeanGoose = [NSNumber numberWithBool:(box.checkState == M13CheckboxStateChecked) ? YES : NO];
    }
    else {
        harvest.taigaBeanGoose = nil;
    }

    RiistaValueListButton *huntingType = [self.view viewWithTag:HARVEST_HUNTING_TYPE_TAG];
    if (huntingType) {
        harvest.huntingMethod = self.harvestHuntingType;
    }
    else {
        harvest.huntingMethod = nil;
    }
}

- (void)resetSpecimenExtraFields
{
    self.harvestHuntingType = nil;
    self.harvestFeedingPlace = nil;
    self.harvestTaigaBeanGoose = nil;

    if (self.event != nil) {
        self.event.feedingPlace = nil;
        self.event.huntingMethod = nil;
        self.event.taigaBeanGoose = nil;
    }
}

- (void)dateTimeButtonClicked:(id)sender
{
    [self hideKeyboard];

    NSDate *defaultDate = self.event ? self.event.pointOfTime : self.startTime;

    RMAction *selectAction = [RMAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                 style:RMActionStyleDone
                                            andHandler:^(RMActionController * controller) {
        NSDate *selectedDate = ((UIDatePicker*)controller.contentView).date;

        if (self.event) {
            self.event.pointOfTime = selectedDate;
        }

        self.startTime = selectedDate;
        [self updateTitle];
        [self setupSpeciesExtraFields];
        [self setupMooseInfo];
        [self updatePermitInfo];
        [self updateSubmitButton];
    }];

    RMAction *cancelAction = [RMAction actionWithTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                 style:RMActionStyleCancel
                                            andHandler:^(RMActionController * controller) {
        // Do nothing
    }];

    RMDateSelectionViewController *dateSelectionVC = [RMDateSelectionViewController actionControllerWithStyle:RMActionControllerStyleDefault
                                                                                                 selectAction:selectAction
                                                                                              andCancelAction:cancelAction];

    dateSelectionVC.datePicker.date = defaultDate;
    dateSelectionVC.datePicker.timeZone = RiistaDateTimeUtils.finnishTimezone;
    dateSelectionVC.datePicker.maximumDate = [NSDate date];
    dateSelectionVC.datePicker.locale = [RiistaSettings locale];
    dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    if (@available(iOS 13.4, *)) {
        dateSelectionVC.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }

    [self presentViewController:dateSelectionVC animated:YES completion:nil];
}

- (void)deleteButtonClicked:(id)sender
{
    [self hideKeyboard];

    MDCAlertController *alertController = [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"DeleteEntryCaption", nil)
                                                                               message:RiistaLocalizedString(@"DeleteEntryText", nil)];

    MDCAlertAction *cancelAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                           handler:nil];
    [alertController addAction:cancelAction];

    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                       handler:^(MDCAlertAction *action) {
        [self onDeleteConfirmed];
    }];
    [alertController addAction:okAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)onDeleteConfirmed
{
    if (self.eventInvalid) {
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:0 userInfo:nil];
        [self showEditError:error];
        return;
    }

    if (!self.event.managedObjectContext) {
        NSError *error = [NSError errorWithDomain:@"EventEditing" code:409 userInfo:nil];
        [self showEditError:error];
        return;
    }

    // Do not let user start anything before a page change
    [self disableUserControls];

    self.event.sent = @(NO);
    self.event.pendingOperation = [NSNumber numberWithInteger:DiaryEntryOperationDelete];

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        [self doDeleteNow];
    } else {
        [[RiistaGameDatabase sharedInstance] deleteLocalEvent:self.event];
        [self doDeleteIfLocalOnly];
        [self navigateToDiaryLog];
    }
}

- (void)doDeleteNow
{
    DiaryEntry *currentEntry = [[RiistaGameDatabase sharedInstance] diaryEntryWithId:[self.event.remoteId integerValue]];

    // Check for changes locally
    if ([currentEntry.rev integerValue] > [self.event.rev integerValue]) {
        NSError *error = [NSError errorWithDomain:RiistaEditDomain code:409 userInfo:nil];
        [self showEditError:error];
        return;
    }

    [[RiistaGameDatabase sharedInstance] deleteLocalEvent:self.event];

    __weak RiistaLogGameViewController *weakSelf = self;

    // Just delete local copy if not sent to server yet
    if ([self doDeleteIfLocalOnly]) {
        [weakSelf navigateToDiaryLog];
        return;
    }

    [[RiistaGameDatabase sharedInstance] deleteDiaryEntry:self.event completion:^(NSError *error) {
        if (weakSelf) {
            if (!error) {
                [self.event.managedObjectContext performBlock:^(void) {
                    [self.event.managedObjectContext deleteObject:self.event];
                    [self.event.managedObjectContext performBlock:^(void) {
                        NSError *err;
                        if ([self.event.managedObjectContext save:&err]) {

                            // Save to persistent store
                            RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
                            [delegate.managedObjectContext performBlock:^(void) {
                                NSError *Err;
                                [delegate.managedObjectContext save:&Err];
                            }];
                        }
                    }];
                }];
                [weakSelf navigateToDiaryLog];
            } else {
                [weakSelf showEditError:error];
                if (weakSelf.editMode)
                    [weakSelf enableEditMode:weakSelf];
            }
        }
    }];
}

// Return true if local only entry. Will delete without server request.
- (BOOL)doDeleteIfLocalOnly
{
    if ([self.event.remote boolValue] == NO) {
        [self.event.managedObjectContext performBlock:^(void) {
            [self.event.managedObjectContext deleteObject:self.event];
            [self.event.managedObjectContext performBlock:^(void) {
                NSError *err;
                if ([self.event.managedObjectContext save:&err]) {

                    // Save to persistent store
                    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
                    [delegate.managedObjectContext performBlock:^(void) {
                        NSError *Err;
                        [delegate.managedObjectContext save:&Err];
                    }];
                }
            }];
        }];
        return YES;
    }
    return NO;
}

// Remember to get rid of created object immediately after use  so it will not be persisted
- (DiaryEntry*)tempHarvestFromInput:(DiaryEntry*)diaryEntry context:(NSManagedObjectContext*)context
{
    diaryEntry.pointOfTime = self.startTime;
    diaryEntry.gameSpeciesCode = [NSNumber numberWithInteger:self.species.speciesId];
    diaryEntry.amount = [NSNumber numberWithInteger:[self.amountTextField.text integerValue]];
    diaryEntry.permitNumber = self.selectedPermitNumber;

    [self saveDeerHuntingTypeTo:diaryEntry];
    NSMutableOrderedSet *specimens = [NSMutableOrderedSet new];
    for (RiistaSpecimen *specimen in self.specimenData) {
        [specimens addObject:[specimen riista_copyInContext:context]];
    }
    diaryEntry.specimens = specimens;

    NSEntityDescription *coordinatesEntity = [NSEntityDescription entityForName:@"GeoCoordinate" inManagedObjectContext:context];
    GeoCoordinate *coordinates = (GeoCoordinate*)[[NSManagedObject alloc] initWithEntity:coordinatesEntity insertIntoManagedObjectContext:context];

    coordinates.latitude = [NSNumber numberWithFloat:_selectedCoordinates.x];
    coordinates.longitude = [NSNumber numberWithFloat:_selectedCoordinates.y];
    coordinates.accuracy = [NSNumber numberWithFloat:self.selectedLocation.horizontalAccuracy];
    coordinates.source = _locationSource;

    diaryEntry.coordinates = coordinates;
    diaryEntry.huntingMethod = self.harvestHuntingType;
    diaryEntry.feedingPlace = self.harvestFeedingPlace;
    diaryEntry.taigaBeanGoose = self.harvestTaigaBeanGoose;

    return diaryEntry;
}

- (void)amountTextFieldDidChange:(id)sender
{
    [self updateSubmitButton];
}

- (void)amountTextFieldDidBeginEditing:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [notification.object selectAll:nil];
    });
}

- (void)amountTextFieldDidEndEditing:(id)sender
{
    [self setupSpecimenInfo];
}

- (void)showEditError:(NSError*)error
{
    MDCAlertController *alertController = [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"Error", nil)
                                                                               message:RiistaLocalizedString(@"DiaryEditFailed", nil)];

    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil) handler:nil];
    [alertController addAction:okAction];

    if (error.code == 409) { // Event outdated
        [alertController setMessage:RiistaLocalizedString(@"OutdatedDiaryEntry", nil)];
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *newLocation = locations.lastObject;
    // Do not update location after user manually sets it.
    if (![_locationSource isEqual:DiaryEntryLocationManual]) {
        _locationSource = DiaryEntryLocationGps;

        if (!gotGpsLocationFix) {
            // Avoids lots of unnecessary tile requests.
            gotGpsLocationFix = YES;
            [self updateLocation:newLocation animateCamera:NO];
        }
        else {
            [self updateLocation:newLocation animateCamera:YES];
        }
    }
    [self updateSubmitButton];
}

- (void)updateLocation:(CLLocation*)newLocation animateCamera:(BOOL)animateCamera
{
    self.selectedLocation = newLocation;

    if (animateCamera) {
        [_mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:newLocation.coordinate zoom:15]];
    }
    else {
        [_mapView moveCamera:[GMSCameraUpdate setTarget:newLocation.coordinate zoom:15]];
    }

    RiistaMapUtils *mapUtils = [RiistaMapUtils sharedInstance];
    _selectedCoordinates = [mapUtils WGS84toETRSTM35FIN:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
    _coordinateLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"CoordinatesFormat", nil), _selectedCoordinates.x, _selectedCoordinates.y];
    [self updateSubmitButton];

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

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    NSLog(@"Location manager failed with error: %@", error);
}

- (void)updateSubmitButton
{
    if (self.event != nil) {
        self.event.permitNumber = self.selectedPermitNumber;
        self.event.gameSpeciesCode = @(self.species.speciesId);
        [self saveDeerHuntingTypeTo:self.event];
        [self saveSpecimenExtraFieldsTo:self.event];
        if (![HarvestValidator isValidWithHarvest:self.event]) {
            [self.submitButton setEnabled:NO];
            return;
        }
    } else {
        NSManagedObjectContext *tempContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        tempContext.parentContext = self.editContext;

        NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryEntry" inManagedObjectContext:tempContext];
        DiaryEntry *diaryEntry = (DiaryEntry*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:tempContext];

        DiaryEntry *tempHarvest = [self tempHarvestFromInput:diaryEntry context:tempContext];

        if (![HarvestValidator isValidWithHarvest:tempHarvest]) {
            [self.submitButton setEnabled:NO];

            return;
        }

        [tempContext reset];
    }

    // Validate against permit if number is set
    if ([self.selectedPermitNumber length] > 0) {
        RiistaPermitManager *permitManager = [RiistaPermitManager sharedInstance];
        Permit *selectedPermit = [permitManager getPermit:self.selectedPermitNumber];

        if (selectedPermit == nil || ![permitManager validateEntryPermitInformation:[NSNumber numberWithInteger:self.species.speciesId]
                                                                        pointOfTime:self.startTime
                                                                             amount:[NSNumber numberWithInteger:[self.amountTextField.text integerValue]]
                                                                          specimens:self.specimenData
                                                                             permit:selectedPermit]) {
            [self.submitButton setEnabled:NO];
            return;
        }
    }

    if (self.selectedLocation && self.species && [self validAmountInput:self.amountTextField.text]) {
        [self.submitButton setEnabled:YES];
        return;
    }
    [self.submitButton setEnabled:NO];
}

- (BOOL)validAmountInput:(NSString*) input
{
    NSScanner *sc = [NSScanner scannerWithString:input];
    NSInteger value;
    if ([sc scanInteger:&value])
    {
        return [sc isAtEnd] && value > 0 && value <= [AppConstants HarvestMaxAmount];
    }

    return NO;
}

- (IBAction)speciesButtonClick:(id)sender
{
    if (self.editMode) {
        [self hideKeyboard];

        self.dialogTransitionController = [[MDCDialogTransitionController alloc] init];

        SpeciesCategoryDialogController *dialogController = [SpeciesCategoryDialogController new];
        dialogController.modalPresentationStyle = UIModalPresentationCustom;
        dialogController.transitioningDelegate = self.dialogTransitionController;

        dialogController.completionHandler = ^(NSInteger categoryCode) {
            if (categoryCode >= 1 && categoryCode <= 3) {
                RiistaSpeciesSelectViewController *speciesController = [self.storyboard instantiateViewControllerWithIdentifier:@"speciesSelectController"];
                speciesController.delegate = self;
                speciesController.category = self.categoryList[categoryCode - 1];

                [self.navigationController pushViewController:speciesController animated:YES];
            }
        };

        [self presentViewController:dialogController animated:YES completion:nil];
    }
}

- (IBAction)imagesButtonClick:(id)sender
{
    if (self.editMode) {
        [imageUtil editImageWithPickerDelegate:self];
    }
    else if ([imageUtil hasImagesWithEntry:self.event]) {
        if (self.imagesButton.imageLoadStatus == LoadStatusFailure) {
            ImageLoadRequest *loadRequest = [ImageLoadRequest fromDiaryImage:[self selectDisplayedImage]
                                                                     options:[ImageLoadOptions aspectFilledWithSize:CGSizeMake(50.f, 50.f)]];

            [imageUtil displayImageLoadFailedDialog:self
                                             reason:self.imagesButton.imageLoadFailureReason
                                   imageLoadRequest:loadRequest
                         allowAnotherPhotoSelection:NO];

            return;
        }

        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ImageFullViewController *dest = (ImageFullViewController*)[sb instantiateViewControllerWithIdentifier:@"ImageFullController"];
        dest.item = self.event;

        UIStoryboardSegue *seque = [UIStoryboardSegue segueWithIdentifier:@"" source:self destination:dest performHandler:^{
            [self.navigationController pushViewController:dest animated:YES];
        }];

        [seque perform];
    }
}

- (void)navigateToDiaryLog
{
    // Specimen data may have been invalidated and accessing it would result in core data exception
    [self.specimenData removeAllObjects];

    if (!self.eventId) {
        NSNotification *msg = [NSNotification notificationWithName:RiistaLogTypeSelectedKey object:[NSNumber numberWithInt:RiistaEntryTypeHarvest]];
        [[NSNotificationCenter defaultCenter] postNotification:msg];
    }

    NSNotification *savedMsg = [NSNotification notificationWithName:RiistaLogEntrySavedKey object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:savedMsg];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigateToMapPage
{
    BOOL selectMode = self.editMode && (self.event == nil || [self.event isEditable]);

    ViewOrSelectLocationOnMapViewController *controller =
        [ViewOrSelectLocationOnMapViewController createWithSelectMode:selectMode
                                                      initialLocation:self.selectedLocation
                                                             listener:self];
    controller.title = RiistaLocalizedString(@"Harvest", nil);
    [self hideKeyboard];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)navigateToPermitList:(NSString*)permitNumber
{
    RiistaPermitListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"permitListViewController"];
    controller.delegate = self;
    controller.inputValue = self.selectedPermitNumber;

    [self hideKeyboard];
    [self.navigationController pushViewController:controller animated:YES];
}

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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeEditField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    RiistaSpecimen *specimen = self.specimenData[0];

    switch (textField.tag) {
        case DEER_HUNTING_TYPE_DESCRIPTION:
            self.selectedDeerHuntingTypeDescription = textField.text;
            break;
        case MOOSE_WEIGHT_ESTIMATED_TAG:
            specimen.weightEstimated = [self parseMooseValue:textField.text];
            break;
        case MOOSE_WEIGHT_MEASURED_TAG:
            specimen.weightMeasured = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_WIDTH_TAG:
            specimen.antlersWidth = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_POINTS_LEFT_TAG:
            specimen.antlerPointsLeft = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_POINTS_RIGHT_TAG:
            specimen.antlerPointsRight = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_GIRTH_TAG:
            specimen.antlersGirth = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_LENGTH_TAG:
            specimen.antlersLength = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_INNER_WIDTH_TAG:
            specimen.antlersInnerWidth = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ANTLERS_SHAFT_WIDTH_TAG:
            specimen.antlersShaftWidth = [self parseMooseValue:textField.text];
            break;
        case MOOSE_ADDITIONAL_INFO_TAG:
            specimen.additionalInfo = textField.text;
            break;
        default:
            break;
    }

    self.activeEditField = nil;
}

- (void)setSelectedSpecies:(RiistaSpecies*)species
{
    self.species = species;

    UIImage *speciesImage = [ImageUtils loadSpeciesImageWithSpeciesCode:species.speciesId
                                                                   size:CGSizeMake(42.0f, 42.0f)];

    [self.speciesButton setImage:speciesImage forState:UIControlStateNormal];
    [self.speciesButton setTitle:[RiistaUtils nameWithPreferredLanguage:species.name] forState:UIControlStateNormal];
    [self updateSpeciesButton];

    [self setupDeerHuntingTypeFields];
    [self setupAmountInfo];
    [self setupSpecimenInfo];
    [self updateSubmitButton];

    // Layout needed since visible views may have changed.
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)onLocationSelectedWithLocation:(CLLocationCoordinate2D)coordinates
{
    _locationSource = DiaryEntryLocationManual;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinates.latitude longitude:coordinates.longitude];

    [self updateLocation:location animateCamera:NO];
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self navigateToMapPage];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    [self navigateToMapPage];
}

# pragma mark - PermitPageDelegate

- (void)permitSelected:(NSString*)permitNumber speciesCode:(NSInteger)speciesCode;
{
    self.selectedPermitNumber = permitNumber;
    [self updateSelectedPermitType];
    [self speciesSelected:[[RiistaGameDatabase sharedInstance] speciesById:speciesCode]];

    [self updatePermitInfo];
}

#pragma mark - SpeciesSelectionDelegate

- (void)speciesSelected:(RiistaSpecies*)species
{
    self.species = species;

    UIImage *speciesImage = [ImageUtils loadSpeciesImageWithSpeciesCode:species.speciesId
                                                                   size:CGSizeMake(42.0f, 42.0f)];

    [self.speciesButton setImage:speciesImage forState:UIControlStateNormal];
    [self.speciesButton setTitle:[RiistaUtils nameWithPreferredLanguage:species.name] forState:UIControlStateNormal];
    [self updateSpeciesButton];

    [self setupDeerHuntingTypeFields];
    [self resetSpecimenExtraFields];
    [self setupAmountInfo];
    [self setupSpecimenInfo];
    [self updateSubmitButton];

    // Layout needed since visible views may have changed.
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#pragma mark - SpecimensUpdatedDelegate

- (void)didAddSpecimen:(RiistaSpecimen *)specimen
{
    [_specimenData addObject:specimen];
    if (self.event != nil) {
        [self.event addSpecimensObject:specimen];
    }
    [self.amountTextField setText:[NSString stringWithFormat:@"%lu", (unsigned long)[_specimenData count]]];
}

- (void)didRemoveSpecimen:(RiistaSpecimen *)specimen
{
    [_specimenData removeObject:specimen];
    if (self.event != nil) {
        [self.event removeSpecimensObject:specimen];
        [self.editContext deleteObject:specimen];
    }
    [self.amountTextField setText:[NSString stringWithFormat:@"%lu", (unsigned long)[_specimenData count]]];
}

# pragma mark - RiistaKeyboardHandlerDelegate

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;

    NSUInteger newLength = oldLength - rangeLength + replacementLength;

    return newLength <= [AppConstants HarvestMaxAmountLength] || ([string rangeOfString: @"\n"].location != NSNotFound);
}

#pragma mark - RiistaImagePickerDelegate

- (void)imagePickedWithImage:(IdentifiableImage *)image
{
    // reuse addedImage if one exists. addedImage will not be persisted unless data is submitted
    if (addedImage == nil) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryImage" inManagedObjectContext:self.editContext];

        addedImage = (DiaryImage*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.editContext];

        // setup rest of the image data. These won't be updated before submit is pressed and
        // thus it is safe to setup them just once
        addedImage.imageid = [[NSUUID UUID] UUIDString];
        addedImage.status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
        addedImage.type = [NSNumber numberWithInteger:DiaryImageTypeLocal];
    }

    [image.imageIdentifier saveIdentifierTo:addedImage];
    [self refreshImage];
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
        [self refreshImage];

        [imageUtil displayImageLoadFailedDialog:self reason:reason imageLoadRequest:loadRequest allowAnotherPhotoSelection:YES];
    }
}


#pragma mark - NSNotificationCenter

- (void)calendarEntriesUpdated:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSArray *entries = userInfo[@"entries"];
    for (int i=0; i<entries.count; i++) {
        RiistaDiaryEntryUpdate *update = entries[i];
        if ([update.entry.objectID isEqual:self.eventId]) {
            self.eventInvalid = YES;
        }
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
