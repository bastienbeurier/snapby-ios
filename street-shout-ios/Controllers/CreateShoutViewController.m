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

@property (strong, nonatomic) NSString *shoutImageName;
@property (strong, nonatomic) NSString *shoutImageUrl;
@property (strong, nonatomic) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property(nonatomic,retain) ALAssetsLibrary *library;

@property (nonatomic) BOOL blackListed;
@property (nonatomic) BOOL isAnonymous;
@property (weak, nonatomic) IBOutlet UILabel *charCount;
@property (weak, nonatomic) IBOutlet UIView *topKeyboardView;
@property (weak, nonatomic) IBOutlet UITextField *addDescriptionField;


@end

@implementation CreateShoutViewController

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    self.blackListed = [SessionUtilities getCurrentUser].isBlackListed;
    
    
//    // Set the cursor before the placeholder
//    if (self.firstOpening) {
//        [self.descriptionView becomeFirstResponder];
//        [GeneralUtilities adaptHeightTextView:self.descriptionView];
//        self.firstOpening = FALSE;
//    }
}

//- (void) viewDidLayoutSubviews {
//    // strange hack to avoid opening bug
//    if (!self.firstOpening) {
//         [GeneralUtilities adaptHeightTextView:self.descriptionView];
//     }
//}

- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation
{
    self.shoutLocation = shoutLocation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //todobt
    self.isAnonymous = YES;
    self.blackListed = NO;
//    self.firstOpening = TRUE;
//    self.descriptionView.delegate = self;
    self.library = [ALAssetsLibrary new];
    
    //Round corners
//    self.descriptionView.layer.cornerRadius = 5;
//    self.descriptionView.clipsToBounds = YES;
    
    //Nav Bar
//    [ImageUtilities drawCustomNavBarWithLeftItem:@"cancel" rightItem:@"ok" title:@"Shout" sizeBig:YES inViewController:self];
    
    // observe keyboard show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
//    
//    // Put the placeholder
//    self.descriptionView.textColor = [UIColor lightGrayColor];
//    self.descriptionView.text = NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil);

    // Display camera
    [self displayFullScreenCamera];

}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    if ([textView.text isEqualToString:NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil)]) {
        textView.text = @"";
        textView.textColor = [UIColor whiteColor];
        [GeneralUtilities adaptHeightTextView:textView];
    }
    
    // Update char count
    NSInteger charCount = [textView.text length] + [text length] - range.length;
    NSInteger remainingCharCount = kShoutMaxLength - charCount;
    self.charCount.text = [NSString stringWithFormat:@"%d", remainingCharCount];
    return (remainingCharCount >= 0);
}

//- (void)textViewDidChange:(UITextView *)textView {
//    [GeneralUtilities adaptHeightTextView:textView];
//}

//- (void)textViewDidChangeSelection:(UITextView *)textView
//{
//    if ([textView.text isEqualToString:NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil)]) {
//        textView.selectedRange = NSMakeRange(0, 0);
//    }
//}
//
//- (void)textViewDidEndEditing:(UITextView *)textView
//{
//    if ([textView.text isEqualToString:@""]) {
//        textView.text = NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil);
//        textView.textColor = [UIColor lightGrayColor];
//        [GeneralUtilities adaptHeightTextView:textView];
//        [self.view endEditing:YES];
//    }
//}

- (void)okButtonClicked
{
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
    } else if (self.addDescriptionField.text.length == 0) {
        title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        message = NSLocalizedStringFromTable (@"shout_description_blank", @"Strings", @"comment");
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

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    [self performSegueWithIdentifier:@"Refine Shout Location" sender:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Refine Shout Location"]) {
        ((RefineShoutLocationViewController *) [segue destinationViewController]).myLocation = self.myLocation;
        ((RefineShoutLocationViewController *) [segue destinationViewController]).refineShoutLocationVCDelegate = self;
    }
}

// Custom button actions

- (IBAction)quitButtonclicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


// Utilities

- (void)keyboardWillShow:(NSNotification *)notification {
    
    [KeyboardUtilities pushUpTopView:self.topKeyboardView whenKeyboardWillShowNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [KeyboardUtilities pushDownTopView:self.topKeyboardView whenKeyboardWillhideNotification:notification];
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
    double scalingRatio = self.view.frame.size.height / kCameraHeight;
    double translationFactor = (self.view.frame.size.height - kCameraHeight) / 2;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, translationFactor);
    imagePickerController.cameraViewTransform = translate;
    
    CGAffineTransform scale = CGAffineTransformScale(translate, scalingRatio, scalingRatio);
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
    
    // Resize image
    CGFloat newWidth = kShoutImageWidth / image.size.width;
    self.capturedImage = [UIImage imageWithCGImage:[image CGImage] scale:newWidth orientation:image.imageOrientation];
    
    if (!image || !self.capturedImage) {
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"take_and_resize_picture_failed", @"Strings", @"comment") withTitle:nil];
        [self dismissViewControllerAnimated:YES completion:NULL];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    self.shoutImageName = [[GeneralUtilities getDeviceID] stringByAppendingFormat:@"--%d", [GeneralUtilities currentDateInMilliseconds]];
    self.shoutImageUrl = [S3_URL stringByAppendingString:self.shoutImageName];

    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.shoutImageView setImage:self.capturedImage];
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
