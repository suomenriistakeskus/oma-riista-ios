#import "RiistaValueListReadonlyText.h"
#import "RiistaViewUtils.h"

#import "Oma_riista-Swift.h"

@implementation RiistaValueListReadonlyText

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

    [AppTheme.shared setupLabelFontWithLabel:self.titleTextLabel];
    [AppTheme.shared setupValueFontWithLabel:self.valueTextLabel];

    [self addSubview:self.view];
    [self.view constraintToSuperviewBounds];
}

@end
