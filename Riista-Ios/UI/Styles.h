#import <Foundation/Foundation.h>

extern NSInteger const RiistaRefreshPadding;
extern NSInteger const RiistaRefreshImageSize;

@interface Styles : NSObject

+ (void)styleButton:(UIButton*)button;
+ (void)styleNegativeButton:(UIButton*)button;
+ (void)styleLinkButton:(UIButton*)button;
+ (void)styleButtonView:(UIView*)view highlighted:(BOOL)highlighted;
+ (void)styleMapButton:(UIButton*)button;

@end
