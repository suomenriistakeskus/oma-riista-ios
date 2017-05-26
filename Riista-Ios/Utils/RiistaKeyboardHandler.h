#import <Foundation/Foundation.h>

@protocol KeyboardHandlerDelegate

- (void)hideKeyboard;

@end

@interface RiistaKeyboardHandler : NSObject

- (id)initWithView:(UIView*)view andBottomSpaceConstraint:(NSLayoutConstraint*)constraint;

@property (weak, nonatomic) id<KeyboardHandlerDelegate> delegate;

@end
