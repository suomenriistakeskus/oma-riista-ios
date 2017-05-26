#import <UIKit/UIKit.h>

@interface RiistaValueListButton : UIButton

@property (weak, nonatomic) IBOutlet UIView *view;

@property (strong, nonatomic) NSString *titleText;
@property (strong, nonatomic) NSString *valueText;

@end
