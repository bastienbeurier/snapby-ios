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
#import "ApiUtilities.h"
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
#import "GPUImage.h"

@interface CreateSnapbyViewController ()

@property (weak, nonatomic) IBOutlet GPUImageView *snapbyImageView;

@property (strong, nonatomic) UIImage *originalImage;

@property (nonatomic) BOOL blackListed;
@property (nonatomic) BOOL isAnonymous;
@property (nonatomic) BOOL flashOn;
@property (nonatomic, strong) NSArray *effects;
@property (nonatomic) NSUInteger currentEffect;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *tutorialView;

@property (strong, nonatomic) GPUImageBrightnessFilter *brightnessFilter;
@property (strong, nonatomic) GPUImageContrastFilter *contrastFilter;
@property (strong, nonatomic) GPUImageRGBFilter *rgbFilter;
@property (strong, nonatomic) GPUImagePicture *gpuImagePicture;
@property (strong, nonatomic) GPUImageColorInvertFilter *invertFilter;

@end

@implementation CreateSnapbyViewController


// ----------------------------------------------------------
// Create Snapby Screen
// ----------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [ImageUtilities outerGlow:self.cancelButton];
    [ImageUtilities outerGlow:self.sendButton];
    
    self.currentEffect = 0;
    
    self.isAnonymous = NO;
    self.blackListed = NO;
    
    double rescalingRatio = self.view.frame.size.height / kCameraHeight;
    
    self.originalImage = [ImageUtilities cropWidthOfImage:self.sentImage by:(1-1/rescalingRatio)];
    
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:self.originalImage];
    [gpuImage addTarget:self.snapbyImageView];
    [gpuImage processImage];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults objectForKey:APPLYING_SNAPBY_FILTER_TUTO_PREF]) {
        self.tutorialView.hidden = NO;
    } else {
        self.tutorialView.hidden = YES;
    }
    
    [userDefaults setObject:@"dummy" forKey:APPLYING_SNAPBY_FILTER_TUTO_PREF];
}

- (IBAction)tutorialViewClicked:(id)sender {
    self.tutorialView.hidden = YES;
}


- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    self.blackListed = [SessionUtilities getCurrentUser].isBlackListed;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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
        
        if (self.createSnapbyVCDelegate) {
            NSLog(@"CREATE SNAPBY DELEGATE IS NIL");
        }
        
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

    [ApiUtilities createSnapbyWithLat:myLocation.coordinate.latitude
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


- (IBAction)imageClicked:(id)sender {
    UIImage *image = self.originalImage;

    [self firstFilter:image];
    
}

- (void)firstFilter:(UIImage *)image
{
    self.brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    self.contrastFilter = [[GPUImageContrastFilter alloc] init];
    self.rgbFilter = [[GPUImageRGBFilter alloc] init];
    self.invertFilter = [[GPUImageColorInvertFilter alloc] init];
    
    self.gpuImagePicture = [[GPUImagePicture alloc] initWithImage:image];
    [self.gpuImagePicture addTarget:self.invertFilter];
    [self.invertFilter addTarget:self.snapbyImageView];
    [self.gpuImagePicture processImage];
}

@end
