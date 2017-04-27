//
// Please report any problems with this app template to contact@estimote.com
//

#import "SignInViewController.h"
@import Firebase;

@interface SignInViewController ()
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnSignIn;
@property(strong, nonatomic) FIRAuthStateDidChangeListenerHandle handle;
@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _txtPassword.delegate = self;
    _txtEmail.delegate = self;
    // Do any additional setup after loading the view, typically from a nib.
//    if let _ = FIRAuth.auth()?.currentUser {
//        self.signIn()
//    }
    if ([FIRAuth auth].currentUser)  {
        [self goToMainView];
    }
//    [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"EMAIL"];
//    [[NSUserDefaults standardUserDefaults] setObject:_txtPassword.text forKey:@"PASS"];
     [self autoLogin];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewWillDisappear:(BOOL)animated
{
     [super viewWillDisappear:animated];
    [[FIRAuth auth] removeAuthStateDidChangeListener:_handle];
}
- (IBAction)forgotPasswordClick:(id)sender {
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Reset password"
                                  message:@"Enter your email"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   NSString * email = alert.textFields[0].text;
                                                   if (!email) {
                                                       return;
                                                   }
                                                    [[FIRAuth auth] sendPasswordResetWithEmail:email completion:^(NSError * _Nullable error) {
                                                        if (error) {
                                                            FIRAuthErrorCode err = (FIRAuthErrorCode) error.code;
    
                                                            switch (err) {
                                                                case FIRAuthErrorCodeUserNotFound:
                                                                         [self showAlert:@"User account not found. Try registering"];
                                                                   
                                                                    break;
                                                                default:
                                                                        [self showAlert: [NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
                                                                    break;
                                                            }
                                                        }else
                                                        {
                                                          [self showAlert: [NSString stringWithFormat:@"You'll receive an email shortly to reset your password"]];
                                                        }
                                                    }];
                                                   
                                               }];
    
    [alert addAction:ok];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Username";
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
    

}
- (void) autoLogin
{
    NSString * email = [[NSUserDefaults standardUserDefaults] stringForKey:@"EMAIL"];
    NSString * pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"PASS"];
    if(email)
    {
        self.txtEmail.text = email;
        if (pass) {
                [self.navigationController presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"AutoLoginViewController"] animated:YES completion:nil];
        }
    }
}
- (void) signIn:(NSString * ) email withPassword:(NSString *) pass
{
    _btnSignIn.enabled = NO;
    _btnSignIn.alpha = 0.5;
    [[FIRAuth auth] signInWithEmail:email
                           password:pass
                         completion:^(FIRUser *user, NSError *error) {
                             if (user) {
                                 // The user's ID, unique to the Firebase project.
                                 // Do NOT use this value to authenticate with your backend server,
                                 // if you have one. Use getTokenWithCompletion:completion: instead.
                                 if (![[NSUserDefaults standardUserDefaults] stringForKey:@"UID"]) {
                                     NSString *uid = user.uid;
                                     NSString *email = user.email;
                                     //NSURL *photoURL = user.photoURL;
                                     // ...
                                     [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"UID"];
                                     [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"EMAIL"];
                                     [[NSUserDefaults standardUserDefaults] setObject:pass forKey:@"PASS"];
                                 }
                                 [self goToMainView];
                             }else
                             {
                                 _btnSignIn.enabled = YES;
                                 _btnSignIn.alpha = 1.0;
                                 [self showAlert: [NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
                             }
                             
                         }];
    
}
- (IBAction)signInClick:(id)sender {
    [self signIn:_txtEmail.text withPassword:_txtPassword.text];
}

- (void) goToMainView
{
    [self.navigationController presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"MainViewController"] animated:YES completion:nil];
}

- (void) showAlert: (NSString *) message
{
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Bap checkin"
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIPreviewActionStyleDefault handler:nil];
    [alert addAction:dismiss];

    
    [self presentViewController:alert animated:YES completion:nil];

}
/*
 #pragma mark - textField
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
@end
