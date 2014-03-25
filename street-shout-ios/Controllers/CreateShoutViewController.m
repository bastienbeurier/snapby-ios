//
//  CreateShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "CreateShoutViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Constants.h"
#import "AFStreetShoutAPIClient.h"
#import "LocationUtilities.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "ImageUtilities.h"
#import "NavigationAppDelegate.h"
#import "SessionUtilities.h"
#import "TrackingUtilities.h"
#import "KeyboardUtilities.h"

@interface CreateShoutViewController ()

@property (weak, nonatomic) IBOutlet UIButton *anonymousButton;
@property (strong, nonatomic) IBOutlet UIImageView *shoutImageView;

@property (nonatomic) BOOL blackListed;
@property (nonatomic) BOOL isAnonymous;
@property (nonatomic) BOOL flashOn;

@property (weak, nonatomic) IBOutlet UILabel *charCount;
@property (weak, nonatomic) IBOutlet UITextField *addDescriptionField;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) CLLocation *shoutLocation;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation CreateShoutViewController


// ----------------------------------------------------------
// Create Shout Screen
// ----------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.isAnonymous = NO;
    self.blackListed = NO;
    
    double rescalingRatio = self.view.frame.size.height / kCameraHeight;
    [self.shoutImageView setImage:[ImageUtilities cropWidthOfImage:self.sentImage by:(1-1/rescalingRatio)]];
    
    self.addDescriptionField.delegate = self;
    
    // Get user location
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self.locationManager startUpdatingLocation];
    
    // observe keyboard show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    self.blackListed = [SessionUtilities getCurrentUser].isBlackListed;
    
    // Open keyboard to create shout
    [self.addDescriptionField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.05f];
}


// RefineShout protocole
- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation
{
    self.shoutLocation = shoutLocation;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    }
    
    // Update char count
    NSInteger charCount = [textField.text length] + [text length] - range.length;
    NSInteger remainingCharCount = kShoutMaxLength - charCount;
    if (remainingCharCount >= 0 ) {
        self.charCount.text = [NSString stringWithFormat:@"%ld", (long)remainingCharCount];
        return YES;
    } else {
        return NO;
    }
}


- (IBAction)createShoutButtonClicked:(id)sender {
    
    if (![SessionUtilities isSignedIn]){
        [SessionUtilities redirectToSignIn];
        return;
    }
    
    [self.view endEditing:YES];
    
    // Get user location if we don't have already one
    if (![LocationUtilities userLocationValid:self.shoutLocation]) {
        self.shoutLocation = self.locationManager.location;
    }
    
    // Check error
    NSString *title = nil; NSString *message = nil;
    
    if (self.blackListed) {
        title = NSLocalizedStringFromTable (@"black_listed_alert_title", @"Strings", @"comment");
        message = NSLocalizedStringFromTable (@"black_listed_alert_text", @"Strings", @"comment");
    } else if (self.addDescriptionField.text.length > kMaxShoutDescriptionLength) {
        title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        NSString *maxChars = [NSString stringWithFormat:@" (max: %lu).", (unsigned long)kMaxShoutDescriptionLength];
        message = [(NSLocalizedStringFromTable (@"shout_description_too_long", @"Strings", @"comment")) stringByAppendingString:maxChars];
    } else if (!self.sentImage) {
        title = NSLocalizedStringFromTable (@"missing_image", @"Strings", @"comment");
    } else if (![GeneralUtilities connected]) {
        title = NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment");
    } else if (![LocationUtilities userLocationValid:self.shoutLocation]) {
        title = NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment");
        message = NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment");
    }
    
    if (title || message) {
        [GeneralUtilities showMessage:message withTitle:title];
    } else {
        [self createShout];
    }
}


- (void)createShout
{
    typedef void (^SuccessBlock)(Shout *);
    SuccessBlock successBlock = ^(Shout *shout) {
        [TrackingUtilities trackCreateShout];
            
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
        [self dismissViewControllerAnimated:NO completion:nil];
        [self.createShoutVCDelegate onShoutCreated:shout];
    };
    
    typedef void (^FailureBlock)(NSURLSessionDataTask *);
    FailureBlock failureBlock = ^(NSURLSessionDataTask *task) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
        
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtilities invalidTokenResponse:task]) {
            [SessionUtilities redirectToSignIn];
        } else {
            NSString *title = NSLocalizedStringFromTable (@"create_shout_failed_title", @"Strings", @"comment");
            NSString *message = NSLocalizedStringFromTable (@"create_shout_failed_message", @"Strings", @"comment");
            [GeneralUtilities showMessage:message withTitle:title];
        }
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    // Start monitoring network
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    User *currentUser = [SessionUtilities getCurrentUser];
    
    NSString *encodedImage = [ImageUtilities encodeToBase64String:self.sentImage];

    [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                                   Lng:self.shoutLocation.coordinate.longitude
                                              Username:currentUser.username
                                           Description:self.addDescriptionField.text
                                                 encodedImage:encodedImage
                                                UserId:currentUser.identifier
                                             Anonymous:self.isAnonymous
                                     AndExecuteSuccess:successBlock
                                               Failure:failureBlock];
}


// Custom button actions

- (IBAction)quitButtonclicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)refineLocationButtonClicked:(id)sender {
    [self.addDescriptionField resignFirstResponder];
    [self performSegueWithIdentifier:@"Refine Shout modal segue" sender:nil];
}

- (IBAction)anonymousButtonClicked:(id)sender {
    if (self.isAnonymous) {
        self.isAnonymous = NO;
        [self.anonymousButton setImage:[UIImage imageNamed:@"create_anonymous_button.png"] forState:UIControlStateNormal];
        [self displayToastWithMessage:NSLocalizedStringFromTable (@"anonymous_button_disabled", @"Strings", @"comment")];
    } else {
        self.isAnonymous = YES;
        [self.anonymousButton setImage:[UIImage imageNamed:@"create_anonymous_button_pressed.png"] forState:UIControlStateNormal];
        [self displayToastWithMessage:NSLocalizedStringFromTable (@"anonymous_button_enabled", @"Strings", @"comment")];
    }
}


// Utilities

- (void)keyboardWillShow:(NSNotification *)notification {
    [KeyboardUtilities pushUpTopView:self.containerView whenKeyboardWillShowNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [KeyboardUtilities pushDownTopView:self.containerView whenKeyboardWillhideNotification:notification];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Refine Shout modal segue"]) {
        ((RefineShoutLocationViewController *) [segue destinationViewController]).myLocation = self.locationManager.location;
        ((RefineShoutLocationViewController *) [segue destinationViewController]).refineShoutLocationVCDelegate = self;
    }
}

- (void)displayToastWithMessage:(NSString *)message{
    MBProgressHUD *toast = [MBProgressHUD showHUDAddedTo:self.containerView animated:YES];
    // Configure for text only and offset down
    toast.mode = MBProgressHUDModeText;
    toast.labelText = message;
    toast.opacity = 0.3f;
    toast.margin =10.f;
    toast.yOffset = -100.f;
    [toast hide:YES afterDelay:1];
}





@end
