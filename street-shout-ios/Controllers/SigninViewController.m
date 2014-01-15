//
//  SigninViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/10/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "SigninViewController.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "AFStreetShoutAPIClient.h"
#import "User.h"
#import "AFJSONRequestOperation.h"
#import "SessionUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageUtilities.h"
#import "TrackingUtilities.h"

@interface SigninViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextView;

@end

@implementation SigninViewController

- (void)viewDidLoad
{
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithBackItem:YES okItem:YES title:@"Sign in" inViewController:self];
    
    //Textview border
    [ImageUtilities drawBottomBorderForView:self.emailTextView withColor:[UIColor lightGrayColor]];
    [ImageUtilities drawBottomBorderForView:self.passwordTextView withColor:[UIColor lightGrayColor]];
    
    //Set textview tags
    self.emailTextView.tag = 0;
    self.passwordTextView.tag = 1;
    
    //Set TextField delegate
    self.emailTextView.delegate = self;
    self.passwordTextView.delegate = self;
    
    [super viewDidLoad];
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

- (void)viewDidAppear:(BOOL)animated
{
    //First responder
    [self.emailTextView becomeFirstResponder];
    
    [super viewDidAppear:animated];
}

- (void)okButtonClicked
{
    BOOL error = NO;
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:@""
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    if (![GeneralUtilities validEmail:self.emailTextView.text]){
        message.message = NSLocalizedStringFromTable (@"invalid_email_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (self.passwordTextView.text.length < 6 || self.passwordTextView.text.length > 128) {
        message.message = NSLocalizedStringFromTable (@"password_length_alert_text", @"Strings", @"comment");
        error = YES;
    }
    
    if (error) {
        [message show];
    } else {
        if ([GeneralUtilities connected]) {
            [self signinUser];
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

- (void)backButtonClicked
{
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)signinUser {
    
    typedef void (^SuccessBlock)(User *, NSString *);
    SuccessBlock successBlock = ^(User *user, NSString *authToken) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [SessionUtilities updateCurrentUserInfoInPhone:user];
            [SessionUtilities securelySaveCurrentUserToken:authToken];
            
            //Mixpanel identification
            [TrackingUtilities identifyWithMixpanel:user isSigningUp:NO];
            
            [self performSegueWithIdentifier:@"Navigation Push Segue From Signin" sender:nil];
        });
    };
    
    typedef void (^FailureBlock)(AFHTTPRequestOperation *);
    FailureBlock failureBlock = ^(AFHTTPRequestOperation *operation){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            NSString *title = nil;
            NSString *message = nil;
            //In this case, 401 means email/password combination doesn't match
            if ([operation.response statusCode] == 401) {
                message = NSLocalizedStringFromTable (@"invalid_sign_in_message", @"Strings", @"comment");
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
        [AFStreetShoutAPIClient signinWithEmail:self.emailTextView.text
                                       password:self.passwordTextView.text
                                        success:(void(^)(User *user, NSString *auth_token))successBlock
                                        failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock];
    });
}


@end