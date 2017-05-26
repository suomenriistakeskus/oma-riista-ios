#import "Styles.h"
#import "UIColor+ApplicationColor.h"

NSInteger const RiistaRefreshPadding = 15;
NSInteger const RiistaRefreshImageSize = 32;

@implementation Styles

+ (void)styleButton:(UIButton*)button
{
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground]] forState:UIControlStateNormal];
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorButtonBackgroundHighlighted]] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorButtonBackgroundDisabled]] forState:UIControlStateDisabled];
    [self styleBaseButton:button];
}

+ (void)styleNegativeButton:(UIButton*)button
{
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorNegativeButtonBackground]] forState:UIControlStateNormal];
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorNegativeButtonBackgroundHighlighted]] forState:UIControlStateHighlighted];
    [self styleBaseButton:button];
}

+ (void)styleLinkButton:(UIButton*)button
{
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorLink]] forState:UIControlStateNormal];
    [button setBackgroundImage:[Styles imageWithColor:[UIColor applicationColor:RiistaApplicationColorLinkHighlighted]] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 3;
    button.clipsToBounds = YES;
}

+ (void)styleBaseButton:(UIButton*)button
{
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIFont *font = [UIFont boldSystemFontOfSize:15];
    [button.titleLabel setFont:font];
    button.layer.cornerRadius = 3;
    button.clipsToBounds = YES;
}

+ (void)styleButtonView:(UIView*)view highlighted:(BOOL)highlighted
{
    UIColor *color = highlighted ? [UIColor applicationColor:RiistaApplicationColorButtonBackgroundHighlighted] : [UIColor applicationColor:RiistaApplicationColorButtonBackground];
    view.layer.cornerRadius = 3;
    view.clipsToBounds = YES;
    view.backgroundColor = color;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
