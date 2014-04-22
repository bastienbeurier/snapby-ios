//
//  SignupViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "SignupViewController.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "AFSnapbyAPIClient.h"
#import "User.h"
#import "SessionUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageUtilities.h"
#import "TrackingUtilities.h"

@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextView;
@property (nonatomic) CGSize keyboardSize;

@end

@implementation SignupViewController

- (void)viewDidLoad
{
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:@"ok" title:@"Sign up" sizeBig:YES inViewController:self];
    
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
    
    // Register for keyboard notif
    [self registerForKeyboardNotifications];
    
    [super viewDidLoad];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    //First responder
    [self.usernameTextView becomeFirstResponder];
    
    [super viewDidAppear:animated];
}

-(void) keyboardWasShown:(NSNotification *)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    self.keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:textField up:YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
}


- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int moveUpValue = textField.frame.origin.y+ textField.frame.size.height;
    int animatedDistance = self.keyboardSize.height-(self.view.frame.size.height-moveUpValue-5);
    
    if(animatedDistance>0)
    {
        const float movementDuration = 0.3f;
        int movement = (up ? -animatedDistance : animatedDistance);
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: movementDuration];
        [self.view viewWithTag:10].frame = CGRectOffset([self.view viewWithTag:10].frame, 0, movement);
        [UIView commitAnimations];
    }
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
    } else if (self.usernameTextView.text.length < 1 || self.usernameTextView.text.length > 20) {
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
            
            [self performSegueWithIdentifier:@"Multiple From Signup Push Segue" sender:nil];
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
        [AFSnapbyAPIClient signupWithEmail:self.emailTextView.text password:self.passwordTextView.text username:self.usernameTextView.text success:successBlock failure:failureBlock];
    });
    
}

@end
