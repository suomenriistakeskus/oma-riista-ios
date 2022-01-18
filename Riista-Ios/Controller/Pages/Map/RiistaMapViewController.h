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

// External id override

@property (assign, nonatomic) BOOL overrideAreaExternalId;
// An external id of the area to be displayed instead of one set by the settings
 @property (strong, nonatomic) NSString *overriddenAreaExternalId;
// Should area colors be inverted for the overridden area?
 @property (assign, nonatomic) BOOL overriddenAreaInvertColors;

@end
