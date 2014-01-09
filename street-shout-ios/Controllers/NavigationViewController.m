//
//  NavigationViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "NavigationViewController.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "Shout.h"
#import "FeedTVC.h"
#import "DisplayShoutImageViewController.h"
#import "AFStreetShoutAPIClient.h"
#import "Constants.h"
#import "Reachability.h"
#import "GeneralUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageUtilities.h"
#import "SessionUtilities.h"

#define SHOUT_BUTTON_SIZE 72.0

@interface NavigationViewController ()

@property (nonatomic, weak) UINavigationController *feedNavigationController;
@property (nonatomic, weak) FeedTVC *feedTVC;
@property (nonatomic, weak) MapViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *createShoutButton;
@property (strong, nonatomic) UIAlertView *obsoleteAPIAlertView;

@end

@implementation NavigationViewController

- (void)viewDidLoad
{
    [ImageUtilities addInnerShadowToView:self.topContainerView];
    
    //Shout button drop shadow
    [ImageUtilities addDropShadowToView:self.createShoutButton];
    
    //Nav bar color
    NSArray *ver = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ([[ver objectAtIndex:0] intValue] >= 7) {
        self.navigationController.navigationBar.barTintColor = [ImageUtilities getShoutBlue];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.translucent = NO;
    }
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateUserInfo];
}

- (void) viewWillAppear:(BOOL)animated
{
    // Check if API obsolete
    [AFStreetShoutAPIClient checkAPIVersion:kApiVersion IsObsolete:^{
        [self createObsoleteAPIAlertView];
    }];
    
    //Nav bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self updateUserInfo];
}

- (void)pullShoutsInZone:(NSArray *)mapBounds
{
    if (!self.activityView) {
        self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }

    self.activityView.center = self.feedTVC.view.center;
    
    [self.activityView startAnimating];
        
    [self.feedTVC.view addSubview:self.activityView];
    
    self.feedTVC.shouts = @[@"Loading"];
    
    [MapRequestHandler pullShoutsInZone:mapBounds AndExecuteSuccess:^(NSArray *shouts) {
        [self.activityView stopAnimating];
        self.mapViewController.shouts = shouts;
        self.feedTVC.shouts = shouts;
    } failure:^{
        [self.activityView stopAnimating];
        self.feedTVC.shouts = @[@"No connection"];
    }];
}

- (void)handleShoutRedirection:(Shout *)shout
{
    NSMutableArray *newShouts = [NSMutableArray arrayWithObjects:shout, nil];
    [self manuallyUpdateShoutsToShow:newShouts];
    
    [self.mapViewController startShoutSelectionModeInMapViewController:shout];
}

- (void)manuallyUpdateShoutsToShow:(NSArray *)newShouts
{
    self.mapViewController.shouts = newShouts;
    self.feedTVC.shouts = newShouts;
}

- (void)showShoutViewControllerIfNeeded:(Shout *)shout
{
    if ([[self.feedNavigationController topViewController] isKindOfClass:[ShoutViewController class]]) {
        ((ShoutViewController *)[self.feedNavigationController topViewController]).shout = shout;
    } else {
        [self.feedTVC performSegueWithIdentifier:@"Show Shout" sender:shout];
    }
}

- (void)shoutSelectionComingFromFeed:(Shout *)shout
{
    [self.mapViewController startShoutSelectionModeInMapViewController:shout];
}

- (void)refreshShouts
{
    [self.mapViewController refreshShoutsFromMapViewController];
}

- (void)onShoutCreated:(Shout *)shout
{
    [self handleShoutRedirection:shout];
    
    [self.mapViewController animateMapWhenShoutSelected:shout];
}

- (void)onShoutNotificationPressed:(Shout *)shout
{
    [self handleShoutRedirection:shout];
    
    [self.mapViewController animateMapWhenShoutSelected:shout];
}

- (void)dismissShoutViewControllerIfNeeded
{
    if ([[self.feedNavigationController topViewController] isKindOfClass:[ShoutViewController class]]) {
        [self.feedNavigationController popViewControllerAnimated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"mapViewController"]) {
        self.mapViewController = (MapViewController *) [segue destinationViewController];
        self.mapViewController.mapVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"feedNavigationController"]) {
        self.feedNavigationController = (UINavigationController *)[segue destinationViewController];
        self.feedTVC = (FeedTVC *) [self.feedNavigationController topViewController];
        self.feedTVC.feedTVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"Create Shout Modal"]) {
        MKUserLocation *myLocation = (MKUserLocation *)sender;
        
        ((CreateShoutViewController *)[segue destinationViewController]).myLocation = myLocation.location;
        ((CreateShoutViewController *)[segue destinationViewController]).shoutLocation = myLocation.location;
        ((CreateShoutViewController *)[segue destinationViewController]).createShoutVCDelegate = self;
    }
    
    if ([segueName isEqualToString: @"Display Shout Image"]) {
        Shout *imageShout = (Shout *)sender;
        
        ((DisplayShoutImageViewController *)[segue destinationViewController]).shout = imageShout;
    }
    
    if ([segueName isEqualToString: @"Settings Push Segue"]) {
        ((SettingsViewController *) [segue destinationViewController]).settingsViewControllerDelegate = self;
    }
}

- (void)displayShoutImage:(Shout *)imageShout
{
    [self performSegueWithIdentifier:@"Display Shout Image" sender:imageShout];
}
- (IBAction)createShoutButtonClicked:(id)sender {
    
    if (![SessionUtilities loggedIn]){
        [SessionUtilities redirectToSignIn];
        return;
    }
    
    NSString *errorMessageTitle;
    NSString *errorMessageBody;
    
    if ([GeneralUtilities connected]) {
        MKUserLocation *myLocation = [self getMyLocation];
        
        if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0 &&
            myLocation.coordinate.longitude != -180 && myLocation.coordinate.latitude != -180) {
            [self performSegueWithIdentifier:@"Create Shout Modal" sender:myLocation];
            return;
        } else {
            errorMessageTitle = NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment");
            errorMessageBody = NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment");
        }
    } else {
        errorMessageTitle = NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment");
    }
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:errorMessageTitle
                                                      message:errorMessageBody
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
}

- (MKUserLocation *)getMyLocation
{
    return self.mapViewController.mapView.userLocation;
}

- (void)settingsButtonClicked
{
    if (![SessionUtilities loggedIn]){
        [SessionUtilities redirectToSignIn];
        return;
    }
    
    if ([GeneralUtilities connected]) {
        [self performSegueWithIdentifier:@"Settings Push Segue" sender:nil];
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")
                                                          message:nil
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
}

- (void)updateUserInfo
{
    MKUserLocation *myLocation = self.mapViewController.mapView.userLocation;
    
    if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0) {
        //TODO: Method to update user info
//            [AFStreetShoutAPIClient sendDeviceInfoWithLat:myLocation.location.coordinate.latitude Lng:myLocation.location.coordinate.longitude];
        //TODO: update user info
    } else {
        NSLog(@"Could not send device info");
    }
}

- (void)endShoutSelectionModeInMapViewController
{
    [self.mapViewController endShoutSelectionModeInMapViewController];
}

- (void)animateMapWhenZoomOnShout:(Shout *)shout
{
    [self.mapViewController animateMapWhenZoomOnShout:shout];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.obsoleteAPIAlertView) {
        [GeneralUtilities redirectToAppStore];
        [self createObsoleteAPIAlertView];
    }
}

- (void)createObsoleteAPIAlertView
{
    self.obsoleteAPIAlertView = [[UIAlertView alloc] initWithTitle:@"Obsolete API"
                                                           message:@"Download the new version"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
    [self.obsoleteAPIAlertView show];
}

@end
