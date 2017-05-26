#import <UIKit/UIKit.h>
#import "RiistaUIViewController.h"

@class DiaryEntry;
@class RiistaSpecies;

@interface RiistaLogGameViewController : RiistaUIViewController

/**
 * Used to indicate event that is being edited
 */
@property (assign, nonatomic) NSManagedObjectID *eventId;
@property (strong, nonatomic) RiistaSpecies *species;

- (void)speciesSelected:(RiistaSpecies*)species;

@end
