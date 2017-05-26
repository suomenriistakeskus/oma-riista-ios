#import <UIKit/UIKit.h>

@protocol LoginDelegate

- (void)didLogin;

@end

@interface RiistaLoginViewController : UIViewController

@property (weak) id<LoginDelegate> delegate;

@end
