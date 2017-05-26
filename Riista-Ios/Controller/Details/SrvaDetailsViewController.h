#import "DetailsViewControllerBase.h"

@class SrvaEntry;
@class SrvaDetailsViewController;

@protocol SrvaDetailsDelegate
@required

- (void)valuesUpdated:(DetailsViewControllerBase*)sender;

@end

@interface SrvaDetailsViewController : DetailsViewControllerBase

@property (strong, nonatomic) SrvaEntry *srva;
@property (weak, nonatomic) id <SrvaDetailsDelegate> delegate;
@property (strong, nonatomic) NSManagedObjectContext *editContext;

- (CGFloat)refreshViews;
- (void)saveValues;

@end
