#import "RiistaPageViewController.h"
#import "UIColor+ApplicationColor.h"

@implementation RiistaPageViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor applicationColor:RiistaApplicationColorBackground];
}

- (void)refreshTabItem
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
}

@end
