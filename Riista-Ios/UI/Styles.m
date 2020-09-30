#import "Styles.h"
#import "UIColor+ApplicationColor.h"
#import "Oma_riista-Swift.h"

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
    UIFont *font = [UIFont boldSystemFontOfSize:AppFont.ButtonMedium];
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

+ (void)styleMapButton:(UIButton*)button
{
    UIColor *highlighted = [UIColor colorWithWhite:0.5 alpha:0.8];
    [button setBackgroundImage:[Styles imageWithColor:highlighted] forState:UIControlStateHighlighted];

    UIColor *selected = [UIColor colorWithRed:0.25f green:1.0f blue:0.25f alpha:0.8];
    [button setBackgroundImage:[Styles imageWithColor:selected] forState:UIControlStateSelected];

    button.layer.cornerRadius = 10;
    button.layer.borderColor = [[UIColor blackColor] CGColor];
    button.layer.borderWidth = 1;

    button.clipsToBounds = YES;
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
