#import "RiistaLoginViewController.h"
#import "Styles.h"
#import "RiistaKeyboardHandler.h"
#import "RiistaSessionManager.h"
#import "RiistaNetworkManager.h"
#import "RiistaLocalization.h"

#import "Oma_riista-Swift.h"

@interface RiistaLoginViewController () <UITextFieldDelegate, KeyboardHandlerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *loginlabel;
@property (weak, nonatomic) IBOutlet MDCTextField *username;
@property (weak, nonatomic) IBOutlet MDCTextField *password;
@property (weak, nonatomic) IBOutlet MDCButton *loginbutton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPaneBottomSpace;

@property (strong, nonatomic) RiistaKeyboardHandler *keyboardHandler;

@end

@implementation RiistaLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.keyboardHandler = [[RiistaKeyboardHandler alloc] initWithView:self.view andBottomSpaceConstraint:self.bottomPaneBottomSpace];
    self.keyboardHandler.cancelTouchesInView = YES;
    self.keyboardHandler.delegate = self;
    
    _username.keyboardType = UIKeyboardTypeEmailAddress;
    _username.returnKeyType = UIReturnKeyNext;
    [_username resignFirstResponder];
    _username.delegate = self;

    _password.returnKeyType = UIReturnKeyDone;
    _password.delegate = self;

    [AppTheme.shared setupPrimaryButtonThemeWithButton:_loginbutton];
    [_loginbutton addTarget:self action:@selector(loginButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    RiistaLanguageRefresh;

    [AppTheme.shared setupValueFontWithTextField:_username];
    [AppTheme.shared setupValueFontWithTextField:_password];


    _loginlabel.text = RiistaLocalizedString(@"LoginText", nil);
    _username.placeholder = RiistaLocalizedString(@"Username", nil);
    _password.placeholder = RiistaLocalizedString(@"Password", nil);

    [_loginbutton setTitle:RiistaLocalizedString(@"Login", nil) forState:UIControlStateNormal];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == _username) {
        [_password becomeFirstResponder];
    } else if (textField == _password) {
        [textField resignFirstResponder];
        [self login];
    }
    return textField == _password;
}

- (void)loginButtonClick:(id)sender
{
    [_username resignFirstResponder];
    [_password resignFirstResponder];
    [self login];
}

- (void)login
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
            MDCAlertController *alertController =
            [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"loginFailed", nil)
                                                 message:nil];

            if (error.code == LOGIN_NETWORK_UNREACHABLE || error.code ==  LOGIN_TIMEOUT) {
                alertController.message = RiistaLocalizedString(@"loginConnectFailed", nil);
            } else if (error.code == LOGIN_INCORRECT_CREDENTIALS) {
                alertController.message = RiistaLocalizedString(@"loginIncorrectCredentials", nil);
            } else if (error.code == LOGIN_OUTDATED_VERSION) {
                alertController.message = RiistaLocalizedString(@"loginOutdatedVersion", nil);
            }

            MDCAlertAction *alertAction = [MDCAlertAction actionWithTitle:RiistaLocalizedString(@"OK", nil)
                                                                  handler:^(MDCAlertAction *action) {
                // Do nothing
            }];

            [alertController addAction:alertAction];

            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

@end
