//
//  MapViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "ExploreViewController.h"
#import "MKPointAnnotation+SnapbyPointAnnotation.h"
#import "LocationUtilities.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "TrackingUtilities.h"
#import "ExploreSnapbyViewController.h"
#import "HackClipView.h"
#import "AFSnapbyAPIClient.h"

@interface ExploreViewController () <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger scrollViewWidth;
@property (nonatomic) NSUInteger scrollViewHeight;
@property (weak, nonatomic) IBOutlet HackClipView *scrollViewContainer;
@property (nonatomic, strong) NSArray *snapbies;
@property (strong, nonatomic) NSMutableDictionary *displayedSnapbies;
@property (weak, nonatomic) Snapby *previouslySelectedSnapby;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (nonatomic) int currentSelectedZIndex;
@property (nonatomic) NSInteger automaticScrolling;
@property (nonatomic) BOOL myLocationMarkerSet;
@property (weak, nonatomic) IBOutlet UIView *snapbyDialog;
@property (weak, nonatomic) IBOutlet UILabel *snapbyDialogLabel;
@property (nonatomic) BOOL didInitializedExplore;
@property (weak, nonatomic) IBOutlet UIImageView *refreshButton;

@end

@implementation ExploreViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    // border radius
    [self.snapbyDialog.layer setCornerRadius:25.0f];
    [self.refreshButton.layer setCornerRadius:22.0f];
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = NO;
    self.mapView.settings.scrollGestures = NO;
    self.mapView.settings.zoomGestures = NO;
    self.mapView.settings.tiltGestures = NO;
    self.mapView.settings.rotateGestures = NO;
    
    self.automaticScrolling = NO;
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    self.currentSelectedZIndex = 0;
    
    //Equivalent of NO
    self.automaticScrolling = -1;
    
    self.myLocationMarkerSet = NO;
    
    
    
    self.didInitializedExplore = NO;
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!self.didInitializedExplore) {
        self.didInitializedExplore = YES;
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, self.scrollViewContainer.frame.size.height, 0);
        self.mapView.padding = edgeInsets;
        
        [self moveMapToMyLocationAndLoadSnapbies];
    }
}

- (void)refreshSnapbies
{
    [self loadingSnapbiesUI];
    
    [AFSnapbyAPIClient pullSnapbiesInZone:[LocationUtilities getMapBounds:self.mapView] AndExecuteSuccess:^(NSArray *snapbies) {
        self.snapbies = snapbies;
    } failure:^{
        [self noConnectionUI];
    }];
}

- (void)refreshSnapbiesFromDisplay
{
    [self refreshSnapbies];
    [self.exploreVCDelegate refreshProfileSnapbies];
}

- (void)loadingSnapbiesUI
{
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"Loading...";
    self.scrollView.hidden = YES;
}

- (void)noSnapbiesUI
{
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"No snapby here...";
    self.scrollView.hidden = YES;
}

- (void)noConnectionUI
{
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"No connection...";
    self.scrollView.hidden = YES;
}

- (void)noLocationUI
{
    [self.mapView moveCamera:[GMSCameraUpdate setTarget:CLLocationCoordinate2DMake(50,0) zoom:0]];
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"No location...";
    self.scrollView.hidden = YES;
}

- (void)displaySnapbiesUI
{
    self.snapbyDialog.hidden = YES;
    self.snapbyDialogLabel.text = @"";
    self.scrollView.hidden = NO;
}

- (void)setSnapbies:(NSArray *)snapbies
{
    _snapbies = snapbies;
    
    if ([snapbies count] == 0) {
        [self noSnapbiesUI];
        return;
    }
    
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
    
    [self gotoPage:0 animated:NO];
    
    [self loadSnapbiesAndUpdateMarker];
    
    [self displaySnapbiesUI];
}

- (void) moveMapToMyLocationAndLoadSnapbies
{
    CLLocation *myLocation = [self.exploreVCDelegate getMyLocation];
    if (myLocation != nil && myLocation.coordinate.latitude != 0 && myLocation.coordinate.longitude != 0) {
        CLLocationCoordinate2D location;
        location.latitude = myLocation.coordinate.latitude;
        location.longitude = myLocation.coordinate.longitude;
        
        [self.mapView moveCamera:[GMSCameraUpdate setTarget:location zoom:kZoomAtStartup]];
        
        [self.mapView clear];
        
        GMSMarker *marker = [GMSMarker markerWithPosition:location];
        marker.icon = [UIImage imageNamed:@"my_location_marker"];
        marker.zIndex = 10000;
        marker.map = self.mapView;
        
        [self refreshSnapbies];
    } else {
        [self noLocationUI];
    }
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
    if ([segueName isEqualToString: @"Snapby Push Segue From Explore"]) {
        ((DisplayViewController *) [segue destinationViewController]).snapby = (Snapby *)sender;
        ((DisplayViewController *) [segue destinationViewController]).displayVCDelegate = self;
    }
}

- (void)displaySnapbies:(NSArray *)snapbies
{
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
    return MIN(floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1, self.snapbies.count - 1);
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
    [self performSegueWithIdentifier:@"Snapby Push Segue From Explore" sender:snapby];
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self moveMapToMyLocationAndLoadSnapbies];
}

@end
