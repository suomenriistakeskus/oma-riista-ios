#import "RiistaValueListButton.h"
#import "RiistaViewUtils.h"
#import "RiistaUtils.h"

#import "Oma_riista-Swift.h"

@interface RiistaValueListButton ()

@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueTextLabel;

@end

@implementation RiistaValueListButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self initializeView];

        return self;
    }

    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initializeView];

        return self;
    }

    return nil;
}

- (void)initializeView
{
    self.view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [self addSubview:self.view];

    [self.view constraintToSuperviewBounds];
    [self.titleTextLabel configureCompatFor:FontUsageLabel];
    [self.valueTextLabel configureCompatFor:FontUsageInputValue];

    [self setBackgroundImage:[RiistaUtils imageWithColor:[UIColor applicationColor:GreyLight] width:1 height:1]
                    forState:UIControlStateHighlighted];
}

- (void)setTitleText:(NSString *)titleText
{
    self.titleTextLabel.text = titleText;
}

- (void)setValueText:(NSString *)valueText
{
    self.valueTextLabel.text = valueText;
}

@end
