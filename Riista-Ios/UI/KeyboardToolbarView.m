#import "KeyboardToolbarView.h"
#import "RiistaLocalization.h"

@interface TextFieldInputBarButtonItem : UIBarButtonItem

@property (weak, nonatomic) UITextField *inputField;

@end

@interface TextViewInputBarButtonItem : UIBarButtonItem

@property (weak, nonatomic) UITextView *inputField;

@end

@implementation KeyboardToolbarView

+ (id)textFieldDoneToolbarView:(UITextField*)field
{
    KeyboardToolbarView *toolbar = [[KeyboardToolbarView alloc] init];
    toolbar.barStyle = UIBarStyleDefault;

    TextFieldInputBarButtonItem *doneButton = [[TextFieldInputBarButtonItem alloc] initWithTitle:RiistaLocalizedString(@"KeyboardDone", nil)
                                                                                           style:UIBarButtonItemStyleDone
                                                                                          target:toolbar
                                                                                          action:@selector(textFieldDonePressed:)];
    doneButton.inputField = field;

    UIBarButtonItem *flexLeftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:nil];

    UIBarButtonItem *fixedRightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:nil
                                                                                     action:nil];
    fixedRightSpace.width = 10.0f;

    [toolbar setItems:[NSArray arrayWithObjects:flexLeftSpace, doneButton, fixedRightSpace, nil]];
    [toolbar sizeToFit];

    return toolbar;
}

+ (id)textViewDoneToolbarView:(UITextView*)field
{
    KeyboardToolbarView *toolbar = [[KeyboardToolbarView alloc] init];
    toolbar.barStyle = UIBarStyleDefault;

    TextViewInputBarButtonItem *doneButton = [[TextViewInputBarButtonItem alloc] initWithTitle:RiistaLocalizedString(@"KeyboardDone", nil)
                                                                                        style:UIBarButtonItemStyleDone
                                                                                        target:toolbar
                                                                                        action:@selector(textViewDonePressed:)];
    doneButton.inputField = field;

    UIBarButtonItem *flexLeftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];

    UIBarButtonItem *fixedRightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:nil
                                                                                     action:nil];
    fixedRightSpace.width = 10.0f;

    [toolbar setItems:[NSArray arrayWithObjects:flexLeftSpace, doneButton, fixedRightSpace, nil]];
    [toolbar sizeToFit];

    return toolbar;
}

- (IBAction)textFieldDonePressed:(id)sender
{
    if ([sender isKindOfClass:NSClassFromString(@"TextFieldInputBarButtonItem")])
    {
        TextFieldInputBarButtonItem *button = (TextFieldInputBarButtonItem*)sender;
        [button.inputField endEditing:YES];
    }
}

- (IBAction)textViewDonePressed:(id)sender
{
    if ([sender isKindOfClass:NSClassFromString(@"TextViewInputBarButtonItem")])
    {
        TextViewInputBarButtonItem *button = (TextViewInputBarButtonItem*)sender;
        [button.inputField endEditing:YES];
    }
}

@end

@implementation TextFieldInputBarButtonItem
@end

@implementation TextViewInputBarButtonItem
@end
