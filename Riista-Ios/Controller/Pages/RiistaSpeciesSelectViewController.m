#import "RiistaSpeciesSelectViewController.h"
#import "RiistaGameDatabase.h"
#import "RiistaSpeciesCategory.h"
#import "RiistaSpecies.h"
#import "RiistaUtils.h"
#import "RiistaLocalization.h"
#import "RiistaNavigationController.h"

@interface RiistaSpeciesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *speciesImageView;
@property (weak, nonatomic) IBOutlet UILabel *speciesNameLabel;

@end

@interface RiistaSpeciesSelectViewController ()

@property (strong, nonatomic) NSArray *species;

@end

@implementation RiistaSpeciesSelectViewController

- (void)viewDidLoad
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController setRightBarItems:nil];

    if (self.values) {
        NSMutableArray *temp = [NSMutableArray arrayWithArray:self.values];
        if ([self.showOther boolValue]) {
            RiistaSpecies *other = [RiistaSpecies new];
            other.speciesId = -1;
            [temp addObject:other];
        }
        self.species = [temp copy];
    }
    else {
        NSLocale *sortLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"fi_FI"];

        NSMutableArray *speciesList = [[[RiistaGameDatabase sharedInstance] speciesListWithCategoryId:self.category.categoryId] mutableCopy];
        self.species = [speciesList sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *name = [RiistaUtils nameWithPreferredLanguage:((RiistaSpecies*)a).name];
            NSString *name2 = [RiistaUtils nameWithPreferredLanguage:((RiistaSpecies*)b).name];
            return [name compare:name2
                         options:NSCaseInsensitiveSearch
                           range:NSMakeRange(0, [name length])
                          locale:sortLocale];
        }];
        [navController changeTitle:[NSString stringWithFormat:@"%@", [RiistaUtils  nameWithPreferredLanguage:self.category.name]]];
    }

    [super viewDidLoad];
}

#pragma mark UITableViewDataSource methods


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.species.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    RiistaSpeciesCell *cell = (RiistaSpeciesCell*)[tableView dequeueReusableCellWithIdentifier:@"speciesCell"];
    RiistaSpecies *species = self.species[indexPath.row];

    if (species.speciesId == -1) {
        //Other
        cell.speciesImageView.image = [[UIImage imageNamed:@"ic_question_mark_green.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.speciesImageView.tintColor = [UIColor blackColor];
        cell.speciesNameLabel.text = RiistaLocalizedString(@"SrvaOtherSpeciesDescription", nil);
    }
    else {
        cell.speciesImageView.image = [RiistaUtils loadSpeciesImage:species.speciesId];
        cell.speciesNameLabel.text = [RiistaUtils nameWithPreferredLanguage:species.name];
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.delegate) {
        [self.delegate speciesSelected:self.species[indexPath.row]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}

@end

@implementation RiistaSpeciesCell
@end
