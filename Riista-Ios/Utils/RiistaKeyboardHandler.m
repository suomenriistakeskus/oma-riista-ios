#import "RiistaKeyboardHandler.h"

@interface RiistaKeyboardHandler () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) NSLayoutConstraint *bottomPaneBottomSpace;
@property (strong, nonatomic) UITapGestureRecognizer *recognizer;

@end

@implementation RiistaKeyboardHandler

- (id)initWithView:(UIView*)view andBottomSpaceConstraint:(NSLayoutConstraint*)constraint
{
    self = [super init];
    if (self) {
        _contentView = view;
        _recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
        _recognizer.cancelsTouchesInView = NO;
        [_contentView addGestureRecognizer:_recognizer];

        _bottomPaneBottomSpace = constraint;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setCancelTouchesInView:(BOOL)cancelTouchesInView
{
    _recognizer.cancelsTouchesInView = cancelTouchesInView;
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.contentView convertRect:keyboardRect fromView:nil];
    
    _bottomPaneBottomSpace.constant = (keyboardRect.size.height);
    
    double animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    _bottomPaneBottomSpace.constant = 0;
    
    double animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)tapGesture:(id)sender
{
    if (self.delegate) {
        [self.delegate hideKeyboard];
    }
}

@end
