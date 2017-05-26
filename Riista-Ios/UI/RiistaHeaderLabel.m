#import "RiistaHeaderLabel.h"

@implementation RiistaHeaderLabel

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setFont:[UIFont boldSystemFontOfSize:13]];
    }
    return self;
}

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.borderColor = [UIColor darkGrayColor].CGColor;
    bottomBorder.borderWidth = 1;
    bottomBorder.frame = CGRectMake(-1, self.layer.frame.size.height-1, self.layer.frame.size.width, 1);
    [bottomBorder setBorderColor:[UIColor blackColor].CGColor];
    [self.layer addSublayer:bottomBorder];
}

- (void)setText:(NSString*)text
{
    [super setText:[text uppercaseString]];
}

@end
