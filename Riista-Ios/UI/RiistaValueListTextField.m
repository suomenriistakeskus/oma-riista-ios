#import "RiistaValueListTextField.h"
#import "RiistaViewUtils.h"
#import "RiistaUtils.h"
#import "KeyboardToolbarView.h"

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
    [RiistaViewUtils addTopAndBottomBorders:self.view];
    [RiistaViewUtils setTextViewStyle:self.textView];

    self.textView.delegate = self;
    self.textView.keyboardType = UIKeyboardTypeDecimalPad;

    self.maxTextLength = [NSNumber numberWithInteger:255];

    [self addSubview:self.view];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Close keyboard on return key
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }

    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];

    if (self.maxTextLength != nil) {
        if (newString.length > [self.maxTextLength integerValue]) {
            return NO;
        }
    }

    if (self.maxNumberValue != nil) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.locale = [NSLocale currentLocale];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;

        NSNumber *result = [formatter numberFromString:newString];
        if ([result doubleValue] > [self.maxNumberValue doubleValue] || [result doubleValue] < 0.0) {
            return NO;
        }
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.delegate) {
        [self.delegate textViewDidEndEditing:textView];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView selectAll:nil];
    });
}

@end
