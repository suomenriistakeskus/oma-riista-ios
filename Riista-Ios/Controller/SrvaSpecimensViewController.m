#import "SrvaSpecimensViewController.h"
#import "SrvaEntry.h"
#import "SrvaSpecimen.h"
#import "RiistaGameDatabase.h"
#import "RiistaUtils.h"
#import "RiistaSpecies.h"
#import "RiistaSpecimen.h"
#import "RiistaLocalization.h"
#import "RiistaMetadataManager.h"
#import "SrvaMetadata.h"
#import "RiistaValueListButton.h"
#import "ValueListViewController.h"
#import "RiistaNavigationController.h"

static NSString * const SPECIMEN_AGE_KEY = @"SpecimenAgeKey";

@interface SrvaSpecimenCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSelect;
@property (weak, nonatomic) IBOutlet RiistaValueListButton *ageSelect;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonWidthConstraint;

@end

@implementation SrvaSpecimenCell

@end

@interface SrvaSpecimensViewController () <ValueSelectionDelegate>

@property (strong, nonatomic) SrvaSpecimen *selectedSpecimen;
@property (strong, nonatomic) UIBarButtonItem *addButton;

@end

@implementation SrvaSpecimensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RiistaLanguageRefresh;

    [self updateTitle];
    [self configureButtons];
}

- (void)configureButtons
{
    UIImage *addImage = [UIImage imageNamed:@"ic_menu_add.png"];
    self.addButton = [[UIBarButtonItem alloc] initWithImage:addImage
                                        landscapeImagePhone:addImage
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(addSpecimen:)];
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController setRightBarItems:@[self.addButton]];

    [self.addButton setEnabled:self.editMode];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle: [NSString stringWithFormat:@"%@ (%lu)",
                                 [self speciesName],
                                 (unsigned long)[self.srva.specimens count]]];
}

- (void)addSpecimen:(id)sender
{
    if (self.srva.specimens.count < DiaryEntrySpecimenDetailsMax) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SrvaSpecimen" inManagedObjectContext:self.srva.managedObjectContext];
        SrvaSpecimen *newSpecimen = (SrvaSpecimen*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.srva.managedObjectContext];
        [self.srva addSpecimensObject:newSpecimen];

        [self reloadData];
        [self goToTableBottom];

        [self.delegate specimenCountChanged];
    }
}

- (void)reloadData
{
    [self.tableView reloadData];
    [self updateTitle];
}

- (void)goToTableBottom
{
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.srva.specimens.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (NSString*)speciesName
{
    if (self.srva.gameSpeciesCode != nil) {
        RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[self.srva.gameSpeciesCode integerValue]];
        if (species) {
            return [RiistaUtils nameWithPreferredLanguage:species.name];
        }
    }
    else if (self.srva.otherSpeciesDescription != nil) {
        return self.srva.otherSpeciesDescription;
    }
    return @"";
}

- (void)configureCell:(SrvaSpecimenCell*)cell item:(SrvaSpecimen*)specimen index:(NSInteger)rowIndex
{
    NSString* name = [self speciesName];
    cell.itemTitle.text = [NSString stringWithFormat:@"%@ %ld", name, (long)rowIndex + 1];

    if ([specimen.gender isEqualToString:SpecimenGenderFemale]) {
        [cell.genderSelect setSelectedSegmentIndex:0];
    }
    else if ([specimen.gender isEqualToString:SpecimenGenderMale]) {
        [cell.genderSelect setSelectedSegmentIndex:1];
    }
    else if ([specimen.gender isEqualToString:SpecimenGenderUnknown]) {
        [cell.genderSelect setSelectedSegmentIndex:2];
    }
    else {
        [cell.genderSelect setSelectedSegmentIndex:-1];
    }
    cell.genderSelect.enabled = self.editMode;
    cell.genderSelect.tag = rowIndex;
    [cell.genderSelect addTarget:self action:@selector(genderValueChanged:) forControlEvents:UIControlEventValueChanged];

    cell.ageSelect.titleText = RiistaLocalizedString(@"SpecimenAgeTitle", nil);
    cell.ageSelect.valueText = RiistaMappedValueString(specimen.age, nil);
    cell.ageSelect.enabled = self.editMode;
    cell.ageSelect.tag = rowIndex;
    [cell.ageSelect addTarget:self action:@selector(onAgeClick:) forControlEvents:UIControlEventTouchUpInside];

    cell.removeButton.hidden = !self.editMode;
    cell.removeButton.tag = rowIndex;
    [cell.removeButton addTarget:self action:@selector(removeSpecimenItem:) forControlEvents:UIControlEventTouchUpInside];

    cell.buttonWidthConstraint.constant = self.editMode ? 40: 0;
}

- (void)removeSpecimenItem:(UIButton*)sender
{
    if (self.srva.specimens.count <= 1) {
        return;
    }

    SrvaSpecimen *specimen = self.srva.specimens[sender.tag];
    [self.srva removeSpecimensObject:specimen];
    [specimen.managedObjectContext deleteObject:specimen];

    [self reloadData];
    [self.delegate specimenCountChanged];
}

- (void)genderValueChanged:(UISegmentedControl*)sender
{
    self.selectedSpecimen = self.srva.specimens[sender.tag];

    if (sender.selectedSegmentIndex == 0) {
        self.selectedSpecimen.gender = SpecimenGenderFemale;
    }
    else if (sender.selectedSegmentIndex == 1) {
        self.selectedSpecimen.gender = SpecimenGenderMale;
    }
    else if (sender.selectedSegmentIndex == 2) {
        self.selectedSpecimen.gender = SpecimenGenderUnknown;
    }
    [self reloadData];
}

- (void)onAgeClick:(RiistaValueListButton*)sender
{
    self.selectedSpecimen = self.srva.specimens[sender.tag];

    SrvaMetadata *metadata = [[RiistaMetadataManager sharedInstance] getSrvaMetadata];
    [self showValueSelect:SPECIMEN_AGE_KEY title:RiistaLocalizedString(@"SpecimenAgeTitle", nil) values:metadata.ages];
}

- (void)showValueSelect:(NSString*)key title:(NSString*)title values:(NSArray*)values;
{
    ValueListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"valueListController"];
    controller.fieldKey = key;
    controller.titlePrompt = title;
    controller.values = values;
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)valueSelectedForKey:(NSString*)key value:(NSString*)value
{
    if ([key isEqualToString:SPECIMEN_AGE_KEY]) {
        self.selectedSpecimen.age = value;
    }
    [self reloadData];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.srva.specimens.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    SrvaSpecimenCell *cell = (SrvaSpecimenCell*)[tableView dequeueReusableCellWithIdentifier:@"srvaSpecimenCell"];
    SrvaSpecimen *specimen = self.srva.specimens[indexPath.row];

    [self configureCell:cell item:specimen index:indexPath.row];

    [cell layoutIfNeeded];

    return cell;
}

@end
