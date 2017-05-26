#import "RiistaUIViewController.h"

@class Permit;

@protocol PermitPageDelegate <NSObject>

- (void)permitSelected:(NSString*)permitNumber speciesCode:(NSInteger)speciesCode;

@end

@interface RiistaPermitListViewController : RiistaUIViewController

@property (weak, nonatomic) id<PermitPageDelegate> delegate;
@property (strong, nonatomic) NSString *inputValue;

@end
