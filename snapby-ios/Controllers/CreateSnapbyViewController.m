//
//  CreateSnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "CreateSnapbyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Constants.h"
#import "AFSnapbyAPIClient.h"
#import "LocationUtilities.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "ImageUtilities.h"
#import "NavigationAppDelegate.h"
#import "SessionUtilities.h"
#import "TrackingUtilities.h"
#import "KeyboardUtilities.h"
#import "UIImage+FiltrrCompositions.h"
#import "UIImage+Filtrr.h"

@interface CreateSnapbyViewController ()

@property (weak, nonatomic) IBOutlet UIButton *anonymousButton;
@property (strong, nonatomic) IBOutlet UIImageView *snapbyImageView;

@property (strong, nonatomic) UIImage *originalImage;

@property (nonatomic) BOOL blackListed;
@property (nonatomic) BOOL isAnonymous;
@property (nonatomic) BOOL flashOn;
@property (nonatomic, strong) NSArray *effects;
@property (nonatomic) NSUInteger currentEffect;

@property (weak, nonatomic) IBOutlet UIView *containerView;



@end

@implementation CreateSnapbyViewController


// ----------------------------------------------------------
// Create Snapby Screen
// ----------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentEffect = 0;
    
    self.isAnonymous = NO;
    self.blackListed = NO;
    
    double rescalingRatio = self.view.frame.size.height / kCameraHeight;
    
    self.originalImage = [ImageUtilities cropWidthOfImage:self.sentImage by:(1-1/rescalingRatio)];
    
    [self.snapbyImageView setImage:self.originalImage];
    
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
}


- (IBAction)createSnapbyButtonClicked:(id)sender {
    [self.view endEditing:YES];
    
    // Check error
    NSString *title = nil;
    NSString *message = nil;
    
    if (self.blackListed) {
        title = NSLocalizedStringFromTable (@"black_listed_alert_title", @"Strings", @"comment");
        message = NSLocalizedStringFromTable (@"black_listed_alert_text", @"Strings", @"comment");
    } else if (![GeneralUtilities connected]) {
        title = NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment");
    }
    
    if (title || message) {
        [GeneralUtilities showMessage:message withTitle:title];
    } else {
        [self createSnapby];
    }
}


- (void)createSnapby
{
    CLLocation *myLocation = [self.createSnapbyVCDelegate getMyLocation];
    
    if (![LocationUtilities userLocationValid:myLocation]) {
        NSString *title = NSLocalizedStringFromTable (@"no_location_for_snapby_title", @"Strings", @"comment");
        NSString *message = NSLocalizedStringFromTable (@"no_location_for_snapby_message", @"Strings", @"comment");
        
        [GeneralUtilities showMessage:message withTitle:title];
        return;
    }
    
    typedef void (^SuccessBlock)(Snapby *);
    SuccessBlock successBlock = ^(Snapby *snapby) {
        [TrackingUtilities trackCreateSnapby];
            
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
        [self.createSnapbyVCDelegate onSnapbyCreated];
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    typedef void (^FailureBlock)(NSURLSessionDataTask *);
    FailureBlock failureBlock = ^(NSURLSessionDataTask *task) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
        
        //In this case, 401 means that the auth token is no valid.
        if ([SessionUtilities invalidTokenResponse:task]) {
            [SessionUtilities redirectToSignIn];
        } else {
            NSString *title = NSLocalizedStringFromTable (@"create_snapby_failed_title", @"Strings", @"comment");
            NSString *message = NSLocalizedStringFromTable (@"create_snapby_failed_message", @"Strings", @"comment");
            [GeneralUtilities showMessage:message withTitle:title];
        }
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    // Start monitoring network
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    User *currentUser = [SessionUtilities getCurrentUser];
    
    NSString *encodedImage;
    
    if (self.currentEffect == 1) {
        encodedImage = [ImageUtilities encodeToBase64String:[self.sentImage e10]];
    } else if (self.currentEffect == 2) {
        encodedImage = [ImageUtilities encodeToBase64String:[self.sentImage e3]];
    } else if (self.currentEffect == 3){
        encodedImage = [ImageUtilities encodeToBase64String:[self.sentImage e4]];
    } else {
        encodedImage = [ImageUtilities encodeToBase64String:self.sentImage];
    }

    [AFSnapbyAPIClient createSnapbyWithLat:myLocation.coordinate.latitude
                                                   Lng:myLocation.coordinate.longitude
                                              Username:currentUser.username
                                           Description:@""
                                                 encodedImage:encodedImage
                                                UserId:currentUser.identifier
                                             Anonymous:self.isAnonymous
                                     AndExecuteSuccess:successBlock
                                               Failure:failureBlock];
}


// Custom button actions

- (IBAction)quitButtonclicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
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

- (void)displayToastWithMessage:(NSString *)message {
    MBProgressHUD *toast = [MBProgressHUD showHUDAddedTo:self.containerView animated:YES];
    // Configure for text only and offset down
    toast.mode = MBProgressHUDModeText;
    toast.labelText = message;
    toast.opacity = 0.3f;
    toast.margin =10.f;
    toast.yOffset = -100.f;
    [toast hide:YES afterDelay:1];
}


- (IBAction)imageClicked:(id)sender {
    UIImage *image = self.originalImage;
    
    if (self.currentEffect == 0) {
        [self.snapbyImageView setImage:[image e10]];
        self.currentEffect = 1;
    } else if (self.currentEffect == 1) {
        [self.snapbyImageView setImage:[image e3]];
        self.currentEffect = 2;
    } else if (self.currentEffect == 2) {
        [self.snapbyImageView setImage:[image e4]];
        self.currentEffect = 3;
    } else {
        [self.snapbyImageView setImage:self.originalImage];
        self.currentEffect = 0;
    }
}



@end
