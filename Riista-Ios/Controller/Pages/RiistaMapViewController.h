#import <UIKit/UIKit.h>
#import "RiistaUIViewController.h"

@protocol MapPageDelegate <NSObject>

- (void)locationSetManually:(CLLocationCoordinate2D)location;

@end

@interface RiistaMapViewController : RiistaUIViewController

@property (weak, nonatomic) id<MapPageDelegate> delegate;
@property (strong, nonatomic) CLLocation *location;
@property (assign, nonatomic) BOOL editMode;
@property (strong, nonatomic) NSString *titlePrimaryText;

@end
