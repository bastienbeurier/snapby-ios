//
//  MultipleViewController.m
//  snapby-ios
//
//  Created by Baptiste Truchot on 3/18/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "MultipleViewController.h"
#import "Constants.h"
#import "ImageUtilities.h"
#import "GeneralUtilities.h"
#import "LocationUtilities.h"
#import "SessionUtilities.h"

@interface MultipleViewController ()

@property (strong, nonatomic) ProfileViewController * myProfileViewController;
@property (strong, nonatomic) ExploreViewController * mapViewController;
@property (strong, nonatomic) CreateSnapbyViewController * createSnapbyViewController;
@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *myLocation;

@property (nonatomic) BOOL flashOn;
@property (nonatomic, strong) ALAssetsLibrary *library;

@property (nonatomic, strong) User* currentUser;

@end

@implementation MultipleViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get current user
    self.currentUser = [SessionUtilities getCurrentUser];
    
    // Alloc location manager
    [self allocAndInitLocationManager];
    
    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SnapbyPageViewController"];
    self.pageViewController.dataSource = self;
    
   [self.pageViewController setViewControllers:@[[self getOrInitImagePickerController]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self getOrInitMapViewController];
    [self getOrInitMyProfileViewController];
    
    //Hack to load the controllers
    float dummy = self.mapViewController.view.frame.size.height + self.myProfileViewController.view.frame.size.height;
    NSLog(@"Dummy %f", dummy);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}


- (void)viewWillAppear:(BOOL)animated
{
    // Start user location
    [self.locationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Update and stop user location
    self.currentUser.lat = self.locationManager.location.coordinate.latitude;
    self.currentUser.lng = self.locationManager.location.coordinate.longitude;
    [self.locationManager stopUpdatingLocation];
}

         
// ----------------------
// Controller transitions
// ----------------------

// UIPageViewControllerDataSource protocole
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UIImagePickerController class]]) {
        return [self getOrInitMapViewController];
    } else if ([viewController isKindOfClass:[ProfileViewController class]]){
        return [self getOrInitImagePickerController];
    } else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UIImagePickerController class]]) {
        return [self getOrInitMyProfileViewController];
    } else if ([viewController isKindOfClass:[ExploreViewController class]]){
        return [self getOrInitImagePickerController];
    } else {
        return nil;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Create from Multiple modal segue"]) {
        CreateSnapbyViewController * createSnapbyViewController = (CreateSnapbyViewController *) [segue destinationViewController];
        createSnapbyViewController.sentImage = (UIImage *) sender;
        createSnapbyViewController.snapbyLocation = self.locationManager.location;
    }
}


// ---------------------------
// Controller initializations
// --------------------------

- (UIImagePickerController *) getOrInitImagePickerController {
    if(!self.imagePickerController){
        [self allocAndInitFullScreenCamera];
    }
    return self.imagePickerController;
}

- (ExploreViewController *) getOrInitMapViewController {
    if(!self.mapViewController){
        self.mapViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MapViewController"];
        self.mapViewController.exploreVCDelegate = self;
    }
    return self.mapViewController;
}

- (ProfileViewController *) getOrInitMyProfileViewController {
    if(!self.myProfileViewController){
        self.myProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MyProfileViewController"];
        self.myProfileViewController.myProfileViewControllerDelegate = self;
        self.myProfileViewController.currentUser = self.currentUser;
        self.myProfileViewController.profileUserId = self.currentUser.identifier;
    }
    return self.myProfileViewController;
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

// Custom button and actions
- (IBAction)mapButtonClicked:(id)sender {
    NSArray *viewControllers = @[[self getOrInitMapViewController]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (IBAction)profileButtonClicked:(id)sender {
    NSArray *viewControllers = @[[self getOrInitMyProfileViewController]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (IBAction)takePictureButtonClicked:(id)sender {
    if ([LocationUtilities userLocationValid:self.locationManager.location]) {
        [self.imagePickerController takePicture];
    } else {
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"no_location_for_snapby_message", @"Strings", @"comment") withTitle:NSLocalizedStringFromTable (@"no_location_for_snapby_title", @"Strings", @"comment")];
    }
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
    __weak typeof(self) weakSelf = self;
    
    [weakSelf.library writeImageToSavedPhotosAlbum:[image CGImage]
                                       orientation:[ImageUtilities convertImageOrientationToAssetOrientation:image.imageOrientation]
                                   completionBlock:^(NSURL *assetURL, NSError *error){
                                       if (error) {
                                           [GeneralUtilities showMessage:[error localizedDescription] withTitle:@"Error Saving"];
                                       }
                                   }];
}


// CreateSnapbyDelegate protocole

- (void)onSnapbyCreated:(Snapby *)snapby
{
    //TODO show success toast
}
- (void)startLocationUpdate
{
    [self.locationManager startUpdatingLocation];
}
- (void)stopLocationUpdate
{
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.myLocation = [locations lastObject];
}


// Location Manager
- (void)allocAndInitLocationManager
{
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.distanceFilter = kDistanceBeforeUpdateLocation;
}

- (CLLocation *)getMyLocation
{
    return self.myLocation;
}

@end
