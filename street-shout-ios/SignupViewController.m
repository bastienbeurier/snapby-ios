//
//  SignupViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "SignupViewController.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "AFStreetShoutAPIClient.h"
#import "User.h"
#import "AFJSONRequestOperation.h"
#import "SessionUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageUtilities.h"
#import "TrackingUtilities.h"

@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextView;

@end

@implementation SignupViewController

- (void)viewDidLoad
{
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:@"ok" title:@"Sign up" sizeBig:YES inViewController:self];
    
    //Status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    //Textview border
    [ImageUtilities drawBottomBorderForView:self.usernameTextView withColor:[UIColor lightGrayColor]];
    [ImageUtilities drawBottomBorderForView:self.emailTextView withColor:[UIColor lightGrayColor]];
    [ImageUtilities drawBottomBorderForView:self.passwordTextView withColor:[UIColor lightGrayColor]];
    [ImageUtilities drawBottomBorderForView:self.confirmPasswordTextView withColor:[UIColor lightGrayColor]];
    
    //Set textview tags
    self.usernameTextView.tag = 0;
    self.emailTextView.tag = 1;
    self.passwordTextView.tag = 2;
    self.confirmPasswordTextView.tag = 3;
    
    //Set TextField delegate
    self.usernameTextView.delegate = self;
    self.emailTextView.delegate = self;
    self.passwordTextView.delegate = self;
    self.confirmPasswordTextView.delegate = self;
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    //First responder
    [self.usernameTextView becomeFirstResponder];
    
    [super viewDidAppear:animated];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    NSInteger nextTag = textField.tag + 1;
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)okButtonClicked
{
    BOOL error = NO;
    NSString *message;
    
    if (![GeneralUtilities validUsername:self.usernameTextView.text]) {
        message = NSLocalizedStringFromTable (@"invalid_username_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (self.usernameTextView.text.length < 6 || self.usernameTextView.text.length > 20) {
        message = NSLocalizedStringFromTable (@"username_length_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (![GeneralUtilities validEmail:self.emailTextView.text]) {
        message = NSLocalizedStringFromTable (@"invalid_email_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (self.passwordTextView.text.length < 6 || self.passwordTextView.text.length > 128) {
        message = NSLocalizedStringFromTable (@"password_length_alert_text", @"Strings", @"comment");
        error = YES;
    } else  if (![self.passwordTextView.text isEqualToString:self.confirmPasswordTextView.text]) {
        message = NSLocalizedStringFromTable (@"passwords_matching_alert_text", @"Strings", @"comment");
        error = YES;
    }
    
    if (error) {
        [GeneralUtilities showMessage:message withTitle:nil];
    } else {
        if ([GeneralUtilities connected]) {
            [self signupUser];
        } else {
            [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        }
    }
}

- (void)backButtonClicked
{
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)signupUser {
    
    typedef void (^SuccessBlock)(User *, NSString *);
    SuccessBlock successBlock = ^(User *user, NSString *authToken) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [SessionUtilities updateCurrentUserInfoInPhone:user];
            [SessionUtilities securelySaveCurrentUserToken:authToken];
            
            //Mixpanel identification and tracking
            [TrackingUtilities identifyWithMixpanel:user isSigningUp:YES];
            [TrackingUtilities trackSignUpWithSource:@"Email"];
            
            [self performSegueWithIdentifier:@"Navigation Push Segue From Signup" sender:nil];
        });
    };
    
    typedef void (^FailureBlock)(NSDictionary *);
    FailureBlock failureBlock = ^(NSDictionary * errors){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            NSString *title = nil;
            NSString *message = nil;
            
            if (errors) {
                NSDictionary *userErrors = [errors valueForKey:@"user"];
                if (userErrors && [userErrors  valueForKey:@"username"]) {
                    message = NSLocalizedStringFromTable (@"username_already_taken_message", @"Strings", @"comment");
                } else if (userErrors && [userErrors  valueForKey:@"email"]) {
                    message = NSLocalizedStringFromTable (@"email_already_taken_message", @"Strings", @"comment");
                }
            } else {
                title = NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment");
            }

            [GeneralUtilities showMessage:message withTitle:title];
        });
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [AFStreetShoutAPIClient signupWithEmail:self.emailTextView.text password:self.passwordTextView.text username:self.usernameTextView.text success:successBlock failure:failureBlock];
    });
    
}

@end
