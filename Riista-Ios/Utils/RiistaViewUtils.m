#import "RiistaViewUtils.h"
#import "UIColor+ApplicationColor.h"
#import "M13Checkbox.h"

@implementation RiistaViewUtils

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
