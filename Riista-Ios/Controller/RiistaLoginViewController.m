#import "RiistaLoginViewController.h"
#import "Styles.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaSessionManager.h"
#import "RiistaNetworkManager.h"
#import "RiistaLocalization.h"

@interface RiistaLoginViewController () <UITextFieldDelegate, KeyboardHandlerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *loginlabel;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *loginbutton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;
@end

@implementation RiistaLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.delegate = self;
    
    _username.keyboardType = UIKeyboardTypeEmailAddress;
    [_username resignFirstResponder];
    _username.delegate = self;
    _password.delegate = self;
    [Styles styleButton:_loginbutton];
    [_loginbutton addTarget:self action:@selector(loginButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;
    _loginlabel.text = RiistaLocalizedString(@"LoginText", nil);
    _username.placeholder = RiistaLocalizedString(@"Username", nil);
    _password.placeholder = RiistaLocalizedString(@"Password", nil);
    [_loginbutton setTitle:RiistaLocalizedString(@"Login", nil) forState:UIControlStateNormal];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	[theTextField resignFirstResponder];
	return YES;
}

- (void)loginButtonClick:(id)sender
{
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    RiistaNetworkManager *manager = [RiistaNetworkManager sharedInstance];
    __weak RiistaLoginViewController *weakSelf = self;
    [manager login:username password:password completion:^(NSError *error) {
        if (!error) {
            if (weakSelf.delegate) {
                RiistaCredentials *credentials = [RiistaCredentials new];
                credentials.username = username;
                credentials.password = password;
                [[RiistaSessionManager sharedInstance] storeCredentials:credentials];
                [weakSelf.delegate didLogin];
            }
        } else {
            UIAlertView *alertView = [UIAlertView new];
            alertView.title = RiistaLocalizedString(@"loginFailed", nil);
            if (error.code == LOGIN_NETWORK_UNREACHABLE || error.code ==  LOGIN_TIMEOUT) {
                alertView.message = RiistaLocalizedString(@"loginConnectFailed", nil);
            } else if (error.code == LOGIN_INCORRECT_CREDENTIALS) {
                alertView.message = RiistaLocalizedString(@"loginIncorrectCredentials", nil);
            } else if (error.code == LOGIN_OUTDATED_VERSION) {
                alertView.message = RiistaLocalizedString(@"loginOutdatedVersion", nil);
            }
            [alertView addButtonWithTitle:RiistaLocalizedString(@"OK", nil)];
            [alertView show];
        }
    }];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

@end
