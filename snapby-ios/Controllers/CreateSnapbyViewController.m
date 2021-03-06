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
#import "GPUImage.h"

@interface CreateSnapbyViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *snapbyImageView;

@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) UIImage *modifiedImage;

@property (nonatomic) BOOL blackListed;
@property (nonatomic) BOOL isAnonymous;
@property (nonatomic) BOOL flashOn;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *tutorialView;

@property (strong, nonatomic) GPUImageSepiaFilter *sepiaFilter;
@property (strong, nonatomic) GPUImageContrastFilter *contrastFilter;
@property (strong, nonatomic) GPUImageExposureFilter *exposureFilter;
@property (strong, nonatomic) GPUImageLevelsFilter *levelsFilter;
@property (strong, nonatomic) GPUImageGrayscaleFilter *grayFilter;

@property (strong, nonatomic) GPUImagePicture *gpuImagePicture;

@property (nonatomic) NSUInteger filterIndex;

@end

@implementation CreateSnapbyViewController


// ----------------------------------------------------------
// Create Snapby Screen
// ----------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.filterIndex = 0;
    
    [ImageUtilities outerGlow:self.cancelButton];
    [ImageUtilities outerGlow:self.sendButton];
    
    self.isAnonymous = NO;
    self.blackListed = NO;
    
    double rescalingRatio = self.view.frame.size.height / kCameraHeight;
    
    self.originalImage = [ImageUtilities cropWidthOfImage:self.sentImage by:(1-1/rescalingRatio)];
    
    self.snapbyImageView.image = self.originalImage;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults objectForKey:APPLYING_SNAPBY_FILTER_TUTO_PREF]) {
        self.tutorialView.hidden = NO;
    } else {
        self.tutorialView.hidden = YES;
    }
    
    [userDefaults setObject:@"dummy" forKey:APPLYING_SNAPBY_FILTER_TUTO_PREF];
    
    [self setUpFilters];
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
    
    if (self.filterIndex == 0) {
        encodedImage = [ImageUtilities encodeToBase64String:self.sentImage];
    } else if (self.filterIndex == 1) {
        encodedImage = [ImageUtilities encodeToBase64String:[self vintageFilter:self.sentImage]];
    } else if (self.filterIndex == 2) {
        encodedImage = [ImageUtilities encodeToBase64String:[self washedOutFilter:self.sentImage]];
    } else if (self.filterIndex == 3) {
        encodedImage = [ImageUtilities encodeToBase64String:[self blackAndWhiteFilter:self.sentImage]];
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
    [self washedOutFilter:self.originalImage];
    
    UIImage *image = self.originalImage;
    
    if (self.filterIndex == 0) {
        [self displayToast:@"Vintage"];
        image = [self vintageFilter:image];
        self.filterIndex = self.filterIndex + 1;
    } else if (self.filterIndex == 1) {
        [self displayToast:@"Washed Out"];
        image = [self washedOutFilter:image];
        self.filterIndex = self.filterIndex + 1;
    } else if (self.filterIndex == 2) {
        [self displayToast:@"Black & White"];
        image = [self blackAndWhiteFilter:image];
        self.filterIndex = self.filterIndex + 1;
    } else if (self.filterIndex == 3) {
        [self displayToast:@"No Filter"];
        self.filterIndex = 0;
    }
    
    self.snapbyImageView.image = image;
}

- (void)setUpFilters
{
    self.sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    self.contrastFilter = [[GPUImageContrastFilter alloc] init];
    self.exposureFilter = [[GPUImageExposureFilter alloc] init];
    self.levelsFilter = [[GPUImageLevelsFilter alloc] init];
    self.grayFilter = [[GPUImageGrayscaleFilter alloc] init];
}

- (UIImage *)vintageFilter:(UIImage *)image
{
    // 0 - 1
    [self.sepiaFilter setIntensity:1.0];
    
    //0 - 4
    [self.contrastFilter setContrast:1.2];
    
    // - 4 - 4
    [self.exposureFilter setExposure:0.2];
    
    image = [self.sepiaFilter imageByFilteringImage:image];
    image = [self.contrastFilter imageByFilteringImage:image];
    return [self.exposureFilter imageByFilteringImage:image];
}

- (UIImage *)washedOutFilter:(UIImage *)image
{
    [self.levelsFilter setRedMin:0.25 gamma:1.0 max:0.8 minOut:0.0 maxOut:1.0];
    [self.levelsFilter setGreenMin:0.15 gamma:1.0 max:0.8 minOut:0.0 maxOut:1.0];
    [self.levelsFilter setBlueMin:0.03 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
    
    //0 - 4
    [self.contrastFilter setContrast:0.8];
    
    // - 4 - 4
    [self.exposureFilter setExposure:0.2];

    image = [self.levelsFilter imageByFilteringImage:image];
    image = [self.contrastFilter imageByFilteringImage:image];
    return [self.exposureFilter imageByFilteringImage:image];
}

- (UIImage *)blackAndWhiteFilter:(UIImage *)image
{
    return [self.grayFilter imageByFilteringImage:image];
}

- (void)displayToast:(NSString *)string
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = string;
    hud.margin = 10.f;
    hud.yOffset = 150.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:0.5];
}

@end
