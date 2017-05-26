#import <UIKit/UIKit.h>

@class RiistaLogGameViewController;
@class RiistaSpeciesCategory;
@class RiistaSpecies;

@protocol SpeciesSelectionDelegate

- (void)speciesSelected:(RiistaSpecies*)species;

@end

@interface RiistaSpeciesSelectViewController : UITableViewController

@property (weak, nonatomic) id<SpeciesSelectionDelegate> delegate;
@property (strong, nonatomic) RiistaSpeciesCategory *category;
@property (strong, nonatomic) NSArray<RiistaSpecies*> *values;
@property (copy, nonatomic) NSNumber *showOther;

@end
