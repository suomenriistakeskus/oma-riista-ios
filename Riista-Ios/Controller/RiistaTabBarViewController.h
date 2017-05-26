#import <UIKit/UIKit.h>

#import "RiistaMyGameViewController.h"
#import "RiistaGameLogViewController.h"
#import "RiistaMyDetailsViewController.h"
#import "RiistaAnnouncementsViewController.h"
#import "RiistaContactDetailsViewController.h"
#import "RiistaSettingsViewController.h"

@interface RiistaTabBarViewController : UITabBarController <UITabBarControllerDelegate, UINavigationControllerDelegate>

- (void)logout;

@end
