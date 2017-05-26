#import <UIKit/UIKit.h>

@class SrvaSpecimen;
@class SrvaEntry;

@protocol SrvaSpecimensUpdatedDelegate
- (void)specimenCountChanged;
@end

@interface SrvaSpecimensViewController : UITableViewController

@property (weak, nonatomic) id<SrvaSpecimensUpdatedDelegate> delegate;
@property (strong, nonatomic) NSManagedObjectContext *editContext;
@property (assign, nonatomic) BOOL editMode;
@property (strong, nonatomic) SrvaEntry *srva;

@end
