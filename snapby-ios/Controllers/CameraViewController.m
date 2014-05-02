//
//  CameraViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 5/1/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "CameraViewController.h"
#import "Constants.h"
#import "ImageUtilities.h"
#import "GeneralUtilities.h"
#import "CreateSnapbyViewController.h"

@interface CameraViewController ()

@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (nonatomic) BOOL flashOn;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;

@end

@implementation CameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    [self getOrInitImagePickerController];
    
    self.imagePickerController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self addChildViewController:self.imagePickerController];
    [self.view addSubview:self.imagePickerController.view];
    [self.imagePickerController didMoveToParentViewController:self];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIImagePickerController *) getOrInitImagePickerController {
    if(!self.imagePickerController){
        [self allocAndInitFullScreenCamera];
    }
    return self.imagePickerController;
}

// ----------------------------------------------------------
// Full screen Camera
// ----------------------------------------------------------

// Alloc the impage picker controller
- (void) allocAndInitFullScreenCamera
{
    // Create custom camera view
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    
    // Custom buttons
    imagePickerController.showsCameraControls = NO;
    imagePickerController.allowsEditing = NO;
    imagePickerController.navigationBarHidden=YES;
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"OverlayCameraView" owner:self options:nil];
    UIView* myView = [ nibViews objectAtIndex: 0];
    
    imagePickerController.cameraOverlayView = myView;
    
    // Transform camera to get full screen
    double translationFactor = (self.view.frame.size.height - kCameraHeight) / 2;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, translationFactor);
    imagePickerController.cameraViewTransform = translate;
    
    double rescalingRatio = self.view.frame.size.height / kCameraHeight;
    CGAffineTransform scale = CGAffineTransformScale(translate, rescalingRatio, rescalingRatio);
    imagePickerController.cameraViewTransform = scale;
    
    // flash disactivated by default
    imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    self.flashOn = NO;
    self.library = [ALAssetsLibrary new];
    self.imagePickerController = imagePickerController;
}

- (IBAction)takePictureButtonClicked:(id)sender {
    [self.imagePickerController takePicture];
}

- (IBAction)flipCameraButtonClicked:(id)sender {
    if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront){
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        [self.flashButton setHidden:false];
    } else {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        [self.flashButton setHidden:true];
    }
}

- (IBAction)flashButtonClicked:(id)sender {
    if(self.flashOn == NO){
        [self.flashButton setImage:[UIImage imageNamed:@"flash_on.png"] forState:UIControlStateNormal];
        self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        self.flashOn = YES;
    } else {
        [self.flashButton setImage:[UIImage imageNamed:@"flash_off.png"] forState:UIControlStateNormal];
        self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        self.flashOn = NO;
    }
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSnapbyCreated
{

    [self.cameraVCDelegate onSnapbyCreated];
    [self dismissViewControllerAnimated:NO completion:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

// Utilities
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editInfo
{
    UIImage *image =  [editInfo objectForKey:UIImagePickerControllerOriginalImage];
    [self saveImageToFileSystem:image];
    
    // Force portrait, and avoid flip of front camera
    UIImageOrientation orientation = self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
    
    UIImage* portraitImage = [UIImage imageWithCGImage:image.CGImage
                                                 scale:1
                                           orientation:orientation];
    
    // Resize image
    CGSize rescaleSize = portraitImage.size;
    CGFloat scaleRatio = kSnapbyImageHeight / rescaleSize.height;
    rescaleSize.height *= scaleRatio;
    rescaleSize.width *= scaleRatio;
    portraitImage = [ImageUtilities imageWithImage:portraitImage scaledToSize:rescaleSize];
    
    // Push segue to create snapby
    [self performSegueWithIdentifier:@"Create from Multiple modal segue" sender:portraitImage];
}

- (void)saveImageToFileSystem:(UIImage *)image
{
//    __weak typeof(self) weakSelf = self;
//    
//    [weakSelf.library writeImageToSavedPhotosAlbum:[image CGImage]
//                                       orientation:[ImageUtilities convertImageOrientationToAssetOrientation:image.imageOrientation]
//                                   completionBlock:^(NSURL *assetURL, NSError *error){
//                                       if (error) {
//                                           [GeneralUtilities showMessage:[error localizedDescription] withTitle:@"Error Saving"];
//                                       }
//                                   }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Create from Multiple modal segue"]) {
        CreateSnapbyViewController *createSnapbyViewController = (CreateSnapbyViewController *) [segue destinationViewController];
        createSnapbyViewController.createSnapbyVCDelegate = self;
        createSnapbyViewController.sentImage = (UIImage *) sender;
    }
}

- (CLLocation *)getMyLocation
{
    return [self.cameraVCDelegate getMyLocation];
}



@end
