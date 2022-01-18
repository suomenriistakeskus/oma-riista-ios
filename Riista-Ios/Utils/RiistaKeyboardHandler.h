#import <Foundation/Foundation.h>

@protocol RiistaKeyboardHandlerDelegate

- (void)hideKeyboard;

@end

@interface RiistaKeyboardHandler : NSObject

- (id)initWithView:(UIView*)view andBottomSpaceConstraint:(NSLayoutConstraint*)constraint;

@property (weak, nonatomic) id<RiistaKeyboardHandlerDelegate> delegate;
@property (assign, nonatomic) BOOL cancelTouchesInView;

@end
