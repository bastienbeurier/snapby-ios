//
//  ExploreViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "ExploreViewController.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "Snapby.h"
#import "AFSnapbyAPIClient.h"
#import "Constants.h"
#import "Reachability.h"
#import "GeneralUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageUtilities.h"
#import "SessionUtilities.h"
#import "MBProgressHUD.h"
#import "TrackingUtilities.h"
#import "LocationUtilities.h"

#define SNAPBY_BUTTON_SIZE 72.0

@interface ExploreViewController ()

@property (nonatomic, weak) MapViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *createSnapbyButton;
@property (weak, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) MapRequestHandler *mapRequestHandler;

@end

@implementation ExploreViewController

- (void)viewDidLoad
{
    //Buttons round corner
    NSUInteger buttonHeight = self.createSnapbyButton.bounds.size.height;
    self.createSnapbyButton.layer.cornerRadius = buttonHeight/2;    
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
    //Redirect to recently created snapby
    if (self.redirectToSnapby) {
        [self handleSnapbyRedirection:self.redirectToSnapby];
        self.redirectToSnapby = nil;
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

- (void)refreshSnapbies
{
    [self pullSnapbiesInZone:[LocationUtilities getMapBounds:self.mapViewController.mapView]];
}

- (void)pullSnapbiesInZone:(NSArray *)mapBounds
{
    if (!self.activityView) {
        self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.mapRequestHandler addMapRequest:mapBounds AndExecuteSuccess:^(NSArray *snapbies) {
        
        [weakSelf.activityView stopAnimating];
        
        snapbies = [GeneralUtilities checkForRemovedSnapbies:snapbies];
        
        weakSelf.mapViewController.snapbies = snapbies;
    } failure:^{
        [weakSelf.activityView stopAnimating];
    }];
}


- (void)snapbySelectionComingFromMap:(Snapby *)snapby
{
    [self showSnapbyViewController:snapby];
}

- (void)showSnapbyViewController:(Snapby *)snapby
{
    [self performSegueWithIdentifier:@"Snapby Push Segue" sender:snapby];
}


- (void)handleSnapbyRedirection:(Snapby *)snapby
{
    [self showSnapbyViewController:snapby];
    
    [LocationUtilities animateMap:self.mapView ToLatitude:snapby.lat Longitude:snapby.lng WithDistance:kDistanceWhenRedirectedFromCreateSnapby Animated:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"mapViewController"]) {
        self.mapViewController = (MapViewController *) [segue destinationViewController];
        self.mapViewController.mapVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"Snapby Push Segue"]) {
        ((SnapbyViewController *) [segue destinationViewController]).snapby = (Snapby *)sender;
        ((SnapbyViewController *) [segue destinationViewController]).currentUser = self.currentUser;
        ((SnapbyViewController *) [segue destinationViewController]).snapbyVCDelegate = self;
        [self.mapViewController deselectAnnotationsOnMap];
    }
}

- (IBAction)createSnapbyButtonClicked:(id)sender {
    
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
        [AFSnapbyAPIClient updateUserInfoWithLat:myLocation.location.coordinate.latitude Lng:myLocation.location.coordinate.longitude];
    } else {
        NSLog(@"Could not send device info");
    }
}

- (void)updateMapLocationtoLat:(double)lat lng:(double)lng
{
    [LocationUtilities animateMap:self.mapViewController.mapView ToLatitude:lat Longitude:lng WithDistance:kDistanceWhenMapDisplaySnapbyClicked Animated:YES];
}

@end
