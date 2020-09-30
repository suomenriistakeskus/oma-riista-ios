#import "DetailsViewControllerBase.h"
#import "DiaryImage.h"

@class SrvaEntry;
@class SrvaDetailsViewController;

@protocol SrvaDetailsDelegate
@required

- (void)showDateTimePicker;
- (void)valuesUpdated:(DetailsViewControllerBase*)sender;

@end

@interface SrvaDetailsViewController : DetailsViewControllerBase

@property (strong, nonatomic) DiaryImage *diaryImage;

@property (strong, nonatomic) SrvaEntry *srva;
@property (weak, nonatomic) id <SrvaDetailsDelegate> delegate;
@property (strong, nonatomic) NSManagedObjectContext *editContext;

- (void)saveValues;

@end
