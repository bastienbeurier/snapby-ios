//
//  CreateShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "CreateShoutViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "AFStreetShoutAPIClient.h"
#import "LocationUtilities.h"
#import "AsyncImageUploader.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"

#define ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"camera", @"Strings", @"comment")
#define ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"photo_library", @"Strings", @"comment")
#define ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

@interface CreateShoutViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *charCount;
@property (strong, nonatomic) MKPointAnnotation *shoutAnnotation;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (strong, nonatomic) NSString *shoutImageName;
@property (strong, nonatomic) NSString *shoutImageUrl;
@property (strong, nonatomic) UIImage *capturedImage;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation CreateShoutViewController

- (void)viewWillAppear:(BOOL)animated {
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME_PREF];
    
    if (userName) {
        self.usernameView.text = userName;
    }
    
    [LocationUtilities animateMap:self.mapView ToLatitude:self.shoutLocation.coordinate.latitude Longitude:self.shoutLocation.coordinate.longitude WithDistance:2*kShoutRadius Animated:NO];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKPointAnnotation *shoutAnnotation = [[MKPointAnnotation alloc] init];
    shoutAnnotation.coordinate = self.shoutLocation.coordinate;
    [self.mapView addAnnotation:shoutAnnotation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSString *userName = self.usernameView.text;
    
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:USER_NAME_PREF];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation
{
    self.shoutLocation = shoutLocation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.usernameView.delegate = self;
    self.descriptionView.delegate = self;

    //discriptionView formatting
    self.descriptionView.layer.cornerRadius = 5;
    self.descriptionView.clipsToBounds = YES;
    [self.descriptionView.layer setBorderColor:[[[UIColor grayColor]colorWithAlphaComponent:0.5] CGColor]];
    [self.descriptionView.layer setBorderWidth:2.0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else {
        NSInteger charCount = [textView.text length] + [text length] - range.length;
        NSInteger remainingCharCount = kShoutMaxLength - charCount;
        NSString *countStr = [NSString stringWithFormat:@"%d", remainingCharCount];
        self.charCount.text = [countStr stringByAppendingFormat:@" %@", NSLocalizedStringFromTable (@"characters", @"Strings", @"comment")];
        return YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.descriptionView becomeFirstResponder];
    return YES;
}

- (IBAction)createShoutClicked:(id)sender {
    BOOL error = NO;
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@""
                                                      message:@""
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];

    if (self.usernameView.text.length == 0) {
        message.title = NSLocalizedStringFromTable (@"incorrect_username", @"Strings", @"comment");
        message.message = NSLocalizedStringFromTable (@"username_blank", @"Strings", @"comment");
        error = YES;
    }
    
    if (self.usernameView.text.length > kMaxUsernameLength) {
        message.title = NSLocalizedStringFromTable (@"incorrect_username", @"Strings", @"comment");
        NSString *maxChars = [NSString stringWithFormat:@" (max: %d).", kMaxUsernameLength];
        message.message = [(NSLocalizedStringFromTable (@"username_too_long", @"Strings", @"comment")) stringByAppendingString:maxChars];
        error = YES;
    }

    if (self.descriptionView.text.length == 0) {
        message.title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        message.message = NSLocalizedStringFromTable (@"shout_description_blank", @"Strings", @"comment");
        error = YES;
    }
    
    if (self.descriptionView.text.length > kMaxShoutDescriptionLength) {
        message.title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        NSString *maxChars = [NSString stringWithFormat:@" (max: %d).", kMaxShoutDescriptionLength];
        message.message = [(NSLocalizedStringFromTable (@"shout_description_too_long", @"Strings", @"comment")) stringByAppendingString:maxChars];
        error = YES;
    }
    
    if (error) {
        [message show];
        return;
    } else {
        //TODO: save username
        [self createShout];
    }
}

- (void)createShout
{
    typedef void (^SuccessBlock)(Shout *);
    SuccessBlock successBlock = ^(Shout *shout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.createShoutVCDelegate dismissCreateShoutModal];
            [self.createShoutVCDelegate onShoutCreated:shout];
        });
        
        
    };
    
    typedef void (^FailureBlock)();
    FailureBlock failureBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            NSString *title = NSLocalizedStringFromTable (@"create_shout_failed_title", @"Strings", @"comment");
            NSString *message = NSLocalizedStringFromTable (@"create_shout_failed_message", @"Strings", @"comment");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    };
    
    NSString *deviceId = [GeneralUtilities getDeviceID];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        typedef void (^CreateShoutBlock)();
        CreateShoutBlock createShoutBlock;
        
        if (self.capturedImage && self.shoutImageUrl) {
            createShoutBlock = ^{
                [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                                       Lng:self.shoutLocation.coordinate.longitude
                                                  Username:self.usernameView.text
                                               Description:self.descriptionView.text
                                                     Image:self.shoutImageUrl
                                                  DeviceId:deviceId
                                         AndExecuteSuccess:successBlock
                                                   Failure:failureBlock];
            };
            
            AsyncImageUploader *imageUploader = [[AsyncImageUploader alloc] initWithImage:self.capturedImage AndName:self.shoutImageName];
            imageUploader.completionBlock = createShoutBlock;
            NSOperationQueue *operationQueue = [NSOperationQueue new];
            [operationQueue addOperation:imageUploader];
        } else {
            createShoutBlock = ^{
                [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                                       Lng:self.shoutLocation.coordinate.longitude
                                                  Username:self.usernameView.text
                                               Description:self.descriptionView.text
                                                     Image:nil
                                                  DeviceId:deviceId
                                         AndExecuteSuccess:successBlock
                                                   Failure:failureBlock];
            };
            
            createShoutBlock();
        }
    });
}

- (IBAction)cancelShoutClicked:(id)sender {
    [self.createShoutVCDelegate dismissCreateShoutModal];
}

- (IBAction)settingsMapClicked:(id)sender {
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

- (void)dismissRefineShoutLocationModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addPhotoButtonClicked:(UIButton *)sender {
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
    if (self.shoutImageView.isAnimating)
    {
        [self.shoutImageView stopAnimating];
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        imagePickerController.showsCameraControls = YES;
    }
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)finishAndUpdate
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if (self.capturedImage) {
        [self.shoutImageView setImage:self.capturedImage];
    }
    
    self.imagePickerController = nil;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    image = [self resizeImage:image withSize:kShoutImageSize];
    
    self.capturedImage = image;
    self.shoutImageName = [[GeneralUtilities getDeviceID] stringByAppendingFormat:@"--%d", [GeneralUtilities currentDateInMilliseconds]];
    self.shoutImageUrl = [S3_URL stringByAppendingString:self.shoutImageName];
    
    [self finishAndUpdate];
}

- (UIImage *)resizeImage:(UIImage *)image withSize:(NSUInteger)size
{
    CGSize imageSize;
    imageSize.height = size;
    imageSize.width = size;
    
    UIGraphicsBeginImageContext(imageSize);
    [image drawInRect:CGRectMake(0,0, imageSize.width, imageSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
