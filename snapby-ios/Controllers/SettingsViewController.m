//
//  SettingsViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "SettingsViewController.h"
#import "TestFlight.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "SessionUtilities.h"
#import "ApiUtilities.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"

#define CHANGE_PROFILE_PIC 1
#define CHANGE_USERNAME 2
#define FEEDBACK 6
#define RATE_ME 7
#define LOG_OUT 9


@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) NSArray *distanceUnitPreferences;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unitSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *snapbyVersionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *squareImage;
@property (nonatomic) BOOL editedProfile;

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
    
    self.currentUser = [SessionUtilities getCurrentUser];
    
    [self.profilePictureView.layer setCornerRadius:20.0f];
    
    self.snapbyVersionLabel.text = [self.snapbyVersionLabel.text stringByAppendingFormat:@"\u2122 (v.%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    //Set distance unit pref if exists, update user prefs
    NSNumber *unitPref = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
    self.unitSegmentedControl.selectedSegmentIndex = unitPref ? [unitPref integerValue] : 0;
    [self unitSegmentedControlValueChanged:nil];
    
    //Set username
    [self setInitialUsername];
    
    [ImageUtilities setWithoutCachingImageView:self.profilePictureView withURL:[User getUserProfilePictureURLFromUserId:self.currentUser.identifier]];
    
    self.editedProfile = NO;
}

- (void)setInitialUsername
{
    self.usernameTextField.text = self.currentUser.username;
    self.usernameTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    if (self.editedProfile) {
        [self.settingsVCDelegate reloadSnapbiesFromSettings];
    }
}


// --------------------------
// Label clicked
// --------------------------

- (IBAction)unitSegmentedControlValueChanged:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:self.unitSegmentedControl.selectedSegmentIndex] forKey:DISTANCE_UNIT_PREF];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    
    NSString *newUsername = self.usernameTextField.text;
    
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
        self.editedProfile = YES;
        
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
        
        [ApiUtilities updateUsername:newUsername success:successBlock failure:failureBlock];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];
    return NO;
}


// --------------------------
// Profile picture change
// --------------------------


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
    self.editedProfile = YES;
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
    CGSize rescaleSize = {kSnapbyProfileImageHeight, kSnapbyProfileImageHeight};
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
    [ApiUtilities updateProfilePicture:encodedImage success:successBlock failure:failureBlock];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView
                       cellForRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    if (row == CHANGE_PROFILE_PIC) {
        [self changeProfilePicture];
    } else if (row == CHANGE_USERNAME) {
        [self.usernameTextField becomeFirstResponder];
    } else if (row == FEEDBACK) {
        NSString *email = [NSString stringWithFormat:@"mailto:info@snapby.co?subject=Feedback for Snapby on iOS (v%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    } else if (row == RATE_ME) {
        if ([GeneralUtilities connected]) {
            [GeneralUtilities redirectToAppStore];
        } else {
            [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        }
    } else if (row == LOG_OUT) {
        [SessionUtilities redirectToSignIn];
    }
}

- (void)changeProfilePicture
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

@end
