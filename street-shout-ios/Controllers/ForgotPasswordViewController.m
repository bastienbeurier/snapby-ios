//
//  ForgotPasswordViewController.m
//  street-shout-ios
//
//  Created by Baptiste Truchot on 1/16/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "ForgotPasswordViewController.h"
#import "GeneralUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "MBProgressHUD.h"

@interface ForgotPasswordViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextView;

@end

@implementation ForgotPasswordViewController

- (IBAction)closeButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Send reset password instructions by email and dismiss the modal
- (IBAction)resetPasswordButtonClicked:(id)sender {
    
    // Prevent double clicking
    UIButton *resetButton = (UIButton *) sender;
    resetButton.enabled = NO;
    
    if (![GeneralUtilities validEmail:self.emailTextView.text]){
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"invalid_email_alert_text", @"Strings", @"comment") withTitle:nil];
        resetButton.enabled = YES;
    } else if (![GeneralUtilities connected]) {
        [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        resetButton.enabled = YES;
    } else {
        void(^successBlock)() = ^(id JSON) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if ([JSON valueForKeyPath:@"errors"]){
                [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"email_not_in_database_message", @"Strings", @"comment") withTitle:nil];
            }
            else {
                [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"reset_password_sent_success_message", @"Strings", @"comment") withTitle:nil];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            resetButton.enabled = YES;
        };
        void(^failureBlock)() = ^() {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"Try_again_message", @"Strings", @"comment") withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
            resetButton.enabled = YES;
        };
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [AFStreetShoutAPIClient sendResetPasswordInstructionsToEmail: self.emailTextView.text success:successBlock failure:failureBlock];
    }
    
}

@end
