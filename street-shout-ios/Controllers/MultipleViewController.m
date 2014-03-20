//
//  MultipleViewController.m
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/18/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "MultipleViewController.h"
#import "CreateShoutViewController.h"
#import "Constants.h"
#import "ImageUtilities.h"
#import "GeneralUtilities.h"

@interface MultipleViewController ()

@property (strong, nonatomic) SettingsViewController * settingsViewController;
@property (strong, nonatomic) ExploreViewController * exploreViewController;
@property (strong, nonatomic) CreateShoutViewController * createShoutViewController;
@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;

@property (nonatomic) BOOL flashOn;
@property(nonatomic,retain) ALAssetsLibrary *library;

@end

@implementation MultipleViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ShoutPageViewController"];
    self.pageViewController.dataSource = self;
    
    // Init the full screen camera
    self.imagePickerController = [ImageUtilities initFullScreenCameraControllerWithDelegate:self];
    self.flashOn = NO;
    self.library = [ALAssetsLibrary new];
    
    // Display it as the first screen
    NSArray *viewControllers = @[self.imagePickerController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UIImagePickerController class]]) {
        return [self getOrInitExploreViewController];
    } else if ([viewController isKindOfClass:[SettingsViewController class]]){
        return self.imagePickerController;
    } else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UIImagePickerController class]]) {
        return [self getOrInitSettingsViewController];
    } else if ([viewController isKindOfClass:[ExploreViewController class]]){
        return self.imagePickerController;
    } else {
        return nil;
    }
}



// ----------------------------------------------------------
// Full screen Camera
// ----------------------------------------------------------

// Custom button and actions

- (IBAction)mapButtonClicked:(id)sender {
    NSArray *viewControllers = @[[self getOrInitExploreViewController]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (IBAction)profileButtonClicked:(id)sender {
    NSArray *viewControllers = @[[self getOrInitSettingsViewController]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
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
    CGFloat scaleRatio = kShoutImageHeight / rescaleSize.height;
    rescaleSize.height *= scaleRatio;
    rescaleSize.width *= scaleRatio;
    portraitImage = [ImageUtilities imageWithImage:portraitImage scaledToSize:rescaleSize];
    
    // Push segue to create shout
    [self performSegueWithIdentifier:@"Create from Multiple push segue" sender:portraitImage];
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


// Utilities for controller transitions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Create from Multiple push segue"]) {
        ((CreateShoutViewController *) [segue destinationViewController]).sentImage = (UIImage *) sender;
        ((CreateShoutViewController *) [segue destinationViewController]).createShoutVCDelegate = self;
    }
}

- (void) moveToImagePickerController
{
    NSArray *viewControllers = @[self.imagePickerController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (ExploreViewController *) getOrInitExploreViewController {
    if(!self.exploreViewController){
        self.exploreViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ExploreViewController"];
        self.exploreViewController.exploreControllerdelegate = self;
    }
    return self.exploreViewController;
}

- (SettingsViewController *) getOrInitSettingsViewController {
    if(!self.settingsViewController){
        self.settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
        self.settingsViewController.settingsViewControllerdelegate = self;
    }
    return self.settingsViewController;
}

- (void)onShoutCreated:(Shout *)shout
{
    NSArray *viewControllers = @[[self getOrInitExploreViewController]];
    //Don't show shout controller immidiately (as for notification handling), otherwise segues get mixed up.
    self.exploreViewController.redirectToShout = shout;
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
}

@end
