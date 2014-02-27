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

@interface CreateShoutViewController ()

////@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *charCount;
////@property (strong, nonatomic) MKPointAnnotation *shoutAnnotation;
////@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (strong, nonatomic) NSString *shoutImageName;
@property (strong, nonatomic) NSString *shoutImageUrl;
@property (strong, nonatomic) UIImage *capturedImage;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *refineLocationButton;
@property(nonatomic,retain) ALAssetsLibrary *library;
@property (nonatomic) BOOL blackListed;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionView;


@end

@implementation CreateShoutViewController

- (void)viewWillAppear:(BOOL)animated {
    

//    [LocationUtilities animateMap:self.mapView ToLatitude:self.shoutLocation.coordinate.latitude Longitude:self.shoutLocation.coordinate.longitude WithDistance:2*kShoutRadius Animated:NO];
//    
//    [self.mapView removeAnnotations:self.mapView.annotations];
//    MKPointAnnotation *shoutAnnotation = [[MKPointAnnotation alloc] init];
//    shoutAnnotation.coordinate = self.shoutLocation.coordinate;
//    [self.mapView addAnnotation:shoutAnnotation];
    
    self.blackListed = [SessionUtilities getCurrentUser].isBlackListed;
}

- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation
{
    self.shoutLocation = shoutLocation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.blackListed = NO;
    self.descriptionView.delegate = self;
    self.library = [ALAssetsLibrary new];
    
    //Round corners
    self.descriptionView.layer.cornerRadius = 5;
    self.descriptionView.clipsToBounds = YES;
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"cancel" rightItem:@"ok" title:@"Shout" sizeBig:YES inViewController:self];
    
    // Display a square camera
    [self displaySquareCamera];
    
    // Set the cursor before a placeholder
    self.descriptionView.text = NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil);
    self.descriptionView.textColor = [UIColor lightGrayColor];
    [self.descriptionView becomeFirstResponder];
    // observe keyboard show notifications to resize the text view appropriately
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillShow:)
//                                                 name:UIKeyboardWillShowNotification
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillHide:)
//                                                 name:UIKeyboardWillHideNotification
//                                               object:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else if ([textView.text isEqualToString:NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil)]) {
        textView.text = @"";
        textView.textColor = [UIColor whiteColor];
        [GeneralUtilities adaptHeightTextView:textView];
        return YES;
    } else {
        // Update char count
        NSInteger charCount = [textView.text length] + [text length] - range.length;
        NSInteger remainingCharCount = kShoutMaxLength - charCount;
        self.charCount.text = [NSString stringWithFormat:@"%d", remainingCharCount];
        return (remainingCharCount >= 0);
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [GeneralUtilities adaptHeightTextView:textView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if ([textView.text isEqualToString:NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil)]) {
        textView.selectedRange = NSMakeRange(0, 0);
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = NSLocalizedStringFromTable (@"description_placeholder", @"Strings",nil);
        textView.textColor = [UIColor lightGrayColor];
        [GeneralUtilities adaptHeightTextView:textView];
        [self.view endEditing:YES];
    }
}

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
    } else if (self.descriptionView.text.length == 0) {
        title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        message = NSLocalizedStringFromTable (@"shout_description_blank", @"Strings", @"comment");
        error = YES;
    } else if (self.descriptionView.text.length > kMaxShoutDescriptionLength) {
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
        
        if (self.capturedImage && self.shoutImageUrl) {
            createShoutSuccessBlock = ^{
                [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                                       Lng:self.shoutLocation.coordinate.longitude
                                                  Username:currentUser.username
                                               Description:self.descriptionView.text
                                                     Image:self.shoutImageUrl
                                                    UserId:currentUser.identifier
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
        } else {
            [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                                   Lng:self.shoutLocation.coordinate.longitude
                                              Username:currentUser.username
                                           Description:self.descriptionView.text
                                                 Image:nil
                                              UserId:currentUser.identifier
                                     AndExecuteSuccess:successBlock
                                               Failure:failureBlock];
        }
    });
}

- (IBAction)refineLocationButtonClicked:(id)sender {
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


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (image) {
        [self resizeAndSaveSelectedImageAndUpdate:image];
    } else {
        NSLog(@"Failed to get image");
    }
}

- (void)resizeAndSaveSelectedImageAndUpdate:(UIImage *)image
{
    self.capturedImage = [ImageUtilities cropBiggestCenteredSquareImageFromImage:image withSide:kShoutImageSize];
    if (!self.capturedImage){
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"comment_failed_message", @"Strings", @"comment") withTitle:nil];
        return;
    }
    
    [self saveImageToFileSystem:self.capturedImage];
    self.shoutImageName = [[GeneralUtilities getDeviceID] stringByAppendingFormat:@"--%d", [GeneralUtilities currentDateInMilliseconds]];
    self.shoutImageUrl = [S3_URL stringByAppendingString:self.shoutImageName];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.shoutImageView setImage:self.capturedImage];
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)backButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) displaySquareCamera
{
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    imagePickerController.showsCameraControls = YES;
    [ImageUtilities addSquareBoundsToImagePicker:imagePickerController];
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:NO completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
//    NSDictionary *userInfo = [notification userInfo];
//    
//    // Get the origin of the keyboard when it's displayed.
//    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
//    
//    // Get the top of the keyboard as the y coordinate of its origin in self's view's
//    // coordinate system. The bottom of the text view's frame should align with the top
//    // of the keyboard's final position.
//    //
//    CGRect keyboardRect = [aValue CGRectValue];
//    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
//    
//    CGFloat keyboardTop = keyboardRect.origin.y;
//    
//    CGRect newTextViewFrame = self.addCommentContainerView.bounds;
//    newTextViewFrame.origin.y = keyboardTop - self.addCommentContainerView.frame.size.height;
//    
//    // Get the duration of the animation.
//    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
//    NSTimeInterval animationDuration;
//    [animationDurationValue getValue:&animationDuration];
//    
//    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:animationDuration];
//    
//    self.addCommentContainerView.frame = newTextViewFrame;
//    
//    [UIView commitAnimations];
}


@end
