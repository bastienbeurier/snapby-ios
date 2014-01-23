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
#import "AFJSONRequestOperation.h"
#import "TrackingUtilities.h"

#define ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"camera", @"Strings", @"comment")
#define ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"photo_library", @"Strings", @"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

@interface CreateShoutViewController ()

@property (weak, nonatomic) IBOutlet UITextView *descriptionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *charCount;
@property (strong, nonatomic) MKPointAnnotation *shoutAnnotation;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (strong, nonatomic) NSString *shoutImageName;
@property (strong, nonatomic) NSString *shoutImageUrl;
@property (strong, nonatomic) UIImage *capturedImage;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *refineLocationButton;
@property (weak, nonatomic) IBOutlet UIView *descriptionViewShadowingView;
@property(nonatomic,retain) ALAssetsLibrary *library;
@property (weak, nonatomic) IBOutlet UIButton *removeShoutImage;
@property (nonatomic) BOOL blackListed;
@end

@implementation CreateShoutViewController

- (void)viewWillAppear:(BOOL)animated {
    [LocationUtilities animateMap:self.mapView ToLatitude:self.shoutLocation.coordinate.latitude Longitude:self.shoutLocation.coordinate.longitude WithDistance:2*kShoutRadius Animated:NO];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKPointAnnotation *shoutAnnotation = [[MKPointAnnotation alloc] init];
    shoutAnnotation.coordinate = self.shoutLocation.coordinate;
    [self.mapView addAnnotation:shoutAnnotation];
    
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
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    //Round corners
    NSUInteger buttonHeight = self.addPhotoButton.bounds.size.height;
    self.shoutImageView.clipsToBounds = YES;
    self.addPhotoButton.layer.cornerRadius = buttonHeight/2;
    self.refineLocationButton.layer.cornerRadius = buttonHeight/2;
    self.descriptionView.layer.cornerRadius = 5;
    self.descriptionViewShadowingView.layer.cornerRadius = 5;
    self.mapView.layer.cornerRadius = 15;
    self.shoutImageView.layer.cornerRadius = 15;
    
    self.descriptionViewShadowingView.clipsToBounds = NO;
    
    [self.descriptionViewShadowingView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.descriptionViewShadowingView.layer setShadowOpacity:0.25];
    [self.descriptionViewShadowingView.layer setShadowRadius:3];
    [self.descriptionViewShadowingView.layer setShadowOffset:CGSizeMake(0, 0)];
    
    self.descriptionView.clipsToBounds = YES;
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:@"ok" title:@"Shout" sizeBig:YES inViewController:self];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else {
        NSInteger charCount = [textView.text length] + [text length] - range.length;
        NSInteger remainingCharCount = kShoutMaxLength - charCount;
        self.charCount.text = [NSString stringWithFormat:@"%d", remainingCharCount];
        return YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.descriptionView becomeFirstResponder];
    return NO;
}

- (void)okButtonClicked
{
    if (![SessionUtilities isSignedIn]){
        [SessionUtilities redirectToSignIn];
        return;
    }
    
    [self.descriptionView resignFirstResponder];
    
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
            
            //Mixpanel tracking
            BOOL imagePresent = shout.image != nil;
            NSUInteger textLength = [shout.description length];
            [TrackingUtilities trackCreateShoutImage:imagePresent textLength:textLength];
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
            [self.createShoutVCDelegate onShoutCreated:shout];
        });
    };
    
    typedef void (^FailureBlock)(AFHTTPRequestOperation *);
    FailureBlock failureBlock = ^(AFHTTPRequestOperation *operation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            //In this case, 401 means that the auth token is no valid.
            if ([SessionUtilities invalidTokenResponse:operation]) {
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
                [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
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
            [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
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

- (IBAction)addPhotoButtonClicked:(id)sender {
    [self letUserChoosePhoto];
}

- (IBAction)clearPhoto:(id)sender {
    self.shoutImageView.image = nil;
    self.capturedImage = nil;
    [self.shoutImageView setHidden:YES];
    [self.removeShoutImage setHidden:YES];
}

- (void)letUserChoosePhoto
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL destructiveButtonTitle:nil otherButtonTitles:ACTION_SHEET_OPTION_1, ACTION_SHEET_OPTION_2, nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_1]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_2]) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if (self.shoutImageView.isAnimating) {
        [self.shoutImageView stopAnimating];
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.showsCameraControls = YES;
    }
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
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

- (void)finishAndUpdate
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if (self.capturedImage) {
        [self.shoutImageView setImage:self.capturedImage];
        [self.shoutImageView setHidden:NO];
        [self.removeShoutImage setHidden:NO];
    }
    
    self.imagePickerController = nil;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [self saveImageToFileSystem:image];
    }
    
    if (image) {
        [self resizeAndSaveSelectedImageAndUpdate:image];
    } else {
        NSLog(@"Failed to get image");
    }
}

- (void)resizeAndSaveSelectedImageAndUpdate:(UIImage *)image
{
    self.capturedImage = [ImageUtilities cropBiggestCenteredSquareImageFromImage:image withSide:kShoutImageSize];
    self.shoutImageName = [[GeneralUtilities getDeviceID] stringByAppendingFormat:@"--%d", [GeneralUtilities currentDateInMilliseconds]];
    self.shoutImageUrl = [S3_URL stringByAppendingString:self.shoutImageName];
    
    [self finishAndUpdate];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showMapInCreateShoutViewController
{
    [self.mapView setHidden:NO];
}

- (void)backButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
