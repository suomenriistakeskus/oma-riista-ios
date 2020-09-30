#import <UIKit/UIKit.h>
#import "RiistaUIViewController.h"
#import "RiistaNavigationController.h"

@protocol MapPageDelegate <NSObject>

- (void)locationSetManually:(CLLocationCoordinate2D)location;

@end

@interface RiistaMapViewController : RiistaUIViewController

@property (weak, nonatomic) id<MapPageDelegate> delegate;
@property (strong, nonatomic) CLLocation *location;
@property (assign, nonatomic) BOOL editMode;
@property (assign, nonatomic) BOOL hidePins;
@property (strong, nonatomic) NSString *titlePrimaryText;
@property (strong, nonatomic) RiistaNavigationController *riistaController;

@end
