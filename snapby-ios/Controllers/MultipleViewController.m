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
#import "SettingsViewController.h"
#import "MBProgressHUD.h"
#import "ApiUtilities.h"

@interface MultipleViewController ()

@property (strong, nonatomic) ProfileViewController * myProfileViewController;
@property (strong, nonatomic) ExploreViewController * exploreViewController;
@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *myLocation;

@property (nonatomic) BOOL flashOn;
@property (nonatomic, strong) ALAssetsLibrary *library;

@property (nonatomic, strong) User* currentUser;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) BOOL firstExplorePositionSet;

@end

@implementation MultipleViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Handles status bar
    self.edgesForExtendedLayout=UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars=NO;
    self.automaticallyAdjustsScrollViewInsets=NO;
    
    // Get current user
    self.currentUser = [SessionUtilities getCurrentUser];
    
    // Alloc location manager
    [self allocAndInitLocationManager];

    NSUInteger scrollViewWidth = CGRectGetWidth(self.scrollView.frame);
    NSUInteger scrollViewHeight = CGRectGetHeight(self.scrollView.frame);
    
    self.scrollView.delegate = self;
    
    self.scrollView.contentSize = CGSizeMake(scrollViewWidth * 3, scrollViewHeight);
    
    [self getOrInitImagePickerController];
    [self getOrInitExploreViewController];
    [self getOrInitMyProfileViewController];
    
    self.exploreViewController.view.frame = CGRectMake(0, 0, scrollViewWidth, scrollViewHeight);
    [self addChildViewController:self.exploreViewController];
    [self.scrollView addSubview:self.exploreViewController.view];
    [self.exploreViewController didMoveToParentViewController:self];
    
    self.imagePickerController.view.frame = CGRectMake((scrollViewWidth) * 1, 0, scrollViewWidth, scrollViewHeight);
    [self addChildViewController:self.imagePickerController];
    [self.scrollView addSubview:self.imagePickerController.view];
    [self.imagePickerController didMoveToParentViewController:self];
    
    self.myProfileViewController.view.frame = CGRectMake((scrollViewWidth) * 2, 0, scrollViewWidth, scrollViewHeight);
    [self addChildViewController:self.myProfileViewController];
    [self.scrollView addSubview:self.myProfileViewController.view];
    [self.myProfileViewController didMoveToParentViewController:self];
    
    [self goToPage:1 animated:NO];
    
    self.firstExplorePositionSet = NO;
    
    [self getMyLikesAndComments];
}

- (void)getMyLikesAndComments
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *likesPrefKey = [NSString stringWithFormat:@"%@ %lu", MY_LIKES_PREF, self.currentUser.identifier];
    NSString *commentsPrefKey = [NSString stringWithFormat:@"%@ %lu", MY_COMMENTS_PREF, self.currentUser.identifier];
    
    NSArray *likesArray = [[userDefaults objectForKey:likesPrefKey] mutableCopy];
    self.myLikes = [NSMutableSet setWithArray:likesArray];
    
    NSArray *commentsArray = [[userDefaults objectForKey:commentsPrefKey] mutableCopy];
    self.myComments = [NSMutableSet setWithArray:commentsArray];
    
    [ApiUtilities getMyLikesAndCommentsSuccess:^(NSMutableSet *likes, NSMutableSet *comments) {
        self.myLikes = likes;
        self.myComments = comments;
        
        NSArray *likesArray = [self.myLikes allObjects];
        [userDefaults setObject:likesArray forKey:likesPrefKey];
        
        NSArray *commentsArray = [self.myComments allObjects];
        [userDefaults setObject:commentsArray forKey:commentsPrefKey];
    } failure:nil];
}

- (void)goToPage:(NSUInteger)page animated:(BOOL)animated
{
    if (page > 2) {
        return;
    }
    
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (BOOL)prefersStatusBarHidden {
    if ([self getScrollViewPage] == 1) {
        return YES;
    } else {
        return NO;
    }
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

// ---------------------------
// Controller initializations
// --------------------------

- (UIImagePickerController *) getOrInitImagePickerController {
    if(!self.imagePickerController){
        [self allocAndInitFullScreenCamera];
    }
    return self.imagePickerController;
}

- (ExploreViewController *) getOrInitExploreViewController {
    if(!self.exploreViewController){
        self.exploreViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MapViewController"];
        self.exploreViewController.exploreVCDelegate = self;
    }
    return self.exploreViewController;
}

- (ProfileViewController *) getOrInitMyProfileViewController {
    if(!self.myProfileViewController){
        self.myProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
        self.myProfileViewController.profileViewControllerDelegate = self;
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

- (void)goHomeAfterRelaunch
{
    if ([self getScrollViewPage] != 1) {
        [self goToPage:1 animated:NO];
    }
    
    [self reloadSnapbies];
    [self getMyLikesAndComments];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Create from Multiple modal segue"]) {
        CreateSnapbyViewController * createSnapbyViewController = (CreateSnapbyViewController *) [segue destinationViewController];
        createSnapbyViewController.createSnapbyVCDelegate = self;
        createSnapbyViewController.sentImage = (UIImage *) sender;
    }
}


// CreateSnapbyDelegate protocole

- (void)onSnapbyCreated
{
    [self reloadSnapbies];
    
    [self goToPage:0 animated:NO];
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
    
    if (!self.firstExplorePositionSet) {
        [self.exploreViewController onLocationObtained];
        self.firstExplorePositionSet = YES;
    }
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

- (void)reloadSnapbies
{
    [self.exploreViewController moveMapToMyLocationAndLoadSnapbies];
    [self.myProfileViewController refreshSnapbies];
}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = CGRectGetWidth(self.scrollView.frame);
    return floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
