#import <UIKit/UIKit.h>

@interface DetailsViewControllerBase : UIViewController

@property (assign, nonatomic) BOOL editMode;

- (void)refreshLocalizedTexts;

- (CGFloat)refreshViews;

- (void)refreshImage;

- (void)refreshDateTime:(NSString*)dateTimeString;

- (void)disableUserControls;

@end
