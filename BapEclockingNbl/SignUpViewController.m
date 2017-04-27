//
//  SignUpViewController.m
//  BapEclocking
//
//  Created by BapVn on 4/20/17.
//  Copyright © 2017 blockchain@bap.jp. All rights reserved.
//

#import "SignUpViewController.h"
@import Firebase;

@interface SignUpViewController ()
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _txtPassword.delegate = self;
    _txtEmail.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)signUpClick:(id)sender {
    [[FIRAuth auth]
     createUserWithEmail:_txtEmail.text
     password:_txtPassword.text
     completion:^(FIRUser *_Nullable user,
                  NSError *_Nullable error) {
         if (user) {
             // The user's ID, unique to the Firebase project.
             // Do NOT use this value to authenticate with your backend server,
             // if you have one. Use getTokenWithCompletion:completion: instead.
             NSString *uid = user.uid;
             NSString *email = user.email;
             //NSURL *photoURL = user.photoURL;
             // ...
             [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"UID"];
             [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"EMAIL"];
             [self signIn];
         }else
         {
             [self showAlert: [NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
         }
         
     }];
    
}
- (void) signIn
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
