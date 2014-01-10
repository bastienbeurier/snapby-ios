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

@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextView;

@end

@implementation SignupViewController

- (IBAction)signupButtonClicked:(id)sender {
    BOOL error = NO;
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:@""
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    if ([GeneralUtilities validUsername:self.usernameTextView.text]) {
        message.message = NSLocalizedStringFromTable (@"invalid_username_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (self.usernameTextView.text.length < 6 || self.usernameTextView.text.length > 20) {
        message.message = NSLocalizedStringFromTable (@"username_length_alert_text", @"Strings", @"comment");
        error = YES;
    } else if ([GeneralUtilities validEmail:self.emailTextView.text]) {
        message.message = NSLocalizedStringFromTable (@"invalid_email_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (self.passwordTextView.text.length < 6 || self.passwordTextView.text.length > 128) {
        message.message = NSLocalizedStringFromTable (@"password_length_alert_text", @"Strings", @"comment");
        error = YES;
    } else  if (![self.passwordTextView.text isEqualToString:self.confirmPasswordTextView.text]) {
        message.message = NSLocalizedStringFromTable (@"passwords_matching_alert_text", @"Strings", @"comment");
        error = YES;
    }
    
    if (error) {
        [message show];
    } else {
        if ([GeneralUtilities connected]) {
            [self signupUser];
        } else {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")
                                                              message:nil
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
        }
    }
}

- (void)signupUser {
    
    typedef void (^SuccessBlock)(User *, NSString *);
    SuccessBlock successBlock = ^(User *user, NSString *authToken) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [SessionUtilities updateCurrentUserInfoInPhone:user];
            [SessionUtilities securelySaveCurrentUserToken:authToken];
            
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

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [AFStreetShoutAPIClient signupWithEmail:self.emailTextView.text password:self.passwordTextView.text username:self.usernameTextView.text success:successBlock failure:failureBlock];
    });
    
}

@end
