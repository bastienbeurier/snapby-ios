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

@interface ProfileViewController () <MKMapViewDelegate>

@property (strong, nonatomic) User *profileUser;

@property (weak, nonatomic) IBOutlet UILabel *snapbyCount;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *likedCount;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet HackClipView *scrollViewContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *snapbies;
@property (nonatomic) NSUInteger scrollViewWidth;
@property (nonatomic) NSUInteger scrollViewHeight;
@property (strong, nonatomic) NSMutableDictionary *displayedSnapbies;
@property (weak, nonatomic) Snapby *previouslySelectedSnapby;
@property (nonatomic) BOOL automaticScrolling;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet UIView *userInfoContainer;



@end


@implementation ProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    self.profilePictureView.layer.cornerRadius = PROFILE_IMAGE_SIZE/2;
    self.profilePictureView.clipsToBounds = YES;
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    [self refreshSnapbies];
}

- (void)refreshSnapbies
{
    //TODO Start loading
    
    [AFSnapbyAPIClient getSnapbies:[SessionUtilities getCurrentUser].identifier page:1 pageSize:100 andExecuteSuccess:^(NSArray *snapbies) {
        //TODO: handle case no snapby
        //TODO: stoploading
        [self animatMaptOnFirstSnapby:[snapbies objectAtIndex:0]];
        
        self.snapbies = snapbies;
    } failure:^{
        //TODO Stop loading dialog and display no connection
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self getProfileInfo];
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
    
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
    [self loadScrollViewWithPage:2];
    [self loadScrollViewWithPage:3];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
    MKPointAnnotation *annotation = (MKPointAnnotation *)view.annotation;
    
    if ([annotation respondsToSelector:@selector(snapby)]) {
        Snapby *snapby = annotation.snapby;
        
        [self updateAnnotationPin:snapby selected:YES];
        
        if (self.previouslySelectedSnapby != nil && self.previouslySelectedSnapby.identifier != snapby.identifier) {
            [self updateAnnotationPin:self.previouslySelectedSnapby selected:NO];
        }
        
        self.previouslySelectedSnapby = snapby;
        
        int i = 0;
        NSUInteger length = [self.snapbies count];
        
        for (i = 0; i < length; i = i + 1) {
            if (((Snapby *)[self.snapbies objectAtIndex:i]).identifier == snapby.identifier) {
                if (i != [self getScrollViewPage]) {
                    [self gotoPage:i animated:YES];
                }
            }
        }
    }
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
    for (NSString *key in self.displayedSnapbies) {
        [self.mapView removeAnnotation:[self.displayedSnapbies objectForKey:key]];
    }
    
    [self.displayedSnapbies removeAllObjects];
    
    for (Snapby *snapby in snapbies) {
        NSString *snapbyKey = [NSString stringWithFormat:@"%lu", (unsigned long)snapby.identifier];
        
        CLLocationCoordinate2D annotationCoordinate;
        annotationCoordinate.latitude = snapby.lat;
        annotationCoordinate.longitude = snapby.lng;
        
        MKPointAnnotation *snapbyAnnotation = [[MKPointAnnotation alloc] init];
        snapbyAnnotation.coordinate = annotationCoordinate;
        
        snapbyAnnotation.snapby = snapby;
        [self.mapView addAnnotation:snapbyAnnotation];
        
        [self.displayedSnapbies setObject:snapbyAnnotation forKey:snapbyKey];
    }
}

- (void)updateAnnotationPin:(Snapby *)snapby selected:(BOOL)selected
{
    MKPointAnnotation *pointAnnotation = [self.displayedSnapbies objectForKey:[NSString stringWithFormat:@"%lu", snapby.identifier]];
    
    if (pointAnnotation == nil) {
        return;
    }
    
    MKAnnotationView *annotationView = [self.mapView viewForAnnotation:pointAnnotation];
    
    NSString *annotationPinImage = [GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:selected];
    
    annotationView.image = [UIImage imageNamed:annotationPinImage];
    //TODO set proper offset
    //    annotationView.centerOffset = CGPointMake(kSnapbyAnnotationOffsetX, kSnapbyAnnotationOffsetY);
}

- (NSMutableDictionary *)displayedSnapbies
{
    if (!_displayedSnapbies) _displayedSnapbies = [[NSMutableDictionary alloc] init];
    return _displayedSnapbies;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        MKPointAnnotation *annotation = (MKPointAnnotation *)annView.annotation;
        
        if ([annotation respondsToSelector:@selector(snapby)]) {
            [self updateAnnotationPin:annotation.snapby selected:NO];
        }
        
        CGRect endFrame = annView.frame;
        annView.frame = CGRectMake(endFrame.origin.x + endFrame.size.width/2, endFrame.origin.y + endFrame.size.height, 0, 0);
        [UIView animateWithDuration:0.3
                         animations:^{ annView.frame = endFrame; }];
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
    if (self.automaticScrolling) {
        return;
    }
    
    NSUInteger page = [self getScrollViewPage];
    
    Snapby *snapby = ((Snapby *)[self.snapbies objectAtIndex:page]);
    
    [self animateMapToLat:snapby.lat lng:snapby.lng];
    
    NSString *snapbyKey = [NSString stringWithFormat:@"%lu", snapby.identifier];
    
    MKPointAnnotation *shoutAnnotation = [self.displayedSnapbies objectForKey:snapbyKey];
    
    if (shoutAnnotation) {
        [self.mapView selectAnnotation:shoutAnnotation animated:NO];
    }
    
    [self loadScrollViewWithPage:page - 3];
    [self loadScrollViewWithPage:page - 2];
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:page + 2];
    [self loadScrollViewWithPage:page + 3];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.automaticScrolling) {
        self.automaticScrolling = NO;
        
        [self scrollViewDidScroll:scrollView];
    }
}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollViewWidth;
    return floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (void)gotoPage:(NSUInteger)page animated:(BOOL)animated
{
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 3];
    [self loadScrollViewWithPage:page - 2];
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:page + 2];
    [self loadScrollViewWithPage:page + 3];
    
	// update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    
    self.automaticScrolling = YES;
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
    
    [self.mapView setCenterCoordinate:snapbyCoordinate animated:YES];
    
//    MKMapRect currentMapRect = self.mapView.visibleMapRect;
//    currentMapRect.origin = MKMapPointForCoordinate(snapbyCoordinate);
//    
////    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(self.userInfoContainer.frame.size.height, 0, self.scrollViewContainer.frame.size.height, 0);
//    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
//    
//    [self.mapView setVisibleMapRect:currentMapRect edgePadding:edgeInsets animated:YES];
}
     
- (void)animatMaptOnFirstSnapby:(Snapby *)snapby
{
    CLLocationCoordinate2D location;
    location.latitude = snapby.lat;
    location.longitude = snapby.lng;
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(self.userInfoContainer.frame.size.height, 0, self.scrollViewContainer.frame.size.height, 0);
    
    MKCoordinateRegion snapbyRegion = MKCoordinateRegionMakeWithDistance(location, kDistanceAtStartup, kDistanceAtStartup);
    
    [self.mapView setRegion:snapbyRegion animated:YES];
    [self.mapView setVisibleMapRect:[LocationUtilities mKMapRectForCoordinateRegion:snapbyRegion] edgePadding:edgeInsets animated:NO];
}


// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------

- (void)settingsButtonClicked {
    [self performSegueWithIdentifier:@"settings push segue" sender:nil];
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
