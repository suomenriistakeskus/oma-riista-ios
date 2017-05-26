#import "RiistaViewUtils.h"
#import "UIColor+ApplicationColor.h"
#import "M13Checkbox.h"

@implementation RiistaViewUtils

+ (void)addTopAndBottomBorders:(UIView*)view
{
    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, 1.f/[UIScreen mainScreen].scale)];
    topBorder.backgroundColor = [UIColor lightGrayColor];

    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, view.frame.size.height - .5f, view.frame.size.width, 1.f/[UIScreen mainScreen].scale)];
    bottomBorder.backgroundColor = [UIColor lightGrayColor];

    [view addSubview:topBorder];
    [view addSubview:bottomBorder];
}

+ (void)setCheckboxStyle:(M13Checkbox*)checkBox
{
    [checkBox setStrokeColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [checkBox setCheckColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground]];
}

+ (void)setTextViewStyle:(UIView*)textView
{
    [[textView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[textView layer] setBorderWidth:0.5];
    [[textView layer] setCornerRadius:5];
}

@end
