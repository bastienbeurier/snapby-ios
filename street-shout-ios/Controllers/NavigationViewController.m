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
@property (weak, nonatomic) IBOutlet UIView *bottomContainerView;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *createShoutButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) UIAlertView *obsoleteAPIAlertView;
@property (weak, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) Shout *redirectToShout;

@end

@implementation NavigationViewController

- (void)viewDidLoad
{
    //Status bar style  
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    //Buttons round corner
    NSUInteger buttonHeight = self.createShoutButton.bounds.size.height;
    self.createShoutButton.layer.cornerRadius = buttonHeight/2;
    self.moreButton.layer.cornerRadius = buttonHeight/2;
    
    self.mapView = self.mapViewController.mapView;
    
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    // Check if API obsolete
    [AFStreetShoutAPIClient checkAPIVersion:kApiVersion IsObsolete:^{
        [self createObsoleteAPIAlertView];
    }];
    
    //Nav bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [self refreshShouts];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.redirectToShout) {
        [self showShoutViewController:self.redirectToShout];
        self.redirectToShout = nil;
    }
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self updateUserInfo];
    
    [super viewDidDisappear:animated];
}

//Hack to remove the selection highligh from the cell during the back animation
- (void)redisplayFeed
{
    self.feedTVC.shouts = self.feedTVC.shouts;
}

- (void)refreshShouts
{
    [self pullShoutsInZone:[LocationUtilities getMapBounds:self.mapViewController.mapView]];
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
        
        shouts = [GeneralUtilities checkForRemovedShouts:shouts];
        
        self.mapViewController.shouts = shouts;
        self.feedTVC.shouts = shouts;
    } failure:^{
        [self.activityView stopAnimating];
        self.feedTVC.shouts = @[@"No connection"];
    }];
}

- (void)shoutSelectionComingFromFeed:(Shout *)shout
{
    [self showShoutViewController:shout];
}

- (void)shoutSelectionComingFromMap:(Shout *)shout
{
    [self showShoutViewController:shout];
}

- (void)showShoutViewController:(Shout *)shout
{
    [self performSegueWithIdentifier:@"Shout Push Segue" sender:shout];
}

- (void)onShoutCreated:(Shout *)shout
{
    [self handleShoutRedirection:shout];
}

- (void)onShoutNotificationPressed:(Shout *)shout
{
    [self handleShoutRedirection:shout];
}

- (void)handleShoutRedirection:(Shout *)shout
{
    self.redirectToShout = shout;
    [LocationUtilities animateMap:self.mapView ToLatitude:shout.lat Longitude:shout.lng WithDistance:kDistanceWhenRedirectedFromCreateShout Animated:NO];
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
    
    if ([segueName isEqualToString: @"Settings Push Segue"]) {
        ((SettingsViewController *) [segue destinationViewController]).settingsViewControllerDelegate = self;
    }
    
    if ([segueName isEqualToString: @"Shout Push Segue"]) {
        ((ShoutViewController *) [segue destinationViewController]).shout = (Shout *)sender;
        ((ShoutViewController *) [segue destinationViewController]).shoutVCDelegate = self;
        [self.mapViewController deselectAnnotationsOnMap];
    }
}

- (IBAction)createShoutButtonClicked:(id)sender {
    
    if (![SessionUtilities isSignedIn]){
        [SessionUtilities redirectToSignIn];
        return;
    }
    
    NSString *errorMessageTitle;
    NSString *errorMessageBody;
    
    if ([GeneralUtilities connected]) {
        MKUserLocation *myLocation = [self getMyLocation];
        
        if (myLocation && [LocationUtilities userLocationValid:myLocation]) {
            [self performSegueWithIdentifier:@"Create Shout Modal" sender:myLocation];
            return;
        } else {
            errorMessageTitle = NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment");
            errorMessageBody = NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment");
        }
    } else {
        errorMessageTitle = NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment");
    }
    
    [GeneralUtilities showMessage:errorMessageBody withTitle:errorMessageTitle];
}

- (MKUserLocation *)getMyLocation
{
    return self.mapViewController.mapView.userLocation;
}

- (IBAction)moreButtonClicked:(id)sender {
    if (![SessionUtilities isSignedIn]){
        [SessionUtilities redirectToSignIn];
        return;
    }
    
    if ([GeneralUtilities connected]) {
        [self performSegueWithIdentifier:@"Settings Push Segue" sender:nil];
    } else {
        [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
    }
}

- (void)updateUserInfo
{
    MKUserLocation *myLocation = self.mapViewController.mapView.userLocation;
    
    if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0) {
        [AFStreetShoutAPIClient updateUserInfoWithLat:myLocation.location.coordinate.latitude Lng:myLocation.location.coordinate.longitude];
    } else {
        NSLog(@"Could not send device info");
    }
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
    self.obsoleteAPIAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"obsolete_api_error_title", @"Strings", @"comment")
                                                           message:NSLocalizedStringFromTable (@"obsolete_api_error_message", @"Strings", @"comment")
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
    [self.obsoleteAPIAlertView show];
}

@end
