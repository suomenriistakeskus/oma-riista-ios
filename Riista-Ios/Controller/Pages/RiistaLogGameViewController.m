#import <GoogleMaps/GoogleMaps.h>
#import "RiistaLogGameViewController.h"
#import "RiistaHeaderLabel.h"
#import "Styles.h"
#import "RiistaMapUtils.h"
#import "RiistaNavigationController.h"
#import "RiistaSpeciesSelectViewController.h"
#import "RiistaSpecimenListViewController.h"
#import "RiistaMapViewController.h"
#import "RiistaGameDatabase.h"
#import "RiistaUtils.h"
#import "RiistaSpeciesCategory.h"
#import "RiistaSpecies.h"
#import "RiistaSpecimen.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaAppDelegate.h"
#import "DiaryEntry.h"
#import "GeoCoordinate.h"
#import "RiistaDiaryImageManager.h"
#import "RiistaSettings.h"
#import "UIColor+ApplicationColor.h"
#import "DiaryImage.h"
#import "RiistaDiaryEntryUpdate.h"
#import "RiistaLocalization.h"
#import "RiistaSpecimenView.h"
#import "RiistaMmlTileLayer.h"
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

@interface RiistaMarkerInfoWindow : UIView

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *gpsQualityImageView;
@property (weak, nonatomic) IBOutlet UILabel *gpsQualityLabel;

@end

@interface RiistaLogGameViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, SpeciesSelectionDelegate, KeyboardHandlerDelegate, UITextViewDelegate, UITextFieldDelegate, RiistaDiaryImageManagerDelegate, SpecimensUpdatedDelegate, MapPageDelegate, PermitPageDelegate, ValueSelectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *dateTimeToolbarButton;
@property (weak, nonatomic) IBOutlet UIButton *editToolbarButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteToolbarButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIView *speciesView;
@property (weak, nonatomic) IBOutlet UIImageView *speciesImageView;
@property (weak, nonatomic) IBOutlet UILabel *speciesNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speciesMandatoryMarkerLabel;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UIView *statusContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *statusIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet RiistaSpecimenView *specimenDetail;
@property (weak, nonatomic) IBOutlet UILabel *specimenLabel;
@property (weak, nonatomic) IBOutlet UIButton *specimenButton;
@property (weak, nonatomic) IBOutlet UILabel *imagesLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *imageListView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageListViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionTopSeparatorHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionBottomSeparatorHeight;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIView *buttonArea;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (weak, nonatomic) IBOutlet UIView *permitView;
@property (weak, nonatomic) IBOutlet M13Checkbox *permitCheckbox;
@property (weak, nonatomic) IBOutlet UILabel *permitPrompt;
@property (weak, nonatomic) IBOutlet UILabel *permitNumber;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *permitNumberHeight;
@property (strong, nonatomic) UITapGestureRecognizer *permitNumberTapRecognizer;

@property (weak, nonatomic) IBOutlet UIView *mooseFields;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mooseFieldsHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *backgroundImages;
@property (weak, nonatomic) IBOutlet UIView *backgroundSpecimen;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *specimenBackgroundBottomConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonAreaHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *specimenDetailHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *specimenButtonHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *specimenButtonTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coordinateToPermitConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coordinateToSpeciesConstraint;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;
@property (strong, nonatomic) RiistaDiaryImageManager *imageManager;

@property (strong, nonatomic) ETRMSPair *selectedCoordinates;
@property (strong, nonatomic) CLLocation *selectedLocation;
@property (strong, nonatomic) NSString *locationSource;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSMutableOrderedSet *specimenData;
@property (strong, nonatomic) NSString *selectedPermitNumber;

@property (strong, nonatomic) NSString *mooseFitnessClass;
@property (strong, nonatomic) NSString *mooseAntlersType;

@property (strong, nonatomic) NSMutableArray *categoryList;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) UIAlertView *speciesSelectionAlertView;

@property (assign, nonatomic) BOOL editMode;
@property (assign, nonatomic) BOOL browsingImages;
@property (assign, nonatomic) UIView *activeEditField;

@property (strong, nonatomic) DiaryEntry *event;

@property (strong, nonatomic) NSManagedObjectContext *editContext;
@property (assign, nonatomic) BOOL eventInvalid;

@end

static const NSInteger TEXTVIEW_BOTTOM_PADDING = 10;
static const NSInteger MOOSE_INFO_EXTRA_HEIGHT = 50;

// Alertview tags
static const NSInteger SPECIES_SELECTION = 1;
static const NSInteger CONFIRM_REMOVE_ENTRY = 2;

static const NSInteger MAX_AMOUNT_VALUE = 999;
static const NSInteger MAX_AMOUNT_LENGTH = 3;

static const NSInteger MOOSE_NOT_EDIBLE_TAG = 100;
static const NSInteger MOOSE_WEIGHT_ESTIMATED_TAG = 101;
static const NSInteger MOOSE_WEIGHT_MEASURED_TAG = 102;
static const NSInteger MOOSE_FITNESS_TAG = 103;
static const NSInteger MOOSE_ANTLERS_TYPE_TAG = 104;
static const NSInteger MOOSE_ANTLERS_WIDTH_TAG = 105;
static const NSInteger MOOSE_ANTLERS_POINTS_LEFT_TAG = 106;
static const NSInteger MOOSE_ANTLERS_POINTS_RIGHT_TAG = 107;
static const NSInteger MOOSE_ADDITIONAL_INFO_TAG = 108;

static NSString * const MOOSE_FITNESS_KEY = @"MooseFitnessKey";
static NSString * const MOOSE_ANTLERS_TYPE_KEY = @"MooseAntlersTypeKey";

NSString* RiistaEditDomain = @"RiistaEdit";

@implementation RiistaLogGameViewController
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
        _editMode = NO;
        gotGpsLocationFix = NO;
        _submitButton.enabled = NO;
        _categoryList = [NSMutableArray new];
        _specimenData = [NSMutableOrderedSet new];
        _browsingImages = NO;
        NSDictionary *categories = [RiistaGameDatabase sharedInstance].categories;
        NSArray *categoryKeys = [categories allKeys];
        NSSortDescriptor *categorySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        NSArray *sortedCategoryKeys = [categoryKeys sortedArrayUsingDescriptors:@[categorySortDescriptor]];
        for (int i=0; i<categories.count; i++) {
            [_categoryList addObject:categories[sortedCategoryKeys[i]]];
        }
        RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        _editContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _editContext.parentContext = delegate.managedObjectContext;
        _eventInvalid = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amountTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:_amountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amountTextFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:_amountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amountTextFieldDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:_amountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarEntriesUpdated:) name:RiistaCalendarEntriesUpdatedKey object:nil];
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

    RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    if (self.event) {
        context = self.editContext;
    }
    else {
        self.editContext = context;
    }

    self.imageManager = [[RiistaDiaryImageManager alloc] initWithParentController:self
                                                                          andView:_imageListView
                                                   andContentViewHeightConstraint:_contentViewHeightConstraint
                                                     andImageViewHeightConstraint:_imageListViewHeightConstraint
                                                          andManagedObjectContext:context];
    self.imageManager.entryType = DiaryEntryTypeHarvest;

    _amountTextField.delegate = self;
    _descriptionTextView.delegate = self;

    [RiistaViewUtils setTextViewStyle:_descriptionTextView];
    
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

    [self setupPermitInfo];
    [self setupGestureRecognizers];

    [RiistaViewUtils addTopAndBottomBorders:self.speciesView];
    [RiistaViewUtils addTopAndBottomBorders:self.specimenButton];

    self.descriptionTopSeparatorHeight.constant = 1.f/[UIScreen mainScreen].scale;
    self.descriptionBottomSeparatorHeight.constant = 1.f/[UIScreen mainScreen].scale;

    [RiistaViewUtils setTextViewStyle:self.amountTextField];
    self.amountTextField.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:self.amountTextField];

    [Styles styleNegativeButton:_cancelButton];
    [Styles styleButton:_submitButton];
    _startTime = [NSDate date];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];

    self.contentViewHeightConstraint.constant = [[UIScreen mainScreen] applicationFrame].size.height - self.navigationController.navigationBar.frame.size.height - self.buttonAreaHeightConstraint.constant;

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    _amountLabel.text = RiistaLocalizedString(@"EntryDetailsAmountShort", nil);
    _imagesLabel.text = [RiistaLocalizedString(@"EntryDetailsImage", nil) uppercaseString];
    _descriptionLabel.text = [RiistaLocalizedString(@"EntryDetailsDescription", nil) uppercaseString];
    _specimenLabel.text = RiistaLocalizedString(@"Specimens", nil);

    [self updateTitle];
    [_submitButton setTitle:RiistaLocalizedString(@"Save", nil) forState:UIControlStateNormal];

    if (self.browsingImages) {
        [self initForEdit:self.event];
    }

    [self setupBarButtons];

    [self saveMooseFields];
    [self setupAmountInfo];
    [self setupSpecimenInfo];
    [self updatePermitInfo];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self saveMooseFields];

    if (self.speciesSelectionAlertView)
        [self.speciesSelectionAlertView dismissWithClickedButtonIndex:self.speciesSelectionAlertView.cancelButtonIndex animated:YES];
}

- (void)dealloc
{
    self.speciesSelectionAlertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initForNewEvent
{
    if (!self.species) {
        _speciesNameLabel.text = RiistaLocalizedString(@"ChooseSpecies", nil);
    } else {
        [self speciesSelected:self.species];
    }

    self.statusContainerHeightConstraint.constant = 0;
    self.statusContainer.hidden = YES;

    [_cancelButton setTitle:RiistaLocalizedString(@"Dismiss", nil) forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(dismissButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton addTarget:self action:@selector(submitButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_specimenButton addTarget:self action:@selector(specimenButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self initImageManager:[NSArray new]];
    self.imageManager.editMode = YES;
    self.imageListView.userInteractionEnabled = YES;

    self.editMode = YES;
    self.amountTextField.text = @"1";
    self.amountTextField.userInteractionEnabled = NO;

    self.editToolbarButton.hidden = YES;
    self.deleteToolbarButton.hidden = YES;

    [self updateSubmitButton];
    [self setupLocation];
}

- (void)initForEdit:(DiaryEntry*)event
{
    if (!self.event.managedObjectContext) {
        // If the event doesn't exist any more, go back to previous screen
        [self.navigationController popViewControllerAnimated:YES];
    }

    self.specimenData = [NSMutableOrderedSet orderedSetWithOrderedSet:event.specimens];
    self.selectedPermitNumber = event.permitNumber != nil ? [NSString stringWithString:event.permitNumber] : nil;

    RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.event.gameSpeciesCode integerValue]];
    [self speciesSelected:species];
    
    [_cancelButton setTitle:RiistaLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(editCancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton addTarget:self action:@selector(saveChangesButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_specimenButton addTarget:self action:@selector(specimenButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self initImageManager:[self.event.diaryImages allObjects]];
    [self setupAmountInfo];

    if (!self.browsingImages)
        [self setupBarEditButton];

    if (self.event.stateAcceptedToHarvestPermit != nil || self.event.harvestReportState != nil || [self.event.harvestReportRequired boolValue]) {
        [self setupHarvestState:self.event.stateAcceptedToHarvestPermit harvest:self.event.harvestReportState];
    } else {
        self.statusContainerHeightConstraint.constant = 0;
        self.statusContainer.hidden = YES;
    }

    self.amountTextField.text = [self.event.amount stringValue];
    self.amountTextField.userInteractionEnabled = NO;
    self.imageListView.userInteractionEnabled = YES;
    self.descriptionTextView.text = self.event.diarydescription;
    self.descriptionTextView.userInteractionEnabled = NO;
    [self updateTextViewHeight:self.descriptionTextView];

    self.buttonAreaHeightConstraint.constant = 0.f;
    self.buttonArea.userInteractionEnabled = NO;

    GeoCoordinate *coordinates = self.event.coordinates;
    WGS84Pair *pair = [[RiistaMapUtils sharedInstance] ETRMStoWGS84:[coordinates.latitude integerValue] y:[coordinates.longitude integerValue]];
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pair.x, pair.y) altitude:0 horizontalAccuracy:[coordinates.accuracy floatValue] verticalAccuracy:[coordinates.accuracy floatValue] timestamp:[NSDate date]];
    self.locationSource = coordinates.source;
    [self updateLocation:location animateCamera:NO];

    self.speciesView.userInteractionEnabled = NO;

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

    self.speciesView.userInteractionEnabled = NO;

    if (self.permitNumberTapRecognizer) {
        [self.permitNumberTapRecognizer setEnabled:NO];
    }

    self.permitCheckbox.enabled = NO;
    self.imageListView.userInteractionEnabled = NO;
    self.specimenDetail.userInteractionEnabled = NO;
    self.specimenButton.userInteractionEnabled = NO;
    self.mapView.userInteractionEnabled = NO;
    self.cancelButton.enabled = NO;
    self.submitButton.enabled = NO;
}

- (void)setupAmountInfo
{
    if (!self.species || !self.species.multipleSpecimenAllowedOnHarvests) {
        [self.amountLabel setHidden:YES];
        self.amountTextField.text = @"1";
        [self.amountTextField setUserInteractionEnabled:NO];
        [self.amountTextField setHidden:YES];
    }
    else {
        [self.amountLabel setHidden:NO];
        [self.amountTextField setUserInteractionEnabled:self.editMode && (self.event == nil || [self.event isEditable])];
        [self.amountTextField setHidden:NO];
    }
}

- (void)setupHarvestState:(NSString*)permitState harvest:(NSString*)harvestState
{
    self.statusIndicatorView.hidden = NO;
    self.statusIndicatorView.layer.cornerRadius = self.statusIndicatorView.frame.size.width/2;

    if ([DiaryEntryHarvestPermitProposed isEqual:permitState]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusProposed];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestPermitStateProposed", nil);
    } else if ([DiaryEntryHarvestPermitAccepted isEqual:permitState]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusAccepted];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestPermitStateAccepted", nil);
    } else if ([DiaryEntryHarvestPermitRejected isEqual:permitState]) {
        self.statusIndicatorView.backgroundColor = [UIColor applicationColor:RiistaApplicationColorHarvestPermitStatusRejected];
        self.statusLabel.text = RiistaLocalizedString(@"HarvestPermitStateRejected", nil);
    } else if ([harvestState isEqual:DiaryEntryHarvestStateProposed]) {
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

    self.specimenLabel.text = RiistaLocalizedString(@"SpecimenDetailsTitle", nil);

    if (self.species != nil && !self.species.multipleSpecimenAllowedOnHarvests) {
        [self.specimenDetail setHidden:NO];
        [self.specimenDetailHeightConstraint setConstant:106.f];

        [self.specimenButton setHidden:YES];
        [self.specimenButton setUserInteractionEnabled:NO];
        [self.specimenButtonHeightConstraint setConstant:0.f];
    }
    else if (self.species != nil
             && [self.amountTextField.text integerValue] > 0
             && [self.amountTextField.text integerValue] <= DiaryEntrySpecimenDetailsMax) {
        [self.specimenDetail setHidden:YES];
        [self.specimenDetailHeightConstraint setConstant:0.f];

        [self.specimenButton setHidden:NO];
        [self.specimenButton setUserInteractionEnabled:YES];
        [self.specimenButtonHeightConstraint setConstant:43.f];

        [self.specimenButton setNeedsLayout];
        [self.specimenButton layoutIfNeeded];
    }
    else {
        [self.specimenDetail setHidden:YES];
        [self.specimenDetailHeightConstraint setConstant:0.f];

        [self.specimenButton setHidden:YES];
        [self.specimenButton setUserInteractionEnabled:NO];
        [self.specimenButtonHeightConstraint setConstant:0.f];
    }

    [self setupMooseInfo];

    self.backgroundSpecimen.hidden = self.specimenDetail.hidden;
    self.specimenBackgroundBottomConstraint.constant = self.mooseFields.hidden ? 0 : -34;

    [self updateTextViewHeight:self.descriptionTextView];
}

- (void)specimenGenderOrAgeChanged:(UISegmentedControl*)sender
{
    if (self.species) {
        [self setupMooseInfo];

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];

        [self updateViewSize];
    }
}

- (void)updateViewSize
{
    CGSize s = self.scrollView.contentSize;
    s.height = self.descriptionTextView.frame.origin.y + self.descriptionTextView.frame.size.height + 10.0f;
    [self.scrollView setContentSize:s];

    self.contentViewHeightConstraint.constant = s.height;

    [self.scrollView setNeedsLayout];
    [self.scrollView layoutIfNeeded];
}

- (void)setupMooseInfo
{
    NSArray *views = [self.mooseFields subviews];
    for (UIView *v in views) {
        [v removeFromSuperview];
    }

    RiistaSpecimen *specimen = nil;
    if (self.specimenData.count > 0) {
        specimen = self.specimenData[0];
    }

    RiistaSpecies* species = self.species;
    if (species && specimen && species.speciesId == MooseId) {
        //A moose
        specimen.weight = nil;

        if (specimen.fitnessClass && !self.mooseFitnessClass) {
            self.mooseFitnessClass = specimen.fitnessClass;
        }
        if (specimen.antlersType && !self.mooseAntlersType) {
            self.mooseAntlersType = specimen.antlersType;
        }

        CGFloat H = 70;
        [self.mooseFields addSubview:[self createMooseNotEdibleChoice:specimen y:0]];
        [self.mooseFields addSubview:[self createMooseWeightEstimatedItem:specimen y:H*1]];
        [self.mooseFields addSubview:[self createMooseWeightMeasuredItem:specimen y:H*2]];
        [self.mooseFields addSubview:[self createMooseFitnessClassItem:specimen y:H*3]];

        if ([specimen.gender isEqualToString:SpecimenGenderMale] && [specimen.age isEqualToString:SpecimenAgeAdult]) {
            [self.mooseFields addSubview:[self createMooseAntlersTypeItem:specimen y:H*4]];
            [self.mooseFields addSubview:[self createMooseAntlersWidthItem:specimen y:H*5]];
            [self.mooseFields addSubview:[self createMooseAntlersPointsLeft:specimen y:H*6]];
            [self.mooseFields addSubview:[self createMooseAntlersPointsRight:specimen y:H*7]];
        }
        [self.mooseFields addSubview:[self createMooseAdditionalInfoField:specimen y:H * [self.mooseFields subviews].count]];

        CGFloat height = ([self.mooseFields subviews].count * H) + MOOSE_INFO_EXTRA_HEIGHT;

        [self.specimenDetail hideWeightInput:YES];
        [self.specimenButtonTopConstraint setConstant:height - 30];

        [self.mooseFields setHidden:NO];
        [self.mooseFieldsHeightConstraint setConstant:height];
    }
    else if (species && specimen &&
             (species.speciesId == FallowDeerId ||
              species.speciesId == WhiteTailedDeerId ||
              species.speciesId == WildForestDeerId)) {
        [self createDeerChoiseFields:specimen];
    }
    else {
        [self.specimenDetail hideWeightInput:NO];
        [self.specimenButtonTopConstraint setConstant:5.f];

        [self.mooseFields setHidden:YES];
        [self.mooseFieldsHeightConstraint setConstant:0.f];
    }
}

- (void)createDeerChoiseFields:(RiistaSpecimen*)specimen
{
    specimen.weight = nil;

    self.mooseFitnessClass = nil;
    self.mooseAntlersType = nil;

    CGFloat H = 70;
    [self.mooseFields addSubview:[self createMooseNotEdibleChoice:specimen y:0]];
    [self.mooseFields addSubview:[self createMooseWeightEstimatedItem:specimen y:H*1]];
    [self.mooseFields addSubview:[self createMooseWeightMeasuredItem:specimen y:H*2]];

    if ([specimen.gender isEqualToString:SpecimenGenderMale] && [specimen.age isEqualToString:SpecimenAgeAdult]) {
        [self.mooseFields addSubview:[self createMooseAntlersWidthItem:specimen y:H*3]];
        [self.mooseFields addSubview:[self createMooseAntlersPointsLeft:specimen y:H*4]];
        [self.mooseFields addSubview:[self createMooseAntlersPointsRight:specimen y:H*5]];
    }
    [self.mooseFields addSubview:[self createMooseAdditionalInfoField:specimen y:H * [self.mooseFields subviews].count]];

    CGFloat height = ([self.mooseFields subviews].count * H) + MOOSE_INFO_EXTRA_HEIGHT;

    [self.specimenDetail hideWeightInput:YES];
    [self.specimenButtonTopConstraint setConstant:height - 30];

    [self.mooseFields setHidden:NO];
    [self.mooseFieldsHeightConstraint setConstant:height];
}

- (RiistaValueListButton*)createMooseItem:(NSString*)name value:(NSString*)value y:(int)y
{
    RiistaValueListButton *control = [[RiistaValueListButton alloc] initWithFrame:CGRectMake(0, y, self.mooseFields.frame.size.width, 63)];
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

- (RiistaValueListTextField*)createMooseTextField:(NSString*)name value:(NSString*)value y:(int)y grow:(int)grow
{
    RiistaValueListTextField *control = [[RiistaValueListTextField alloc] initWithFrame:CGRectMake(0, y, self.mooseFields.frame.size.width, 63 + grow)];
    control.backgroundColor = [UIColor whiteColor];
    control.textView.editable = self.editMode;
    control.textView.scrollEnabled = NO;
    control.textView.inputAccessoryView = [KeyboardToolbarView textViewDoneToolbarView:control.textView];
    control.titleTextLabel.text = name;
    if (value == nil) {
        control.textView.text = @"";
    }
    else {
        control.textView.text = value;
    }
    return control;
}

- (UIView*)createMooseNotEdibleChoice:(RiistaSpecimen*)specimen y:(int)y
{
    BOOL notEdible = (specimen.notEdible != nil) ? [specimen.notEdible boolValue] : false;

    UIView *item = [[UIView alloc] initWithFrame: CGRectMake (0, 10, self.mooseFields.frame.size.width, 50)];
    item.backgroundColor = [UIColor whiteColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake (15, 0, item.frame.size.width, 50)];
    label.text = RiistaLocalizedString(@"MooseNotEdible", nil);
    [item addSubview:label];

    M13Checkbox* box = [[M13Checkbox alloc] initWithFrame:CGRectMake (item.frame.size.width - 40, 13, 25, 25)];
    box.tag = MOOSE_NOT_EDIBLE_TAG;
    box.checkState = notEdible ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;
    box.enabled = self.editMode;
    [RiistaViewUtils setCheckboxStyle:box];
    [item addSubview:box];

    [RiistaViewUtils addTopAndBottomBorders:item];

    return item;
}

- (RiistaValueListTextField*)createMooseWeightEstimatedItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseWeightEstimated", nil) value:[self formatMooseValue: specimen.weightEstimated] y:y grow:0];
    item.tag = MOOSE_WEIGHT_ESTIMATED_TAG;
    item.maxNumberValue = [NSNumber numberWithInt:999];
    return item;
}

- (RiistaValueListTextField*)createMooseWeightMeasuredItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseWeightWeighted", nil) value:[self formatMooseValue: specimen.weightMeasured] y:y grow:0];
    item.tag = MOOSE_WEIGHT_MEASURED_TAG;
    item.maxNumberValue = [NSNumber numberWithInt:999];
    return item;
}

- (RiistaValueListButton*)createMooseFitnessClassItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListButton *item = [self createMooseItem:RiistaLocalizedString(@"MooseFitnessClass", nil) value:RiistaMappedValueString(self.mooseFitnessClass, nil) y:y];
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
    RiistaValueListButton *item = [self createMooseItem:RiistaLocalizedString(@"MooseAntlersType", nil) value:RiistaMappedValueString(self.mooseAntlersType, nil) y:y];
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
        if ([key isEqualToString:MOOSE_FITNESS_KEY]) {
            self.mooseFitnessClass = value;
        }
        else if ([key isEqualToString:MOOSE_ANTLERS_TYPE_KEY]) {
            self.mooseAntlersType = value;
        }
        [self setupMooseInfo];
    }
}

- (RiistaValueListTextField*)createMooseAntlersWidthItem:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseAntlersWidth", nil) value:[specimen.antlersWidth stringValue] y:y grow:0];
    item.tag = MOOSE_ANTLERS_WIDTH_TAG;
    item.textView.keyboardType = UIKeyboardTypeNumberPad;
    item.maxNumberValue = [NSNumber numberWithInt:999];
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersPointsLeft:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseAntlersPointsLeft", nil) value:[specimen.antlerPointsLeft stringValue] y:y grow:0];
    item.tag = MOOSE_ANTLERS_POINTS_LEFT_TAG;
    item.textView.keyboardType = UIKeyboardTypeNumberPad;
    item.maxNumberValue = [NSNumber numberWithInt:50];
    return item;
}

- (RiistaValueListTextField*)createMooseAntlersPointsRight:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseAntlersPointsRight", nil) value:[specimen.antlerPointsRight stringValue] y:y grow:0];
    item.tag = MOOSE_ANTLERS_POINTS_RIGHT_TAG;
    item.textView.keyboardType = UIKeyboardTypeNumberPad;
    item.maxNumberValue = [NSNumber numberWithInt:50];
    return item;
}

- (RiistaValueListTextField*)createMooseAdditionalInfoField:(RiistaSpecimen*)specimen y:(int)y
{
    RiistaValueListTextField *item = [self createMooseTextField:RiistaLocalizedString(@"MooseAdditionalInfo", nil) value:specimen.additionalInfo y:y grow:MOOSE_INFO_EXTRA_HEIGHT];
    item.tag = MOOSE_ADDITIONAL_INFO_TAG;
    item.textView.keyboardType = UIKeyboardTypeDefault;
    item.textView.returnKeyType = UIReturnKeyDone;
    item.textView.inputAccessoryView = nil;
    item.textView.scrollEnabled = YES;
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
        self.coordinateToPermitConstraint.priority = 999;
        self.coordinateToSpeciesConstraint.priority = 500;
        self.permitView.hidden = NO;
    }
    else {
        self.coordinateToPermitConstraint.priority = 500;
        self.coordinateToSpeciesConstraint.priority = 999;
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
    }

    [self updatePermitInfo];
}

- (void)permitNumberTapped:(id)sender
{
    if (self.editMode) {
        [self navigateToPermitList:[self.permitNumber text]];
    }
}

- (void)updatePermitInfo
{
    CGFloat originalConstant = self.permitNumberHeight.constant;

    // Displayed data
    if ([self.selectedPermitNumber length] > 0) {
        [self.permitCheckbox setCheckState:M13CheckboxStateChecked];

        [self.permitNumber setText:self.selectedPermitNumber];
        [self.permitNumber setHidden:NO];

        self.permitNumberHeight.constant = 20.f;
    }
    else {
        [self.permitCheckbox setCheckState:M13CheckboxStateUnchecked];

        [self.permitNumber setText:nil];
        [self.permitNumber setHidden:YES];

        self.permitNumberHeight.constant = 0.f;
    }

    if (originalConstant != self.permitNumberHeight.constant) {
        [self.permitNumber setNeedsLayout];
    }

    // Control enabled status
    if (self.editMode && (self.event == nil || [self.event isEditable])) {
        self.permitNumber.textColor = [UIColor blackColor];
        self.permitNumber.userInteractionEnabled = YES;

        self.permitCheckbox.enabled = YES;
    }
    else {
        self.permitNumber.textColor = [UIColor applicationColor:RiistaApplicationColorTextDisabled];
        self.permitNumber.userInteractionEnabled = NO;

        self.permitCheckbox.enabled = NO;
    }

    [self updateRequiredSpecimenDetails];
    [self updateViewSize];
}

- (void)updateRequiredSpecimenDetails
{
    RiistaPermitManager *permitManager = [RiistaPermitManager sharedInstance];
    Permit *selectedPermit = [permitManager getPermit:self.selectedPermitNumber];

    if (selectedPermit != nil && self.species != nil) {
        PermitSpeciesAmounts *speciesAmount = [permitManager getSpeciesAmountFromPermit:selectedPermit forSpecies:(int)self.species.speciesId];
        [self.specimenDetail setRequiresGender:speciesAmount.genderRequired
                                        andAge:speciesAmount.ageRequired
                                     andWeight:speciesAmount.weightRequired];
    }
    else {
        [self.specimenDetail setRequiresGender:NO andAge:NO andWeight:NO];
    }
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

- (void)setupBarButtons
{
    self.dateTimeToolbarButton.enabled = NO;
    self.editToolbarButton.enabled = NO;
    self.deleteToolbarButton.enabled = NO;

    if (self.event == nil && self.editMode && !self.browsingImages) {
        [self setupBarCalendarButton];
    }
    else if (self.event && !self.editMode && !self.browsingImages) {
        [self setupBarEditButton];
    }
    else if (self.event && self.editMode && !self.browsingImages) {
        [self setupBarCalendarAndDeleteButton];
    }
}

- (void)setupBarEditButton
{
    self.editToolbarButton.enabled = YES;
    [self.editToolbarButton addTarget:self action:@selector(enableEditMode:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupBarCalendarAndDeleteButton
{
    if (self.event && [self.event isEditable]) {
        self.dateTimeToolbarButton.enabled = YES;
        [self.dateTimeToolbarButton addTarget:self action:@selector(dateTimeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

        self.deleteToolbarButton.enabled = YES;
        [self.deleteToolbarButton addTarget:self action:@selector(deleteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupBarCalendarButton
{
    if (self.event == nil || (self.event && [self.event isEditable])) {
        self.dateTimeToolbarButton.enabled = YES;
        [self.dateTimeToolbarButton addTarget:self action:@selector(dateTimeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)initImageManager:(NSArray*)images
{
    if (self.imageManager) {
        [[self.imageListView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    [self.imageManager setupWithImages:images];
    self.imageManager.delegate = self;

    [self.backgroundImages.superview sendSubviewToBack:self.backgroundImages];
}

- (void)updateTitle
{
    if (self.event) {
        NSString *timeString = [self.dateFormatter stringFromDate:self.event.pointOfTime];
        self.dateTimeLabel.text = timeString;
    } else {
        NSString *timeString = [self.dateFormatter stringFromDate:_startTime];
        self.dateTimeLabel.text = timeString;
    }

    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle:RiistaLocalizedString(@"Game", nil)];
}

- (void)setupGestureRecognizers
{
    self.permitNumberTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(permitNumberTapped:)];
    [self.permitNumberTapRecognizer setDelegate:self];
    [self.permitNumber setUserInteractionEnabled:YES];
    [self.permitNumber addGestureRecognizer:self.permitNumberTapRecognizer];
}

- (void)setupLocation
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
    [locationManager startUpdatingLocation];
}

- (void)dismissButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editCancelButtonClicked:(id)sender {
    self.mooseFitnessClass = nil;
    self.mooseAntlersType = nil;

    self.editMode = NO;
    self.imageManager.editMode = NO;
    [self.editContext rollback];
    [self initForEdit:self.event];
    [self updateTitle];
    [self setupBarButtons];
}

- (void)enableEditMode:(id)sender
{
    self.editMode = YES;
    self.imageManager.editMode = YES;
    [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[]];
    [self updateTitle];
    [self setupAmountInfo];
    [self setupSpecimenInfo];
    [self setupBarButtons];

    [self refreshPermitViewVisibility];
    [self updatePermitInfo];

    self.descriptionTextView.userInteractionEnabled = YES;
    self.imageListView.userInteractionEnabled = YES;
    self.mapView.userInteractionEnabled = YES;

    self.buttonAreaHeightConstraint.constant = 70.f;
    self.buttonArea.userInteractionEnabled = YES;
    self.cancelButton.enabled = YES;
    self.submitButton.enabled = YES;

    [self.buttonArea setNeedsLayout];
    [self.buttonArea layoutIfNeeded];

    self.speciesView.userInteractionEnabled = self.event && [self.event isEditable];

    if (self.event && [self.event isEditable] && self.permitNumberTapRecognizer) {
        [self.permitNumberTapRecognizer setEnabled:YES];
        self.permitNumber.textColor = [UIColor blackColor];
    }

    [self updateViewSize];
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
    diaryEntry.diarydescription = self.descriptionTextView.text;
    diaryEntry.type = DiaryEntryTypeHarvest;
    diaryEntry.remote = @(NO);
    diaryEntry.sent = @(NO);
    diaryEntry.mobileClientRefId = [RiistaUtils generateMobileClientRefId];
    diaryEntry.permitNumber = self.selectedPermitNumber;
    diaryEntry.harvestSpecVersion = [NSNumber numberWithInteger:HarvestSpecVersion];

    [self saveMooseFields];

    [self purgeEmptySpecimenItems:_specimenData];
    [diaryEntry addSpecimens:_specimenData];

    NSEntityDescription *coordinatesEntity = [NSEntityDescription entityForName:@"GeoCoordinate" inManagedObjectContext:self.editContext];
    GeoCoordinate *coordinates = (GeoCoordinate*)[[NSManagedObject alloc] initWithEntity:coordinatesEntity insertIntoManagedObjectContext:self.editContext];

    coordinates.latitude = [NSNumber numberWithFloat:_selectedCoordinates.x];
    coordinates.longitude = [NSNumber numberWithFloat:_selectedCoordinates.y];
    coordinates.accuracy = [NSNumber numberWithFloat:self.selectedLocation.horizontalAccuracy];
    coordinates.source = _locationSource;

    diaryEntry.coordinates = coordinates;

    NSArray *images = [self.imageManager diaryImages];
    for (int i=0; i<images.count; i++) {
        ((DiaryImage*)images[i]).status = [NSNumber numberWithInteger:DiaryImageStatusInsertion];
        [diaryEntry addDiaryImagesObject:images[i]];
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
    self.event.diarydescription = self.descriptionTextView.text;
    self.event.permitNumber = self.selectedPermitNumber;
    self.event.harvestSpecVersion = [NSNumber numberWithInteger:HarvestSpecVersion];

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:self.event.pointOfTime];
    self.event.year = @([components year]);
    self.event.month = @([components month]);

    [self saveMooseFields];

    [self purgeEmptySpecimenItems:_specimenData];

    self.event.coordinates.latitude = [NSNumber numberWithFloat:_selectedCoordinates.x];
    self.event.coordinates.longitude = [NSNumber numberWithFloat:_selectedCoordinates.y];
    self.event.coordinates.accuracy = [NSNumber numberWithFloat:self.selectedLocation.horizontalAccuracy];
    self.event.coordinates.source = _locationSource;

    if ([RiistaSettings syncMode] == RiistaSyncModeAutomatic) {
        
        DiaryEntry *currentEntry = [[RiistaGameDatabase sharedInstance] diaryEntryWithId:[self.event.remoteId integerValue]];
        
        // Check for changes locally
        if ([currentEntry.rev integerValue] > [self.event.rev integerValue]) {
            NSError *error = [NSError errorWithDomain:RiistaEditDomain code:409 userInfo:nil];
            [self showEditError:error];
            return;
        }

        [[RiistaGameDatabase sharedInstance] editLocalEvent:self.event newImages:[self.imageManager diaryImages]];

        __weak RiistaLogGameViewController *weakSelf = self;
        [[RiistaGameDatabase sharedInstance] editDiaryEntry:self.event completion:^(NSDictionary *response, NSError *error) {
            if (weakSelf) {
                if (!error) {
                    [self.event.managedObjectContext performBlock:^(void) {
                        // Save local changes
                        NSError *err;
                        if ([self.event.managedObjectContext save:&err]) {
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
                        [weakSelf enableEditMode:weakSelf];
                }
            }
        }];
    } else {
        [[RiistaGameDatabase sharedInstance] editLocalEvent:self.event newImages:[self.imageManager diaryImages]];
        [self navigateToDiaryLog];
    }
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

- (void)saveMooseFields
{
    if (self.specimenData.count == 0) {
        return;
    }
    RiistaSpecimen *specimen = self.specimenData[0];

    M13Checkbox *box = [self.view viewWithTag:MOOSE_NOT_EDIBLE_TAG];
    if (box) {
        specimen.notEdible = [NSNumber numberWithBool:(box.checkState == M13CheckboxStateChecked) ? YES : NO];
    }
    else {
        specimen.notEdible = nil;
    }

    RiistaValueListTextField *weightEstimated = [self.view viewWithTag:MOOSE_WEIGHT_ESTIMATED_TAG];
    if (weightEstimated) {
        specimen.weightEstimated = [self parseMooseValue: weightEstimated.textView.text];
    }
    else {
        specimen.weightEstimated = nil;
    }

    RiistaValueListTextField *weightMeasured = [self.view viewWithTag:MOOSE_WEIGHT_MEASURED_TAG];
    if (weightMeasured) {
        specimen.weightMeasured = [self parseMooseValue: weightMeasured.textView.text];
    }
    else {
        specimen.weightMeasured = nil;
    }

    RiistaValueListButton *fitnessClass = [self.view viewWithTag:MOOSE_FITNESS_TAG];
    if (fitnessClass) {
        specimen.fitnessClass = self.mooseFitnessClass;
    }
    else {
        specimen.fitnessClass = nil;
    }

    RiistaValueListButton *antlersType = [self.view viewWithTag:MOOSE_ANTLERS_TYPE_TAG];
    if (antlersType) {
        specimen.antlersType = self.mooseAntlersType;
    }
    else {
        specimen.antlersType = nil;
    }

    RiistaValueListTextField *antlersWidth = [self.view viewWithTag:MOOSE_ANTLERS_WIDTH_TAG];
    if (antlersWidth) {
        specimen.antlersWidth = [self parseMooseValue: antlersWidth.textView.text];
    }
    else {
        specimen.antlersWidth = nil;
    }

    RiistaValueListTextField *antlersPointsLeft = [self.view viewWithTag:MOOSE_ANTLERS_POINTS_LEFT_TAG];
    if (antlersPointsLeft) {
        specimen.antlerPointsLeft = [self parseMooseValue: antlersPointsLeft.textView.text];
    }
    else {
        specimen.antlerPointsLeft = nil;
    }

    RiistaValueListTextField *antlersPointsRight = [self.view viewWithTag:MOOSE_ANTLERS_POINTS_RIGHT_TAG];
    if (antlersPointsRight) {
        specimen.antlerPointsRight = [self parseMooseValue: antlersPointsRight.textView.text];
    }
    else {
        specimen.antlerPointsRight = nil;
    }

    RiistaValueListTextField *additionalInfo = [self.view viewWithTag:MOOSE_ADDITIONAL_INFO_TAG];
    if (additionalInfo) {
        specimen.additionalInfo = additionalInfo.textView.text;
    }
    else {
        specimen.additionalInfo = nil;
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
    dateSelectionVC.datePicker.maximumDate = [NSDate date];
    dateSelectionVC.datePicker.locale = [RiistaSettings locale];
    dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDateAndTime;

    [self presentViewController:dateSelectionVC animated:YES completion:nil];
}

- (void)deleteButtonClicked:(id)sender
{
    [self hideKeyboard];

    UIAlertView *confirmDialog = [[UIAlertView alloc] initWithTitle:RiistaLocalizedString(@"DeleteEntryCaption", nil)
                                                            message:RiistaLocalizedString(@"DeleteEntryText", nil)
                                                           delegate:self
                                                  cancelButtonTitle:RiistaLocalizedString(@"CancelRemove", nil)
                                                  otherButtonTitles:RiistaLocalizedString(@"OK", nil), nil];
    confirmDialog.tag = CONFIRM_REMOVE_ENTRY;
    [confirmDialog show];
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
                            RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
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
                    RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
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
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:RiistaLocalizedString(@"Error", nil)
                          message:RiistaLocalizedString(@"DiaryEditFailed", nil)
                          delegate:self
                          cancelButtonTitle:RiistaLocalizedString(@"OK", nil)
                          otherButtonTitles:nil];
    if (error.code == 409) { // Event outdated
        alert.message = RiistaLocalizedString(@"OutdatedDiaryEntry", nil);
    }
    [alert show];
}

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
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

    [self updateSubmitButton];
    RiistaMapUtils *mapUtils = [RiistaMapUtils sharedInstance];
    _selectedCoordinates = [mapUtils WGS84toETRSTM35FIN:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
    _coordinateLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"CoordinatesFormat", nil), _selectedCoordinates.x, _selectedCoordinates.y];

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
        return [sc isAtEnd] && value > 0 && value <= MAX_AMOUNT_VALUE;
    }

    return NO;
}

- (IBAction)speciesButtonClick:(id)sender
{
    if (!self.editMode) {
        return;
    }

    if (self.selectedPermitNumber == nil) {
        [self hideKeyboard];

        self.speciesSelectionAlertView = [UIAlertView new];
        self.speciesSelectionAlertView.title = RiistaLocalizedString(@"ChooseSpecies", nil);
        self.speciesSelectionAlertView.delegate = self;
        for (int i=0; i<self.categoryList.count; i++) {
            RiistaSpeciesCategory *category = (RiistaSpeciesCategory*)self.categoryList[i];
            [self.speciesSelectionAlertView addButtonWithTitle:[RiistaUtils nameWithPreferredLanguage:category.name]];
        }
        [self.speciesSelectionAlertView addButtonWithTitle:RiistaLocalizedString(@"CancelRemove", nil)];
        self.speciesSelectionAlertView.cancelButtonIndex = self.categoryList.count;

        self.speciesSelectionAlertView.tag = SPECIES_SELECTION;
        [self.speciesSelectionAlertView show];
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
    RiistaMapViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"mapPageController"];
    controller.delegate = self;
    controller.editMode = self.editMode && (self.event == nil || [self.event isEditable]);
    controller.location = self.selectedLocation;

    controller.titlePrimaryText = RiistaLocalizedString(@"Game", nil);

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

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.activeEditField = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.activeEditField = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeEditField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeEditField = nil;
}

# pragma mark - MapPageDelegate

- (void)locationSetManually:(CLLocationCoordinate2D)coordinates
{
    _locationSource = DiaryEntryLocationManual;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinates.latitude longitude:coordinates.longitude];

    [self updateLocation:location animateCamera:NO];
}

# pragma mark - GMSMapViewDelegate

- (UIView*)mapView:(GMSMapView*)mapView markerInfoWindow:(GMSMarker*)marker {
    if (self.event || [self.locationSource isEqual:DiaryEntryLocationManual]) {
        return [UIView new];
    }

    RiistaMarkerInfoWindow *view =  [[[NSBundle mainBundle] loadNibNamed:@"RiistaMarkerInfoWindow" owner:self options:nil] firstObject];
    view.containerView.layer.cornerRadius = 4.0f;
    if (self.selectedLocation && self.selectedLocation.horizontalAccuracy <= GOOD_ACCURACY_IN_METERS) {
        view.gpsQualityImageView.image = [UIImage imageNamed:@"ic_small_gps_good"];
        view.gpsQualityLabel.text = RiistaLocalizedString(@"GPSGood", nil);
    } else if (self.selectedLocation && self.selectedLocation.horizontalAccuracy <= AVERAGE_ACCURACY_IN_METERS) {
        view.gpsQualityImageView.image = [UIImage imageNamed:@"ic_small_gps_average"];
        view.gpsQualityLabel.text = RiistaLocalizedString(@"GPSAverage", nil);
    } else {
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

# pragma mark - PermitPageDelegate

- (void)permitSelected:(NSString*)permitNumber speciesCode:(NSInteger)speciesCode;
{
    self.selectedPermitNumber = permitNumber;
    [self speciesSelected:[[RiistaGameDatabase sharedInstance] speciesById:speciesCode]];

    [self updatePermitInfo];
}

# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == SPECIES_SELECTION) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            RiistaSpeciesSelectViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"speciesSelectController"];
            controller.delegate = self;
            controller.category = self.categoryList[buttonIndex];
            [self.navigationController pushViewController:controller animated:YES];
        }
    } else if (alertView.tag == CONFIRM_REMOVE_ENTRY) {
        if (buttonIndex == 1) { // "Yes/OK"
            [self onDeleteConfirmed];
        }
    }
}

#pragma mark - SpeciesSelectionDelegate

- (void)speciesSelected:(RiistaSpecies*)species
{
    self.species = species;
    self.speciesMandatoryMarkerLabel.hidden = YES;
    UIImage *speciesImage = [RiistaUtils loadSpeciesImage:species.speciesId];
    self.speciesImageView.image = speciesImage;
    self.speciesNameLabel.text = [RiistaUtils nameWithPreferredLanguage:species.name];
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

# pragma mark - KeyboardHandlerDelegate

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView*)textView
{
    [self updateTextViewHeight:textView];
}

- (void)updateTextViewHeight:(UITextView*)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    if (newSize.height > self.imageListViewHeightConstraint.constant) {
        self.imageListViewHeightConstraint.constant += (newSize.height - self.imageListViewHeightConstraint.constant);
    }

    self.contentViewHeightConstraint.constant = self.imageListView.frame.origin.y + self.imageListViewHeightConstraint.constant + TEXTVIEW_BOTTOM_PADDING;

    [self.backgroundImages.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;

    NSUInteger newLength = oldLength - rangeLength + replacementLength;

    return newLength <= MAX_AMOUNT_LENGTH || ([string rangeOfString: @"\n"].location != NSNotFound);
}

#pragma mark - RiistaDiaryImageManager

- (void)imageBrowserOpenStatusChanged:(BOOL)open
{
    self.browsingImages = open;
    if (open) {
        [((RiistaNavigationController*)self.navigationController) setRightBarItems:@[]];
    } else if (self.event && !self.editMode) {
        [self setupBarEditButton];
        [self updateTitle];
    }
}

- (void)RiistaDiaryImageManager:(RiistaDiaryImageManager*)manager selectedEntry:(DiaryEntryBase*)entry;
{
    if (self.event && [entry.objectID isEqual:self.event.objectID]) {
        return;
    }

    self.event = [[RiistaGameDatabase sharedInstance] diaryEntryWithObjectId:entry.objectID context:self.editContext];
    self.amountTextField.text = [self.event.amount stringValue];
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

@implementation RiistaMarkerInfoWindow
@end
