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
#import "AsyncImageUploader.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "ImageUtilities.h"
#import "NavigationAppDelegate.h"
#import "SessionUtilities.h"
#import "TrackingUtilities.h"
#import "KeyboardUtilities.h"

@interface CreateShoutViewController ()

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) IBOutlet UIView *cameraOverlayView;
@property (weak, nonatomic) IBOutlet UIButton *anonymousButton;

@property (nonatomic) CGFloat rescalingRatio;
@property (strong, nonatomic) NSString *shoutImageName;
@property (strong, nonatomic) NSString *shoutImageUrl;
@property (strong, nonatomic) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property(nonatomic,retain) ALAssetsLibrary *library;

@property (nonatomic) BOOL blackListed;
@property (nonatomic) BOOL isAnonymous;
@property (weak, nonatomic) IBOutlet UILabel *charCount;
@property (weak, nonatomic) IBOutlet UITextField *addDescriptionField;
@property (weak, nonatomic) IBOutlet UIView *containerView;


@end

@implementation CreateShoutViewController


// ----------------------------------------------------------
// Create Shout Screen
// ----------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    self.blackListed = [SessionUtilities getCurrentUser].isBlackListed;
    
    [self.addDescriptionField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.05f];
}

- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation
{
    self.shoutLocation = shoutLocation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isAnonymous = NO;
    self.blackListed = NO;
    self.addDescriptionField.delegate = self;
    self.library = [ALAssetsLibrary new];
    self.rescalingRatio = self.view.frame.size.height / kCameraHeight;
    
    // observe keyboard show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    // Display camera
    [self displayFullScreenCamera];
    
    // Start monitoring network
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
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
        self.charCount.text = [NSString stringWithFormat:@"%d", remainingCharCount];
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
    
    BOOL error = NO; NSString *title; NSString *message;
    
    if (self.blackListed) {
        title = NSLocalizedStringFromTable (@"black_listed_alert_title", @"Strings", @"comment");
        message = NSLocalizedStringFromTable (@"black_listed_alert_text", @"Strings", @"comment");
        error = YES;
    } else if (self.addDescriptionField.text.length > kMaxShoutDescriptionLength) {
        title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        NSString *maxChars = [NSString stringWithFormat:@" (max: %d).", kMaxShoutDescriptionLength];
        message = [(NSLocalizedStringFromTable (@"shout_description_too_long", @"Strings", @"comment")) stringByAppendingString:maxChars];
        error = YES;
    }
    
    if (error) {
        [GeneralUtilities showMessage:message withTitle:title];
    } else {
        if ([GeneralUtilities connected]) {
            [self createShout];
        } else {
            [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        }
    }
}


- (void)createShout
{
    typedef void (^SuccessBlock)(Shout *);
    SuccessBlock successBlock = ^(Shout *shout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [TrackingUtilities trackCreateShout];
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
            [self.createShoutVCDelegate onShoutCreated:shout];
        });
    };
    
    typedef void (^FailureBlock)(NSURLSessionDataTask *);
    FailureBlock failureBlock = ^(NSURLSessionDataTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            //In this case, 401 means that the auth token is no valid.
            if ([SessionUtilities invalidTokenResponse:task]) {
                [SessionUtilities redirectToSignIn];
            } else {
                NSString *title = NSLocalizedStringFromTable (@"create_shout_failed_title", @"Strings", @"comment");
                NSString *message = NSLocalizedStringFromTable (@"create_shout_failed_message", @"Strings", @"comment");
                [GeneralUtilities showMessage:message withTitle:title];
            }
        });
    };
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        typedef void (^UploadImageCompletionBlock)();
        UploadImageCompletionBlock createShoutSuccessBlock;
        UploadImageCompletionBlock createShoutFailureBlock;
        
        User *currentUser = [SessionUtilities getCurrentUser];
        
        createShoutSuccessBlock = ^{
            [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                                   Lng:self.shoutLocation.coordinate.longitude
                                              Username:currentUser.username
                                           Description:self.addDescriptionField.text
                                                 Image:self.shoutImageUrl
                                                UserId:currentUser.identifier
                                             Anonymous:self.isAnonymous
                                     AndExecuteSuccess:successBlock
                                               Failure:failureBlock];
        };
        
        createShoutFailureBlock = ^{
            failureBlock(nil);
        };
        
        AsyncImageUploader *imageUploader = [[AsyncImageUploader alloc] initWithImage:self.capturedImage AndName:self.shoutImageName];
        imageUploader.uploadImageSuccessBlock = createShoutSuccessBlock;
        imageUploader.uploadImageFailureBlock = createShoutFailureBlock;
        NSOperationQueue *operationQueue = [NSOperationQueue new];
        [operationQueue addOperation:imageUploader];
    });
}




// Custom button actions

- (IBAction)quitButtonclicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)refineLocationButtonClicked:(id)sender {
    [self.addDescriptionField resignFirstResponder];
    [self performSegueWithIdentifier:@"Refine Shout Location" sender:nil];
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
    if ([segueName isEqualToString: @"Refine Shout Location"]) {
        ((RefineShoutLocationViewController *) [segue destinationViewController]).myLocation = self.myLocation;
        ((RefineShoutLocationViewController *) [segue destinationViewController]).refineShoutLocationVCDelegate = self;
    }
}

- (void)displayToastWithMessage:(NSString *)message{
    MBProgressHUD *toast = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    // Configure for text only and offset down
    toast.mode = MBProgressHUDModeText;
    toast.labelText = message;
    toast.opacity = 0.3f;
    toast.margin =10.f;
    toast.yOffset = -100.f;
    toast.removeFromSuperViewOnHide = YES;
    [toast hide:YES afterDelay:1];
}



// ----------------------------------------------------------
// Full screen Camera
// ----------------------------------------------------------


- (void) displayFullScreenCamera
{
    
    // Create custom camera view
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;

    // Full screen
    imagePickerController.showsCameraControls = NO;
    imagePickerController.allowsEditing = NO;
    imagePickerController.navigationBarHidden=YES;
    [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
    self.cameraOverlayView.frame = imagePickerController.cameraOverlayView.frame;
    imagePickerController.cameraOverlayView = self.cameraOverlayView;
    self.cameraOverlayView = nil;

    // Transform camera to get full screen
    double translationFactor = (self.view.frame.size.height - kCameraHeight) / 2;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, translationFactor);
    imagePickerController.cameraViewTransform = translate;
    
    CGAffineTransform scale = CGAffineTransformScale(translate, self.rescalingRatio, self.rescalingRatio);
    imagePickerController.cameraViewTransform = scale;
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:NO completion:nil];
}

// Custom button actions

- (IBAction)cameraQuitButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)takePictureButtonClicked:(id)sender {
    [self.imagePickerController takePicture];
}
- (IBAction)flipCameraButtonClicked:(id)sender {
    if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront){
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    } else {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
}


// Utilities

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editInfo
{
    UIImage *image =  [editInfo objectForKey:UIImagePickerControllerOriginalImage];
    [self saveImageToFileSystem:image];
    
    // Force portrait
    UIImage* portraitImage = [UIImage imageWithCGImage:image.CGImage scale:1
                                    orientation:UIImageOrientationRight];
    
    // Resize image
    CGSize rescaleSize = portraitImage.size;
    CGFloat scaleRatio = kShoutImageWidth / rescaleSize.width;
    rescaleSize.height *= scaleRatio;
    rescaleSize.width *= scaleRatio;
    self.capturedImage = [ImageUtilities imageWithImage:portraitImage scaledToSize:rescaleSize];
    
    if (!portraitImage || !self.capturedImage) {
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"take_and_resize_picture_failed", @"Strings", @"comment") withTitle:nil];
        [self dismissViewControllerAnimated:YES completion:NULL];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    self.shoutImageName = [[GeneralUtilities getDeviceID] stringByAppendingFormat:@"--%d", [GeneralUtilities currentDateInMilliseconds]];
    self.shoutImageUrl = [S3_URL stringByAppendingString:self.shoutImageName];

    [self dismissViewControllerAnimated:NO completion:NULL];
    
    // Display the same format as in the camera screen
    [self.shoutImageView setImage:[ImageUtilities cropWidthOfImage:self.capturedImage by:(1-1/self.rescalingRatio)]];
    self.imagePickerController = nil;
}

- (void)saveImageToFileSystem:(UIImage *)image
{
    __weak typeof(self) weakSelf = self;
    
    [weakSelf.library writeImageToSavedPhotosAlbum:[image CGImage]
                                       orientation:[ImageUtilities convertImageOrientationToAssetOrientation:image.imageOrientation]
                                   completionBlock:^(NSURL *assetURL, NSError *error){
                                       if (error) {
                                           [GeneralUtilities showMessage:[error localizedDescription] withTitle:@"Error Saving"];
                                       }
                                   }];
}


@end
