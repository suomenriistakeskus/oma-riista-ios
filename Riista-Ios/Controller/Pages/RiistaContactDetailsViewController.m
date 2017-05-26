#import <MessageUI/MessageUI.h>
#import "RiistaContactDetailsViewController.h"
#import "RiistaHeaderLabel.h"
#import "RiistaLocalization.h"
#import "Styles.h"

@interface RiistaContactDetailsViewController () <MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet RiistaHeaderLabel *customerServiceLabel;
@property (weak, nonatomic) IBOutlet UIView *customerServiceView;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *customerServiceTimesLabel;
@property (weak, nonatomic) IBOutlet RiistaHeaderLabel *customerSupportLabel;
@property (weak, nonatomic) IBOutlet UIView *customerSupportView;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailAddressLabel;

@property (strong, nonatomic) UIAlertView *dialAlertView;

@end

NSString *const customerServicePhoneNumber = @"029 431 2111";
NSString *const customerSupportEmail = @"oma@riista.fi";

@implementation RiistaContactDetailsViewController

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"MenuContactDetails", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _phoneNumberLabel.text = customerServicePhoneNumber;
    _emailAddressLabel.text = customerSupportEmail;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    _customerServiceTimesLabel.text = [NSString stringWithFormat:RiistaLocalizedString(@"CustomerServiceTimesTemplate", nil), @"12", @"16"];
    [self setupCustomerServiceView];
    [self setupCustomerSupportView];

    [self pageSelected];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)dealloc
{
    if (self.dialAlertView) {
        self.dialAlertView.delegate = nil;
        [self.dialAlertView dismissWithClickedButtonIndex:self.dialAlertView.cancelButtonIndex animated:YES];
    }
}

- (void)setupCustomerServiceView
{
    [Styles styleButtonView:self.customerServiceView highlighted:NO];
    self.customerServiceLabel.text = RiistaLocalizedString(@"CustomerService", nil);
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openDialer:)];
    tapRecognizer.delegate = self;
    [self.customerServiceView addGestureRecognizer:tapRecognizer];
}

- (void)openDialer:(id)sender
{
    self.dialAlertView = [[UIAlertView alloc] init];
    self.dialAlertView.delegate = self;
    self.dialAlertView.message = RiistaLocalizedString(@"MakeCallMessage", nil);
    [self.dialAlertView addButtonWithTitle:RiistaLocalizedString(@"MakeCall", nil)];
    [self.dialAlertView addButtonWithTitle:RiistaLocalizedString(@"CancelRemove", nil)];
    self.dialAlertView.cancelButtonIndex = 1;
    [self.dialAlertView show];
}

- (void)setupCustomerSupportView
{
    [Styles styleButtonView:self.customerSupportView highlighted:NO];
    self.customerSupportLabel.text = RiistaLocalizedString(@"SupportAndFeedback", nil);
    self.emailLabel.text = RiistaLocalizedString(@"Email", nil);
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openEmailComposer:)];
    tapRecognizer.delegate = self;
    [self.customerSupportView addGestureRecognizer:tapRecognizer];
}

- (void)openEmailComposer:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeViewController = [MFMailComposeViewController new];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:@[customerSupportEmail]];
        
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
        
        NSString *emailBodyTemplate = [NSString stringWithFormat:RiistaLocalizedString(@"EmailTemplate", nil), build, [[UIDevice currentDevice] systemVersion]];
        [composeViewController setSubject:RiistaLocalizedString(@"EmailTitle", nil)];
        [composeViewController setMessageBody:emailBodyTemplate isHTML:NO];
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pageSelected
{
    UIViewController *vc = self.navigationController;
    if ([vc isKindOfClass:NSClassFromString(@"UIMoreNavigationController")]) {
        vc.parentViewController.navigationController.title = RiistaLocalizedString(@"ContactDetails", nil);
    }
    else
    {
        self.navigationController.title = RiistaLocalizedString(@"ContactDetails", nil);
    }
}

- (void)handleTouches:(NSSet*)touches highlight:(BOOL)highlight
{
    for(UITouch* touch in touches) {
        if ([touch view] == self.customerServiceView) {
            [Styles styleButtonView:[touch view] highlighted:highlight];
        } else if ([touch view] == self.customerSupportView) {
            [Styles styleButtonView:[touch view] highlighted:highlight];
        }
    }
}

#pragma mark - UIGestureRecognized

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches highlight:YES];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches highlight:NO];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches highlight:NO];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSString *phoneNumber = [customerServicePhoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]]];
    }
}

@end
