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

#define SHOUT_BUTTON_SIZE 72.0

@interface NavigationViewController ()

@property (nonatomic, weak) UINavigationController *feedNavigationController;
@property (nonatomic, weak) FeedTVC *feedTVC;
@property (nonatomic, weak) MapViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (strong, nonatomic) UIButton *shoutButton;

@end

@implementation NavigationViewController

- (void)viewDidLoad
{
    self.shoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shoutButton addTarget:self action:@selector(createShoutButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    CGRect viewBounds = [self.view bounds];
    self.shoutButton.frame = CGRectMake(viewBounds.size.width/2 - SHOUT_BUTTON_SIZE/2, viewBounds.size.height - SHOUT_BUTTON_SIZE - 5, SHOUT_BUTTON_SIZE, SHOUT_BUTTON_SIZE);
    self.shoutButton.layer.cornerRadius = SHOUT_BUTTON_SIZE/2;
    
    UIImage *shoutButtonImage = [UIImage imageNamed:@"shout-button-v9.png"];
    
    [self.shoutButton setImage:shoutButtonImage forState:UIControlStateNormal];
    
    [self.view addSubview:self.shoutButton];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Map shadow over feed
    [self.mapContainerView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.mapContainerView.layer setShadowOpacity:0.3];
    [self.mapContainerView.layer setShadowRadius:3.0];
    [self.mapContainerView.layer setShadowOffset:CGSizeMake(2, -2.0)];
    
    //Shout button drop shadow
    [self.shoutButton.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.shoutButton.layer setShadowOpacity:0.3];
    [self.shoutButton.layer setShadowRadius:1.5];
    self.shoutButton.clipsToBounds = NO;
    [self.shoutButton.layer setShadowOffset:CGSizeMake(2, -2)];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self sendDeviceInfo];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self sendDeviceInfo];
}

- (void)pullShoutsInZone:(NSArray *)mapBounds
{
    [self.feedTVC.activityIndicator startAnimating];
    self.feedTVC.shouts = @[@"Loading"];
    
    [MapRequestHandler pullShoutsInZone:mapBounds AndExecute:^(NSArray *shouts) {
        self.mapViewController.shouts = shouts;
        [self.feedTVC.activityIndicator stopAnimating];
        self.feedTVC.shouts = shouts;
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

- (void)dismissShoutViewControllerIfNeeded
{
    if ([[self.feedNavigationController topViewController] isKindOfClass:[ShoutViewController class]]) {
        [self.feedNavigationController popViewControllerAnimated:YES];
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
        UIImage *shoutImage = (UIImage *)sender;
        
        ((DisplayShoutImageViewController *)[segue destinationViewController]).shoutImage = shoutImage;
    }
    
    if ([segueName isEqualToString: @"Settings Push Segue"]) {
        ((SettingsTVC *) [segue destinationViewController]).settingsTVCDelegate = self;
    }
}

- (void)displayShoutImage:(UIImage *)image
{
    [self performSegueWithIdentifier:@"Display Shout Image" sender:image];
}

- (void)dismissCreateShoutModal
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createShoutButtonClicked
{
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

- (void)sendDeviceInfo
{
    MKUserLocation *myLocation = self.mapViewController.mapView.userLocation;
    
    if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0) {
            [AFStreetShoutAPIClient sendDeviceInfoWithLat:myLocation.location.coordinate.latitude
                                                      Lng:myLocation.location.coordinate.longitude];
    } else {
        NSLog(@"Could not send device info");
    }
}

@end
