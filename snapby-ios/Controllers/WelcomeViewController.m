//
//  WelcomeViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/10/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "WelcomeViewController.h"
#import "SessionUtilities.h"
#import "ImageUtilities.h"
#import <FacebookSDK/FacebookSDK.h>
#import "NavigationAppDelegate.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"


@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *facebookButtonView;
@property (weak, nonatomic) IBOutlet UIButton *signupButtonView;
@property (weak, nonatomic) IBOutlet UILabel *facebookFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *facebookSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupSecondLabel;
@property (weak, nonatomic) IBOutlet UIButton *signinButton;
@property (weak, nonatomic) IBOutlet UILabel *signinLabel;

@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    //Round corners
    self.facebookButtonView.layer.cornerRadius = 5.0f;
    self.signupButtonView.layer.cornerRadius = 5.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
    //Nav bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [super viewWillAppear:animated];
}

- (IBAction)facebookButtonClicked:(id)sender {
    // Prevent double clicking
    UIButton *facebookButton = (UIButton *) sender;
    facebookButton.enabled = NO;
    [UIView animateWithDuration:0.1 animations:^{
        [self setButtonsAndLabelsAlphaTo:0];}
     ];
    
    // We should not have any token or open session here
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded
        || FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        NSLog(@"%u",FBSession.activeSession.state);
        [SessionUtilities redirectToSignIn];
        
    } else {
        // Check connection
        if (![GeneralUtilities connected]) {
            [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        } else {
            // Display loading
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            // Open a session showing the user the login UI
            [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"]
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session, FBSessionState state, NSError *error) {
                 
                 // Retrieve the app delegate
                 NavigationAppDelegate* navigationAppDelegate = [UIApplication sharedApplication].delegate;
                 [navigationAppDelegate sessionStateChanged:session state:state error:error];
             }];
            return;
        }
    }
    facebookButton.enabled = YES;
    [self setButtonsAndLabelsAlphaTo:1];
}

- (IBAction)signupButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signup Push Segue" sender:nil];
}


- (IBAction)signinButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signin Push Segue" sender:nil];
}

- (void)setButtonsAndLabelsAlphaTo:(float)alpha{
    if (alpha<0||alpha>1){
        return;
    }
    self.facebookButtonView.alpha = alpha;
    self.facebookFirstLabel.alpha = alpha;
    self.facebookSecondLabel.alpha = alpha;
    self.signupButtonView.alpha = alpha;
    self.signupFirstLabel.alpha = alpha;
    self.signupSecondLabel.alpha = alpha;
    self.signinButton.alpha = alpha;
    self.signinLabel.alpha = alpha;
}


@end