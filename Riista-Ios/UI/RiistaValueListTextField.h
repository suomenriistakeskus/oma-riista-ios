#import <UIKit/UIKit.h>
#import "Oma_riista-Swift.h"

@interface RiistaValueListTextField : UIView<UITextFieldDelegate>

@property(weak, nonatomic) id<UITextFieldDelegate> delegate; //Doesn't forward all events

@property (weak, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet MDCTextField *textField;

@property (strong, nonatomic) MDCTextInputControllerUnderline *inputController;

@property (strong, nonatomic) NSNumber *minNumberValue;
@property (strong, nonatomic) NSNumber *maxNumberValue;
@property (strong, nonatomic) NSNumber *maxTextLength;

@property (assign, nonatomic) BOOL nonNegativeIntNumberOnly;

@end
