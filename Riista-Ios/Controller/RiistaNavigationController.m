#import "RiistaNavigationController.h"
#import "Styles.h"
#import "RiistaLogGameViewController.h"
#import "Oma_riista-Swift.h"

NSInteger const TITLEVIEW_ADDITIONAL_WIDTH = 70;
static NSString *const CONTROLLER_PROPERTY_ID = @"viewControllers";

@interface RiistaNavigationController ()

@property (strong, nonatomic) UIView *titleView;
@property (strong, nonatomic) UIImageView *refreshImageView;

@end

@implementation RiistaNavigationController
{
    NSArray *currentRightBarItems;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        currentRightBarItems = @[];
        self.refreshImageView = [UIImageView new];
        self.refreshImageView.image = [UIImage imageNamed:@"ic_action_refresh.png"];
        self.refreshImageView.frame = CGRectMake(0, 0, RiistaRefreshImageSize, RiistaRefreshImageSize);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self styleBackButtons];
    [self addObserver:self forKeyPath:CONTROLLER_PROPERTY_ID options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setTitle:(NSString *)title
{
    [self changeTitle:title];
}

- (void)changeTitle:(NSString*)title
{
    [self changeTitle:title withFont:[UIFont systemFontOfSize:AppFont.NavigationBarTitle]];
}

- (void)changeTitle:(NSString*)title withFont:(UIFont*)font
{
    UINavigationItem *item = [[self.viewControllers lastObject] navigationItem ];
    RiistaNavigationTitle *titleView = [[[NSBundle mainBundle] loadNibNamed:@"RiistaNavigationTitleView" owner:self options:nil] firstObject];
    titleView.navTitle.font = font;
    titleView.navTitle.text = title;
    CGFloat width = [title sizeWithAttributes:@{NSFontAttributeName:font}].width;
    titleView.frame = CGRectMake(titleView.frame.origin.x, 0, width + TITLEVIEW_ADDITIONAL_WIDTH, self.navigationBar.frame.size.height);
    item.titleView = titleView;
}

- (void)setRightBarItems:(NSArray*)items
{
    NSArray *finalItems = items;
    UINavigationItem *item = [[self.viewControllers lastObject] navigationItem];
    if (self.syncStatus) {
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithCustomView:self.refreshImageView];
        finalItems = [items arrayByAddingObjectsFromArray:@[refreshButton]];
    }
    currentRightBarItems = items;
    item.rightBarButtonItems = finalItems;
}

- (void)setLeftBarItem:(UIBarButtonItem*)button
{
    UINavigationItem *item = [[self.viewControllers lastObject] navigationItem];
    item.leftBarButtonItem = button;
}

- (void)styleBackButtons
{
    for (UIViewController *controller in self.viewControllers) {
        controller.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:CONTROLLER_PROPERTY_ID]) {
        [self styleBackButtons];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated
{
    [self willChangeValueForKey:@"viewControllers"];
    [super pushViewController:viewController animated:animated];
    [self didChangeValueForKey:@"viewControllers"];
    [self setRightBarItems:currentRightBarItems];
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *controller = [super popViewControllerAnimated:animated];
    [self setRightBarItems:currentRightBarItems];
    return controller;
}

- (void)setViewControllers:(NSArray*)viewControllers animated:(BOOL)animated
{
    [self willChangeValueForKey:@"viewControllers"];
    [super setViewControllers:viewControllers animated:animated];
    [self didChangeValueForKey:@"viewControllers"];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:CONTROLLER_PROPERTY_ID];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSyncStatus:(BOOL)syncStatus
{
    _syncStatus = syncStatus;

    if (syncStatus) {
        CGFloat speed = 0.4f;
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * speed];
        rotationAnimation.duration = 0.5f;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = HUGE_VALF;
        [self.refreshImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    } else {
        [self.refreshImageView.layer removeAllAnimations];
    }
    [self setRightBarItems:currentRightBarItems];
}

- (UIViewController*)rootViewController
{
    UIViewController *controller = self.parentViewController;
    while ([controller isKindOfClass:[UINavigationController class]]) {
        controller = [controller parentViewController];
    }
    return controller;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([self.topViewController isKindOfClass:NSClassFromString(@"CustomPhotoBrowser")]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }

    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end

@implementation RiistaNavigationTitle
@end
