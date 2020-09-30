#import <UIKit/UIKit.h>

@interface RiistaNavigationTitle : UIView
@property (weak, nonatomic) IBOutlet UIImageView *menuIcon;
@property (weak, nonatomic) IBOutlet UILabel *navTitle;
@property (weak, nonatomic) IBOutlet UILabel *navDescription;
@end

@interface RiistaNavigationController : UINavigationController

@property (assign, nonatomic) BOOL syncStatus;

- (void)changeTitle:(NSString*)title;
- (void)changeTitle:(NSString*)title withFont:(UIFont*)font;
- (void)setRightBarItems:(NSArray*)items;
- (void)setLeftBarItem:(UIBarButtonItem*)button;
- (UIViewController*)rootViewController;

@end
