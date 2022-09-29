#import <Foundation/Foundation.h>

@interface Styles : NSObject

+ (void)styleButton:(UIButton*)button;
+ (void)styleNegativeButton:(UIButton*)button;
+ (void)styleLinkButton:(UIButton*)button;
+ (void)styleButtonView:(UIView*)view highlighted:(BOOL)highlighted;
+ (void)styleMapButton:(UIButton*)button;

@end
