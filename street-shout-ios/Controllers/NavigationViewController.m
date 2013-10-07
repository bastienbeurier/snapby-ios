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

#define SHOUT_BUTTON_SIZE 72.0

@interface NavigationViewController ()

@property (nonatomic, weak) UINavigationController *feedNavigationController;
@property (nonatomic, weak) FeedTVC *feedTVC;
@property (nonatomic, weak) MapViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIButton *createShoutButton;

@end

@implementation NavigationViewController

- (void)viewDidLoad
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(createShoutButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    CGRect viewBounds = [self.view bounds];
    button.frame = CGRectMake(viewBounds.size.width/2 - SHOUT_BUTTON_SIZE/2, viewBounds.size.height - SHOUT_BUTTON_SIZE - 5, SHOUT_BUTTON_SIZE, SHOUT_BUTTON_SIZE);
    
    button.clipsToBounds = YES;
    
    button.layer.cornerRadius = SHOUT_BUTTON_SIZE/2;
    
    UIImage *shoutButtonImage = [UIImage imageNamed:@"shout-button-v5.png"];
    
    [button setImage:shoutButtonImage forState:UIControlStateNormal];
    
    [self.view addSubview:button];
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
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

- (void)onShoutCreated:(Shout *)shout
{
    [self handleShoutRedirection:shout];
    
    [self.mapViewController animateMapWhenShout:shout selectedFrom:@"Create"];
}

- (void)onShoutNotificationPressed:(Shout *)shout
{
    [self handleShoutRedirection:shout];
    
    [self.mapViewController animateMapWhenShout:shout selectedFrom:@"Notification"];
}

- (void)handleShoutRedirection:(Shout *)shout
{
    NSMutableArray *newShouts = [NSMutableArray arrayWithObjects:shout, nil];
    [self manuallyUpdateShoutsToShow:newShouts];
    
    [self showShoutViewControllerIfNeeded:shout];
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

- (void)shoutDeselectedOnMap
{
    if ([[self.feedNavigationController topViewController] isKindOfClass:[ShoutViewController class]]) {
        [self.feedNavigationController popViewControllerAnimated:YES];
    }
}

- (void)shoutSelectedInFeed:(Shout *)shout
{
    [self.mapViewController animateMapWhenShout:shout selectedFrom:@"Feed"];
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
            NSLog(@"MyLocation longitude: %f - latitude: %f: ", myLocation.coordinate.longitude, myLocation.coordinate.latitude);
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

- (IBAction)myLocationButtonClicked:(id)sender {
    [self.mapViewController myLocationButtonClicked];
}

- (IBAction)dezoomButtonClicked:(id)sender {
        [self.mapViewController dezoomButtonClicked];
}

- (IBAction)settingsButtonClicked:(id)sender {
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
