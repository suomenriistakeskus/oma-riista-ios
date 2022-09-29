#import <UIKit/UIKit.h>
#import "RiistaUIViewController.h"

@protocol RiistaTabPage <NSObject>

- (void)refreshTabItem;

@end

// Base class for main navigation level views
@interface RiistaPageViewController : RiistaUIViewController <RiistaTabPage>

@end
