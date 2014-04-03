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
#import "UIImageView+AFNetworking.h"
#include "MBProgressHUD.h"


@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) NSArray *distanceUnitPreferences;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unitSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *shoutVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *editTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *settingsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *participateTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *squareImage;

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
    
    //Disable scroll view if screen is big enough
    if ([[UIScreen mainScreen] bounds].size.height == 568.0f) {
        self.scrollView.scrollEnabled = NO;
    }
    
    [ImageUtilities drawBottomBorderForView:self.editTitleLabel withColor:[UIColor grayColor]];
    [ImageUtilities drawBottomBorderForView:self.settingsTitleLabel withColor:[UIColor grayColor]];
    [ImageUtilities drawBottomBorderForView:self.participateTitleLabel withColor:[UIColor grayColor]];
    
    [ImageUtilities setWithoutCachingImageView:self.profilePictureView withURL:[self.currentUser getUserProfilePictureURL]];
}

- (void)setInitialUsername
{
    self.usernameTextField.text = [@"@" stringByAppendingString:self.currentUser.username];
    self.usernameTextField.delegate = self;
}


// --------------------------
// Label clicked
// --------------------------

- (IBAction)unitSegmentedControlValueChanged:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:self.unitSegmentedControl.selectedSegmentIndex] forKey:DISTANCE_UNIT_PREF];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)feedbackClicked:(id)sender {
    NSString *email = [NSString stringWithFormat:@"mailto:info@shouthereandnow.com?subject=Feedback for Shout on iOS (v%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
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

- (IBAction)logoutButtonClicked:(id)sender {
    [SessionUtilities redirectToSignIn];
}

- (void)backButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}


// --------------------------
// Username change
// --------------------------

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
    } else if ([newUsername length] < 1 || [newUsername length] > 20) {
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
            self.currentUser.username = [NSString stringWithString:user.username];
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


// --------------------------
// Profile picture change
// --------------------------

- (IBAction)addPhotoButtonClicked:(id)sender {
    if (![GeneralUtilities connected]) {
        [GeneralUtilities showMessage:nil withTitle: NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        return;
    }
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (image) {
        [self resizeAndUpdateProfilePicture:image];
    } else {
        NSLog(@"Failed to get image");
    }
}

- (void)resizeAndUpdateProfilePicture:(UIImage *)image
{
    // Crop and rescale image
    CGSize rescaleSize = {kShoutImageHeight, kShoutImageHeight};
    self.squareImage = [ImageUtilities imageWithImage:[ImageUtilities cropBiggestCenteredSquareImageFromImage:image withSide:image.size.width] scaledToSize:rescaleSize];
    
    // encode profile pic;
    NSString *encodedImage = [ImageUtilities encodeToBase64String:self.squareImage];

    void(^successBlock)() = ^(void) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self.profilePictureView setImage:self.squareImage];
    };
    void(^failureBlock)() = ^(void) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.squareImage = nil;
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_update_profile_pic_title", @"Strings", @"comment") withTitle:nil];
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [AFStreetShoutAPIClient updateProfilePicture:encodedImage success:successBlock failure:failureBlock];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
