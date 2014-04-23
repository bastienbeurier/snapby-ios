//
//  ProfileViewController.m
//  snapby-ios
//
//  Created by Baptiste Truchot on 3/26/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//


#import "ProfileViewController.h"
#import "ImageUtilities.h"
#import "AFSnapbyAPIClient.h"
#import "SessionUtilities.h"
#import "GeneralUtilities.h"
#import "UIImageView+AFNetworking.h"
#import "Constants.h"
#import "SettingsViewController.h"
#import "HackClipView.h"
#import "MKPointAnnotation+SnapbyPointAnnotation.h"
#import "ExploreSnapbyViewController.h"
#import "LocationUtilities.h"

#define PROFILE_IMAGE_SIZE 75

@interface ProfileViewController () <GMSMapViewDelegate>

@property (strong, nonatomic) User *profileUser;

@property (weak, nonatomic) IBOutlet UILabel *snapbyCount;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *likedCount;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet HackClipView *scrollViewContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *snapbies;
@property (nonatomic) NSUInteger scrollViewWidth;
@property (nonatomic) NSUInteger scrollViewHeight;
@property (strong, nonatomic) NSMutableDictionary *displayedSnapbies;
@property (weak, nonatomic) Snapby *previouslySelectedSnapby;
@property (nonatomic) NSInteger automaticScrolling;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet UIView *userInfoContainer;
@property (nonatomic) int currentSelectedZIndex;



@end


@implementation ProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = NO;
    self.mapView.settings.scrollGestures = NO;
    self.mapView.settings.zoomGestures = NO;
    self.mapView.settings.tiltGestures = NO;
    self.mapView.settings.rotateGestures = NO;
    
    self.profilePictureView.layer.cornerRadius = PROFILE_IMAGE_SIZE/2;
    self.profilePictureView.clipsToBounds = YES;
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    self.currentSelectedZIndex = 0;
    
    //Equivalent of NO
    self.automaticScrolling = -1;
    
    [self refreshSnapbies];
}

- (void)refreshSnapbies
{
    //TODO Start loading
    
    [AFSnapbyAPIClient getSnapbies:[SessionUtilities getCurrentUser].identifier page:1 pageSize:100 andExecuteSuccess:^(NSArray *snapbies) {
        //TODO: handle case no snapby
        //TODO: stoploading
        [self moveMapToFirstSnapby:[snapbies objectAtIndex:0]];
        
        self.snapbies = snapbies;
    } failure:^{
        //TODO Stop loading dialog and display no connection
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self getProfileInfo];
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(self.userInfoContainer.frame.size.height, 0, self.scrollViewContainer.frame.size.height, 0);
    self.mapView.padding = edgeInsets;
}

- (void)setSnapbies:(NSArray *)snapbies
{
    _snapbies = snapbies;
    [self displaySnapbies:snapbies];
    
    NSUInteger numberPages = self.snapbies.count;
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < numberPages; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    
    if (self.scrollViewWidth == 0 && self.scrollViewHeight == 0) {
        self.scrollViewWidth = CGRectGetWidth(self.scrollView.frame);
        self.scrollViewHeight = CGRectGetHeight(self.scrollView.frame);
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollViewWidth * numberPages, self.scrollViewHeight);
    
    [self loadSnapbiesAndUpdateMarker];
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    NSUInteger snapbyId = [marker.title intValue];
    
    int i = 0;
    NSUInteger length = [self.snapbies count];
    
    for (i = 0; i < length; i = i + 1) {
        if (((Snapby *)[self.snapbies objectAtIndex:i]).identifier == snapbyId) {
            if (i != [self getScrollViewPage]) {
                self.automaticScrolling = (NSInteger) i;
                [self gotoPage:i animated:YES];
                break;
            }
        }
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Snapby Push Segue"]) {
        ((SnapbyViewController *) [segue destinationViewController]).snapby = (Snapby *)sender;
    }
}


- (void)displaySnapbies:(NSArray *)snapbies
{
    //Remove annotations that are not on screen anymore
    [self.mapView clear];
    
    [self.displayedSnapbies removeAllObjects];
    
    for (Snapby *snapby in snapbies) {
        NSString *snapbyKey = [NSString stringWithFormat:@"%lu", (unsigned long)snapby.identifier];
        
        CLLocationCoordinate2D markerCoordinate;
        markerCoordinate.latitude = snapby.lat;
        markerCoordinate.longitude = snapby.lng;
        
        GMSMarker *marker = [GMSMarker markerWithPosition:markerCoordinate];
        marker.title = [NSString stringWithFormat:@"%lu", snapby.identifier];
        marker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:NO]];

        marker.map = self.mapView;
        
        [self.displayedSnapbies setObject:marker forKey:snapbyKey];
    }
}

- (NSMutableDictionary *)displayedSnapbies
{
    if (!_displayedSnapbies) _displayedSnapbies = [[NSMutableDictionary alloc] init];
    return _displayedSnapbies;
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
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (controller.view.superview == nil)
    {
        controller.view.frame = CGRectMake((self.scrollViewWidth) * page, 0, self.scrollViewWidth, self.scrollViewHeight);
        
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
    }
}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.automaticScrolling > -1 && self.automaticScrolling != [self getScrollViewPage]) {
        return;
    }
    
    self.automaticScrolling = -1;
    
    [self loadSnapbiesAndUpdateMarker];
}

- (void)loadSnapbiesAndUpdateMarker
{
    NSUInteger page = [self getScrollViewPage];
    
    Snapby *snapby = ((Snapby *)[self.snapbies objectAtIndex:page]);
    
    [self animateMapToLat:snapby.lat lng:snapby.lng];
    
    NSString *snapbyKey = [NSString stringWithFormat:@"%lu", snapby.identifier];
    
    GMSMarker *marker = [self.displayedSnapbies objectForKey:snapbyKey];
    
    marker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:YES]];
    marker.zIndex = self.currentSelectedZIndex + 1;
    self.currentSelectedZIndex = self.currentSelectedZIndex + 1;
    marker.map = self.mapView;
    
    if (self.previouslySelectedSnapby != nil && self.previouslySelectedSnapby.identifier != snapby.identifier) {
        GMSMarker *oldMarker = [self.displayedSnapbies objectForKey:[NSString stringWithFormat:@"%lu", self.previouslySelectedSnapby.identifier]];
        oldMarker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:NO]];
        oldMarker.map = self.mapView;
    }
    
    self.previouslySelectedSnapby = snapby;
    
    [self loadScrollViewWithPage:page - 3];
    [self loadScrollViewWithPage:page - 2];
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:page + 2];
    [self loadScrollViewWithPage:page + 3];

}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollViewWidth;
    return floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (void)gotoPage:(NSUInteger)page animated:(BOOL)animated
{
	// update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (IBAction)onScrollViewClicked:(id)sender {
    Snapby *snapby = [self.snapbies objectAtIndex:[self getScrollViewPage]];
    [self performSegueWithIdentifier:@"Snapby Push Segue" sender:snapby];
}

- (void)animateMapToLat:(float)lat lng:(float)lng
{
    CLLocationCoordinate2D snapbyCoordinate;
    snapbyCoordinate.latitude = lat;
    snapbyCoordinate.longitude = lng;
    
    [self.mapView animateToLocation:snapbyCoordinate];
}
     
- (void)moveMapToFirstSnapby:(Snapby *)snapby
{
    CLLocationCoordinate2D location;
    location.latitude = snapby.lat;
    location.longitude = snapby.lng;
    
    [self.mapView moveCamera:[GMSCameraUpdate setTarget:location zoom:kZoomAtStartup]];
}


// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------

// Get all profile info to display
- (void)getProfileInfo
{
    typedef void (^SuccessBlock)(User *, NSInteger, NSInteger, BOOL);
    SuccessBlock successBlock = ^(User * user, NSInteger nbFollowers, NSInteger nbFollowedUsers, BOOL isFollowedByCurrentUser)
    {
        self.profileUser = user;
        self.snapbyCount.text = [NSString stringWithFormat: @"%lu", user.snapbyCount];
        self.likedCount.text = [NSString stringWithFormat: @"%lu", user.likedSnapbies];
        self.userName.text = user.username;
        
        // Get the profile picture (and avoid caching)
        //TODO: Move somewhere elsewhere
        [ImageUtilities setWithoutCachingImageView:self.profilePictureView withURL:[User getUserProfilePictureURLFromUserId:self.profileUser.identifier]];
    };
    
    void (^failureBlock)() = ^() {
        //TODO handle profile did not load
    };
    
    [AFSnapbyAPIClient getOtherUserInfo:self.profileUserId success:successBlock failure:failureBlock];
}

@end
