#import "RiistaNavigationController.h"
#import "UIColor+ApplicationColor.h"
#import "Styles.h"
#import "RiistaLogGameViewController.h"

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
    [self setupNavigationBarStyle];
    [self styleBackButtons];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    [self addObserver:self forKeyPath:CONTROLLER_PROPERTY_ID options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setupNavigationBarStyle
{
    [self.navigationBar setBarTintColor:[UIColor applicationColor:RiistaApplicationColorNavigationBackground]];
    self.navigationBar.translucent = NO;
}

- (void)setTitle:(NSString *)title
{
    [self changeTitle:title];
}

- (void)changeTitle:(NSString*)title
{
    [self changeTitle:title withFont:[UIFont systemFontOfSize:15]];
}

- (void)changeTitle:(NSString*)title withFont:(UIFont*)font
{
    UINavigationItem *item = [[self.viewControllers lastObject] navigationItem ];
    RiistaNavigationTitle *titleView = [[[NSBundle mainBundle] loadNibNamed:@"RiistaNavigationTitleView" owner:self options:nil] firstObject];
    titleView.menuIcon.image = [UIImage imageNamed:@"ic_menu_logo"];
    titleView.navTitle.font = font;
    titleView.navTitle.text = title;
    CGFloat width = [title sizeWithAttributes:@{NSFontAttributeName:font}].width;
    titleView.frame = CGRectMake(titleView.frame.origin.x, 0, width + TITLEVIEW_ADDITIONAL_WIDTH, self.navigationBar.frame.size.height);
    item.titleView = titleView;
}

- (void)changeTitle:(NSString*)title andDescription:(NSString*)description
{
    UINavigationItem *item = [[self.viewControllers lastObject] navigationItem ];
    RiistaNavigationTitle *titleView = [[[NSBundle mainBundle] loadNibNamed:@"RiistaNavigationTitleView2" owner:self options:nil] firstObject];
    titleView.menuIcon.image = [UIImage imageNamed:@"ic_menu_logo"];
    titleView.navTitle.text = title;
    titleView.navDescription.text = description;
    CGFloat titleWidth = [title sizeWithAttributes:@{NSFontAttributeName:titleView.navTitle.font}].width;
    CGFloat descriptionWidth = [description sizeWithAttributes:@{NSFontAttributeName:titleView.navDescription.font}].width;
    CGFloat width = MAX(titleWidth, descriptionWidth);
    titleView.frame = CGRectMake(titleView.frame.origin.x, 0, width + TITLEVIEW_ADDITIONAL_WIDTH, self.navigationBar.frame.size.height);
    item.titleView = titleView;
}

- (void)setupCustomTitleView:(UIView*)titleView forNavigationItem:(UINavigationItem*)navigationItem
{
    navigationItem.titleView = titleView;
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
    [self setupNavigationBarStyle];
    [self willChangeValueForKey:@"viewControllers"];
    [super pushViewController:viewController animated:animated];
    [self didChangeValueForKey:@"viewControllers"];
    [self setRightBarItems:currentRightBarItems];
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    [self setupNavigationBarStyle];
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
    if([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientationsForThisContorller)])
    {
        return(NSInteger)[self.topViewController performSelector:@selector(supportedInterfaceOrientationsForThisContorller) withObject:nil];
    }
    else if ([self.topViewController isKindOfClass:NSClassFromString(@"CustomPhotoBrowser")]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    if([self.visibleViewController respondsToSelector:@selector(shouldAutorotateNow)])
    {
        BOOL autoRotate = (BOOL)[self.visibleViewController
                                 performSelector:@selector(shouldAutorotateNow)
                                 withObject:nil];
        return autoRotate;
    }
    else if ([self.visibleViewController isKindOfClass:NSClassFromString(@"CustomPhotoBrowser")]) {
        return YES;
    }
    return NO;
}

@end

@implementation RiistaNavigationTitle
@end
