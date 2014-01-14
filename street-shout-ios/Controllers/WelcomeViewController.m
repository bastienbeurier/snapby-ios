//
//  WelcomeViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/10/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "WelcomeViewController.h"
#import "SessionUtilities.h"
#import "ImageUtilities.h"
#import <FacebookSDK/FacebookSDK.h>
#import "NavigationAppDelegate.h"


@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *welcomeImageView;
@property (weak, nonatomic) IBOutlet UIButton *facebookButtonView;
@property (weak, nonatomic) IBOutlet UIButton *signupButtonView;
@property (weak, nonatomic) IBOutlet UILabel *facebookFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *facebookSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupSecondLabel;


@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    //Nav bar color
    NSArray *ver = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ([[ver objectAtIndex:0] intValue] >= 7) {
        self.navigationController.navigationBar.barTintColor = [ImageUtilities getShoutBlue];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.translucent = NO;
    }
    
    //Set background image
    NSString *filename = @"Welcome.png";
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (screenRect.size.height == 568.0f) {
        filename = [filename stringByReplacingOccurrencesOfString:@".png" withString:@"-568h.png"];
    }
    self.welcomeImageView.image = [UIImage imageNamed:filename];
    
    //Round corners
    NSUInteger buttonHeight = self.facebookButtonView.bounds.size.height;
    self.facebookButtonView.layer.cornerRadius = buttonHeight/2;
    self.signupButtonView.layer.cornerRadius = buttonHeight/2;
    
    //Set button borders
    [[self.signupButtonView layer] setBorderWidth:2.0f];
    [[self.signupButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
    [[self.facebookButtonView layer] setBorderWidth:2.0f];
    [[self.facebookButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Nav bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [super viewWillAppear:animated];
}

- (IBAction)facebookButtonStartedClicking:(id)sender {
    self.facebookFirstLabel.textColor = [UIColor grayColor];
    self.facebookSecondLabel.textColor = [UIColor grayColor];
    [[self.facebookButtonView layer] setBorderColor:[UIColor grayColor].CGColor];
}

- (IBAction)facebookButtonClicked:(id)sender {
    
    self.facebookFirstLabel.textColor = [UIColor whiteColor];
    self.facebookSecondLabel.textColor = [UIColor whiteColor];
    [[self.facebookButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    //todoBT
    // We should not have any token or open session here
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded
        || FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        [SessionUtilities redirectToSignIn];
        
    } else {
        // Open a session showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             
             // Retrieve the app delegate
             NavigationAppDelegate* navigationAppDelegate = [UIApplication sharedApplication].delegate;
             // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
             [navigationAppDelegate sessionStateChanged:session state:state error:error];
         }];
    }
}

- (IBAction)facebookButtonCancelledClicking:(id)sender {
    self.facebookFirstLabel.textColor = [UIColor whiteColor];
    self.facebookSecondLabel.textColor = [UIColor whiteColor];
    [[self.facebookButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
}


- (IBAction)signupButtonStartedClicking:(id)sender {
    self.signupFirstLabel.textColor = [UIColor grayColor];
    self.signupSecondLabel.textColor = [UIColor grayColor];
    [[self.signupButtonView layer] setBorderColor:[UIColor grayColor].CGColor];
}


- (IBAction)signupButtonClicked:(id)sender {
    self.signupFirstLabel.textColor = [UIColor whiteColor];
    self.signupSecondLabel.textColor = [UIColor whiteColor];
    [[self.signupButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
    [self performSegueWithIdentifier:@"Signup Push Segue" sender:nil];
}

- (IBAction)signupButtonCancelledClicking:(id)sender {
    self.signupFirstLabel.textColor = [UIColor whiteColor];
    self.signupSecondLabel.textColor = [UIColor whiteColor];
    [[self.signupButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
}


- (IBAction)signinButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signin Push Segue" sender:nil];
}



@end