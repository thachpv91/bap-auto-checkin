//
//  AutoLoginViewController.m
//  BapEclocking
//
//  Created by BapVn on 4/24/17.
//  Copyright © 2017 blockchain@bap.jp. All rights reserved.
//

#import "AutoLoginViewController.h"
@import Firebase;
@interface AutoLoginViewController ()

@end

@implementation AutoLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}
- (void) viewDidAppear:(BOOL)animated
{
    NSString * email = [[NSUserDefaults standardUserDefaults] stringForKey:@"EMAIL"];
    NSString * pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"PASS"];
    if(email && pass)
    {
       // [self signIn:email withPassword:pass];
    }
}
- (void) signIn:(NSString * ) email withPassword:(NSString *) pass
{
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
                                 [self goToLoginView];
                             }
                             
                         }];
    
}
- (void) goToMainView
{
    
    [self.navigationController presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"MainViewController"] animated:YES completion:nil];
    
}
- (void) goToLoginView
{
    [self.navigationController presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"] animated:YES completion:nil];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
