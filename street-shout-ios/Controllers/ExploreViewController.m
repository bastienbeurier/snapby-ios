//
//  ExploreViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ExploreViewController.h"
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
#import "MBProgressHUD.h"
#import "TrackingUtilities.h"
#import "LocationUtilities.h"

#define SHOUT_BUTTON_SIZE 72.0

@interface ExploreViewController ()

@property (nonatomic, weak) UINavigationController *feedNavigationController;
@property (nonatomic, weak) FeedTVC *feedTVC;
@property (nonatomic, weak) MapViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIView *bottomContainerView;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *createShoutButton;
@property (weak, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) MapRequestHandler *mapRequestHandler;

@end

@implementation ExploreViewController

- (void)viewDidLoad
{
    //Buttons round corner
    NSUInteger buttonHeight = self.createShoutButton.bounds.size.height;
    self.createShoutButton.layer.cornerRadius = buttonHeight/2;    
    self.mapView = self.mapViewController.mapView;
    
    self.mapRequestHandler = [MapRequestHandler new];
    
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    // start updating map and stop location manager
    self.mapView.showsUserLocation = YES;
    [self.exploreControllerdelegate stopLocationUpdate];
    
    //Status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    //Nav bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    //Redirect to recently created shout
    if (self.redirectToShout) {
        [self handleShoutRedirection:self.redirectToShout];
        self.redirectToShout = nil;
    }
    
    //Redirect to notification shout
     NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *notificationShoutId = [prefs objectForKey:NOTIFICATION_SHOUT_ID_PREF];
    [prefs removeObjectForKey:NOTIFICATION_SHOUT_ID_PREF];
    
    if (notificationShoutId) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [AFStreetShoutAPIClient getShoutInfo:[notificationShoutId integerValue] AndExecuteSuccess:^(Shout *shout) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            //Mixpanel tracking
            [TrackingUtilities trackDisplayShout:shout withSource:@"Notification"];
            
            [self handleShoutRedirection:shout];
        } failure:^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self updateUserInfo];
    
    // stop updating user location
    self.mapView.showsUserLocation = NO;
    [self.exploreControllerdelegate startLocationUpdate];
    
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
    
    __weak typeof(self) weakSelf = self;
    [self.mapRequestHandler addMapRequest:mapBounds AndExecuteSuccess:^(NSArray *shouts) {
        
        [weakSelf.activityView stopAnimating];
        
        shouts = [GeneralUtilities checkForRemovedShouts:shouts];
        
        weakSelf.mapViewController.shouts = shouts;
        weakSelf.feedTVC.shouts = shouts;
    } failure:^{
        [weakSelf.activityView stopAnimating];
        weakSelf.feedTVC.shouts = @[@"No connection"];
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

- (void)onShoutNotificationPressedWhileAppInNavigationVC:(Shout *)shout
{
    [self handleShoutRedirection:shout];
}

- (void)showShoutViewController:(Shout *)shout
{
    [self performSegueWithIdentifier:@"Shout Push Segue" sender:shout];
}


- (void)handleShoutRedirection:(Shout *)shout
{
    [self showShoutViewController:shout];
    
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
    
    [self.exploreControllerdelegate moveToImagePickerController];
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

- (void)updateMapLocationtoLat:(double)lat lng:(double)lng
{
    [LocationUtilities animateMap:self.mapViewController.mapView ToLatitude:lat Longitude:lng WithDistance:kDistanceWhenMapDisplayShoutClicked Animated:YES];
}

@end
