//
//  MapViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "ExploreViewController.h"
#import "LocationUtilities.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "TrackingUtilities.h"
#import "HackClipView.h"
#import "ApiUtilities.h"
#import "MBProgressHUD.h"
#import "SessionUtilities.h"

#define MORE_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"navigate_to_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"share_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"report_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"remove_snapby", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"abusive_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"spam_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"privacy_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"inaccurate_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_5 NSLocalizedStringFromTable (@"other_content", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

#define PER_PAGE 20

@interface ExploreViewController () <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, strong) NSArray *snapbies;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (nonatomic) BOOL didInitializedExplore;
@property (nonatomic) NSInteger page;
@property (nonatomic) BOOL noMoreSnapbyToPull;
@property (nonatomic) BOOL pullingMoreSnapbies;
@property (nonatomic) NSUInteger lastPageScrolled;
@property (strong, nonatomic) UIActionSheet *flagActionSheet;
@property (strong, nonatomic) UIActionSheet *moreActionSheet;
@property (strong, nonatomic) GMSMarker *snapbyMarker;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *myLocation;
@property (nonatomic, strong) User* currentUser;
@property(nonatomic) BOOL firstExplorePositionSet;
@property (nonatomic, strong) NSMutableSet *myLikes;
@property (nonatomic, strong) NSMutableSet *myComments;

@end

@implementation ExploreViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [ImageUtilities getSnapbyPink];
    
    [ImageUtilities outerGlow:self.cameraButton];
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = NO;
    self.mapView.settings.scrollGestures = NO;
    self.mapView.settings.zoomGestures = NO;
    self.mapView.settings.tiltGestures = NO;
    self.mapView.settings.rotateGestures = NO;
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    self.didInitializedExplore = NO;
    
    self.page = 1;
    self.noMoreSnapbyToPull = NO;
    self.pullingMoreSnapbies = NO;
    
    self.firstExplorePositionSet = NO;
    
    self.currentUser = [SessionUtilities getCurrentUser];
    
    [self allocAndInitLocationManager];
    
    [self getMyLikesAndComments];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)onLocationObtained
{
    [self moveMapToMyLocationAndLoadSnapbies];
}

- (void)refreshSnapbies
{
    [self loadingSnapbiesUI];
    
    CLLocation *myLocation = self.myLocation;
    
    [ApiUtilities pullLocalSnapbiesWithLat:myLocation.coordinate.latitude Lng:myLocation.coordinate.longitude page:1 pageSize:PER_PAGE AndExecuteSuccess:^(NSArray *snapbies, NSInteger page) {
        self.snapbies = snapbies;
    } failure:^{
        [self noConnectionUI];
    }];
}

- (void)loadingSnapbiesUI
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)loadingMoreSnapbiesUI
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)noSnapbiesUI
{

}

- (void)noConnectionUI
{

}

- (void)noLocationUI
{

}

- (void)displaySnapbiesUI
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
}

- (void)setSnapbies:(NSArray *)snapbies
{
    _snapbies = snapbies;
    self.page = 1;
    self.noMoreSnapbyToPull = NO;
    self.pullingMoreSnapbies = NO;
    
    if ([snapbies count] < PER_PAGE) {
        self.noMoreSnapbyToPull = YES;
    }
    
    if ([snapbies count] == 0) {
        [self noSnapbiesUI];
        return;
    }

    NSUInteger numberPages = self.snapbies.count;
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < numberPages; i++)
    {
        [controllers addObject:[NSNull null]];
    }
    
    self.viewControllers = controllers;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height * numberPages);
    
    [self displaySnapbiesUI];
    
    [self loadSnapbiesAndUpdateMarker];
}

- (void) moveMapToMyLocationAndLoadSnapbies
{
    CLLocation *myLocation = self.myLocation;
    if (myLocation != nil && myLocation.coordinate.latitude != 0 && myLocation.coordinate.longitude != 0) {
        CLLocationCoordinate2D location;
        location.latitude = myLocation.coordinate.latitude;
        location.longitude = myLocation.coordinate.longitude;
        
        [self.mapView moveCamera:[GMSCameraUpdate setTarget:location zoom:kZoomAtStartup]];
        
        GMSMarker *myLocationMarker = [GMSMarker markerWithPosition:location];
        myLocationMarker.icon = [UIImage imageNamed:@"my_location_marker"];
        myLocationMarker.map = self.mapView;
        
        [self refreshSnapbies];
    } else {
        [self noLocationUI];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Comment Push Segue From Explore"]) {
        ((CommentsViewController *) [segue destinationViewController]).snapby = (Snapby *)sender;
        ((CommentsViewController *) [segue destinationViewController]).userLocation = self.myLocation;
        ((CommentsViewController *) [segue destinationViewController]).commentsVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"Camera Push Segue"]) {
        ((CameraViewController *) [segue destinationViewController]).cameraVCDelegate = self;
    }
}

//Scrollview related methods

- (void)loadScrollViewWithPage:(NSUInteger)page
{
    if (page >= self.snapbies.count) {
        return;
    }
    
    // replace the placeholder if necessary
    ExploreSnapbyViewController *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null])
    {
        controller = [[ExploreSnapbyViewController alloc] initWithSnapby:[self.snapbies objectAtIndex:page]];
        controller.exploreSnapbyVCDelegate = self;
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (controller.view.superview == nil)
    {
        controller.view.frame = CGRectMake(0, self.scrollView.frame.size.height * page, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
        
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
    }
}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger page = [self getScrollViewPage];
    
    //Skip if method already called for this page or if scrolling automatically (when user clicks on marker)
    if (page == self.lastPageScrolled) {
        return;
    }
    
    self.lastPageScrolled = page;
    
    [self loadSnapbiesAndUpdateMarker];
}

- (void)loadSnapbiesAndUpdateMarker
{
    NSUInteger page = [self getScrollViewPage];
    
    Snapby *snapby = ((Snapby *)[self.snapbies objectAtIndex:page]);
    
    CLLocationCoordinate2D snapbyLocation;
    
    snapbyLocation.latitude = snapby.lat;
    snapbyLocation.longitude = snapby.lng;
    
    if (!self.snapbyMarker) {
        self.snapbyMarker = [GMSMarker markerWithPosition:snapbyLocation];
        self.snapbyMarker.icon = [UIImage imageNamed:@"snapby-marker"];
    } else {
        self.snapbyMarker.position = snapbyLocation;
    }
    
    self.snapbyMarker.map = self.mapView;
    
    [self loadScrollViewWithPage:page - 2];
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:page + 2];
    
}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageHeight = self.scrollView.frame.size.height;
    return MIN(floor((self.scrollView.contentOffset.y - pageHeight / 2) / pageHeight) + 1, self.snapbies.count - 1);
}

- (IBAction)onScrollViewClicked:(id)sender {
    }

- (void)moreButtonClicked:(Snapby *)snapby
{
    if(snapby.userId == [SessionUtilities getCurrentUser].identifier) {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, MORE_ACTION_SHEET_OPTION_3, MORE_ACTION_SHEET_OPTION_4, nil];
    } else {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, MORE_ACTION_SHEET_OPTION_3, nil];
    }
    
    [self.moreActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUInteger page = [self getScrollViewPage];
    Snapby *snapby = [self.snapbies objectAtIndex:page];
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:FLAG_ACTION_SHEET_CANCEL]) {
        return;
    }
    
    if (actionSheet == self.moreActionSheet) {
        if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_1]) {
            Class mapItemClass = [MKMapItem class];
            if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
                // Create an MKMapItem to pass to the Maps app
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(snapby.lat, snapby.lng);
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                               addressDictionary:nil];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [mapItem setName:@"Snapby"];
                // Pass the map item to the Maps app
                [mapItem openInMapsWithLaunchOptions:nil];
            }
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_2]) {
            UIImage *image = ((ExploreSnapbyViewController * )[self.viewControllers objectAtIndex:page]).imageView.image;
            [self presentViewController:[GeneralUtilities getShareViewController:image] animated:YES completion:nil];
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_3]) {
            self.flagActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable (@"flag_action_sheet_title", @"Strings", @"comment")
                                                               delegate:self
                                                      cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:FLAG_ACTION_SHEET_OPTION_1, FLAG_ACTION_SHEET_OPTION_2, FLAG_ACTION_SHEET_OPTION_3, FLAG_ACTION_SHEET_OPTION_4, FLAG_ACTION_SHEET_OPTION_5, nil];
            [self.flagActionSheet showInView:[UIApplication sharedApplication].keyWindow];
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_4]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [ApiUtilities removeSnapby: snapby success:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self refreshSnapbies];
            } failure:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_delete_snapby", @"Strings", @"comment") withTitle:nil];
            }];
        }
    } else if (actionSheet == self.flagActionSheet) {
        
        NSString *motive = nil;
        
        switch (buttonIndex) {
            case 0:
                motive = @"abuse";
                break;
            case 1:
                motive = @"spam";
                break;
            case 2:
                motive = @"privacy";
                break;
            case 3:
                motive = @"inaccurate";
                break;
            case 4:
                motive = @"other";
                break;
        }
        
        [ApiUtilities reportSnapby:snapby.identifier withFlaggerId:[SessionUtilities getCurrentUser].identifier withMotive:motive AndExecute:nil Failure:^{
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_report_snapby", @"Strings", @"comment") withTitle:nil];
        }];
        
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"flag_thanks_alert", @"Strings", @"comment") withTitle:nil];
    }
}

- (BOOL)snapbyHasBeenLiked:(NSUInteger)snapbyId
{
    return [self.myLikes containsObject:[NSNumber numberWithLong:snapbyId]];
}

- (void)onSnapbyLiked:(Snapby *)snapby
{
    [self.myLikes addObject:[NSNumber numberWithLong:snapby.identifier]];
}

- (void)onSnapbyUnliked:(Snapby *)snapby
{
    [self.myLikes removeObject:[NSNumber numberWithLong:snapby.identifier]];
}

- (BOOL)isSnapbyCommented:(NSUInteger)snapbyId
{
    return [self.myComments containsObject:[NSNumber numberWithLong:snapbyId]];
}

- (void)commentButtonClicked:(Snapby *)snapby
{
    [self performSegueWithIdentifier:@"Comment Push Segue From Explore" sender:snapby];
}

- (void)updateCommentCount:(NSInteger)count
{
    ExploreSnapbyViewController *vc = [self.viewControllers objectAtIndex:[self getScrollViewPage]];
    [vc updateCommentCount:count];
}

- (void)userDidComment:(Snapby *)snapby count:(NSUInteger)count
{
    ExploreSnapbyViewController *vc = [self.viewControllers objectAtIndex:[self getScrollViewPage]];
    [vc userDidComment];
    [self.myComments addObject:[NSNumber numberWithLong:snapby.identifier]];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    self.scrollView.alpha = 1;
    [UIView animateWithDuration:0.4 animations:^(void) {
        self.scrollView.alpha = 1;
    }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.scrollView.layer removeAllAnimations];
    self.scrollView.alpha = 0.1;
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
        [self onLocationObtained];
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

- (IBAction)cameraButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Camera Push Segue" sender:nil];
}

- (CLLocation *)getMyLocation
{
    return self.myLocation;
}

- (void)onSnapbyCreated
{
    [self gotoPage:0 animated:NO];
    [self moveMapToMyLocationAndLoadSnapbies];
}

- (void)gotoPage:(NSUInteger)page animated:(BOOL)animated
{
    // update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = 0;
    bounds.origin.y = CGRectGetHeight(bounds) * page;

    [self.scrollView scrollRectToVisible:bounds animated:animated];
}



@end
