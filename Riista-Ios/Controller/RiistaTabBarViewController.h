#import <UIKit/UIKit.h>

#import "RiistaMyGameViewController.h"
#import "RiistaAnnouncementsViewController.h"
#import "RiistaSettingsViewController.h"

@interface RiistaTabBarViewController : UITabBarController <UITabBarControllerDelegate, UINavigationControllerDelegate>

- (void)logout;

@end
