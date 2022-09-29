#import "RiistaValueListTextField.h"
#import "RiistaViewUtils.h"
#import "RiistaUtils.h"
#import "KeyboardToolbarView.h"

#import "Oma_riista-Swift.h"

@implementation RiistaValueListTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self initializeView:frame];

        return self;
    }

    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializeView:CGRectZero];

        return self;
    }
    
    return nil;
}

- (void)initializeView:(CGRect)frame
{
    self.view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];

    if (frame.size.width > 0 && frame.size.height > 0) {
        //Make views the same size so border lines will be placed correctly
        frame.origin = CGPointZero;
        self.view.frame = frame;
    }

    [self.titleTextLabel configureCompatFor:FontUsageLabel];

    [self.textField configureFor:FontUsageInputValue];
    self.textField.labelBehavior = MDCTextControlLabelBehaviorDisappears;
    self.textField.delegate = self;
    self.textField.keyboardType = UIKeyboardTypeDecimalPad;

    self.maxTextLength = [NSNumber numberWithInteger:255];

    [self addSubview:self.view];
    [self.view constraintToSuperviewBounds];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text
{
    // Close keyboard on return key
    if ([text isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }

    // Need to apply replacement to original string and validate the whole input instead of just changed part
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:text];

    if (self.maxTextLength != nil) {
        if (newString.length > [self.maxTextLength integerValue]) {
            return NO;
        }
    }

    if (self.nonNegativeIntNumberOnly && ![newString isAllDigitsOrEmpty]) {
        return NO;
    }

    if ([newString length] > 0 && (self.minNumberValue != nil || self.maxNumberValue != nil)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.locale = [NSLocale currentLocale];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;

        NSNumber *result = [formatter numberFromString:newString];
        if (self.maxNumberValue != nil &&
            ([result doubleValue] > [self.maxNumberValue doubleValue] || [result doubleValue] < 0.0)) {

            return NO;
        }

        if (self.minNumberValue != nil && [result doubleValue] < [self.minNumberValue doubleValue]) {
            return NO;
        }
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.delegate) {
        [self.delegate textFieldDidEndEditing:textField];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [textField selectAll:nil];
    });
}

@end
