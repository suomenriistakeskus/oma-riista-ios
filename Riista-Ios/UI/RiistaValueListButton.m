#import "RiistaValueListButton.h"
#import "RiistaViewUtils.h"
#import "RiistaUtils.h"

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
    [RiistaViewUtils addTopAndBottomBorders:self.view];
    [self addSubview:self.view];

    // FIXME: Pressed hilight is not working
    [self setBackgroundImage:[RiistaUtils imageWithColor:[UIColor colorWithRed:123 green:123 blue:123 alpha:1] width:1 height:1] forState:UIControlStateHighlighted];
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
