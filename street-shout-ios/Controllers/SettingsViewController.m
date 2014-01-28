//
//  SettingsViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "SettingsViewController.h"
#import "TestFlight.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "SessionUtilities.h"
#import "AFStreetShoutAPIClient.h"


@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UIButton *usernameContainer;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UILabel *rateMeLabel;
@property (weak, nonatomic) IBOutlet UIButton *distanceUnitButton;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *ratemeButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (strong, nonatomic) NSArray *distanceUnitPreferences;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unitSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *shoutVersionLabel;

@end

@implementation SettingsViewController

- (NSArray *)distanceUnitPreferences
{
    return @[NSLocalizedStringFromTable (@"meters", @"Strings", @"comment"),
             NSLocalizedStringFromTable (@"miles", @"Strings", @"comment")];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:@"Settings" sizeBig:YES inViewController:self];
    
    self.shoutVersionLabel.text = [self.shoutVersionLabel.text stringByAppendingFormat:@"\u2122 (v.%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    //Set distance unit pref if exists, update user prefs
    NSNumber *unitPref = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
    self.unitSegmentedControl.selectedSegmentIndex = unitPref ? [unitPref integerValue] : 0;
    [self unitSegmentedControlValueChanged:nil];
    
    //Set username
    [self setInitialUsername];
    
    //Round corners
    NSUInteger cornerRadius = 10;
    self.usernameContainer.layer.cornerRadius = cornerRadius;
    self.distanceUnitButton.layer.cornerRadius = cornerRadius;
    self.feedbackButton.layer.cornerRadius = cornerRadius;
    self.ratemeButton.layer.cornerRadius = cornerRadius;
    self.logOutButton.layer.cornerRadius = cornerRadius;
}

- (void)setInitialUsername
{
    self.usernameTextField.text = [@"@" stringByAppendingString:[SessionUtilities getCurrentUser].username];
    self.usernameTextField.delegate = self;
}

- (IBAction)unitSegmentedControlValueChanged:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.unitSegmentedControl.selectedSegmentIndex] forKey:DISTANCE_UNIT_PREF];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)feedbackClicked:(id)sender {
    NSString *email = [NSString stringWithFormat:@"mailto:info@street-shout.com?subject=Feedback for Shout on iOS (v%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (IBAction)rateMeClicked:(id)sender {
    if ([GeneralUtilities connected]) {
        [GeneralUtilities redirectToAppStore];
    } else {
        [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
    }
}

- (void)viewDidUnload {
    [self setRateMeLabel:nil];
    [super viewDidUnload];
}

- (IBAction)logoutButtonClicked:(id)sender {
    [SessionUtilities redirectToSignIn];
}

- (void)backButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    BOOL error = NO;
    NSString *message;
    
    NSString *newUsername = @"";
    
    if ([self.usernameTextField.text length] > 0 &&
        [[self.usernameTextField.text substringToIndex:1] isEqualToString:@"@"]) {
        newUsername = [self.usernameTextField.text substringFromIndex:1];
    } else {
        newUsername = self.usernameTextField.text;
    }
    
    if (![GeneralUtilities validUsername:newUsername]) {
        message = NSLocalizedStringFromTable (@"invalid_username_alert_text", @"Strings", @"comment");
        error = YES;
    } else if ([newUsername length] < 6 || [newUsername length] > 20) {
        message = NSLocalizedStringFromTable (@"username_length_alert_text", @"Strings", @"comment");
        error = YES;
    }
    
    if (error) {
        [self setInitialUsername];
        [GeneralUtilities showMessage:message withTitle:nil];
    } else {
        typedef void (^SuccessBlock)(User *);
        SuccessBlock successBlock = ^(User *user) {
            [SessionUtilities updateCurrentUserInfoInPhone:user];
        };
        
        typedef void (^FailureBlock)(NSDictionary *);
        FailureBlock failureBlock = ^(NSDictionary * errors){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *title = nil;
                NSString *message = nil;
                
                if (errors) {
                    NSDictionary *userErrors = [errors valueForKey:@"user"];
                    if (userErrors && [userErrors  valueForKey:@"username"]) {
                        message = NSLocalizedStringFromTable (@"username_already_taken_message", @"Strings", @"comment");
                        [self setInitialUsername];
                    }
                } else {
                    title = NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment");
                }
                
                [GeneralUtilities showMessage:message withTitle:title];
            });
        };
        
        [AFStreetShoutAPIClient updateUsername:newUsername success:successBlock failure:failureBlock];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacement
{
    if ([textField.text length] == 1 && [replacement length] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];
    return NO;
}

@end
