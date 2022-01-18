#import "DetailsViewControllerBase.h"

@interface DetailsViewControllerBase ()

@end

@implementation DetailsViewControllerBase

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshLocalizedTexts
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
}

- (CGFloat)refreshViews
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
    return 0.0f;
}

- (void)refreshImage
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
}

- (void)refreshDateTime:(NSString*)dateTimeString
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
}

- (void)disableUserControls
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
}

@end
