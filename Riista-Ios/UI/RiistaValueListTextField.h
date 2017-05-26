#import <UIKit/UIKit.h>

@interface RiistaValueListTextField : UIView<UITextViewDelegate>

@property(weak, nonatomic) id<UITextViewDelegate> delegate; //Doesn't forward all events

@property (weak, nonatomic) IBOutlet UIView *view;

@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) NSNumber *maxNumberValue;
@property (strong, nonatomic) NSNumber *maxTextLength;

@end
