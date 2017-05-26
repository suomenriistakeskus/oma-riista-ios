#import <UIKit/UIKit.h>

@interface DetailsViewControllerBase : UIViewController

@property (assign, nonatomic) BOOL editMode;

- (void)refreshLocalizedTexts;

- (CGFloat)refreshViews;

- (void)disableUserControls;

@end
