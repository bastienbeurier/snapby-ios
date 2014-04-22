//
//  MapViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "MapViewController.h"
#import "MKPointAnnotation+SnapbyPointAnnotation.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "MKMapView+ZoomLevel.h"
#import "TrackingUtilities.h"
#import "ExploreSnapbyViewController.h"
#import "HackClipView.h"
#import "AFSnapbyAPIClient.h"

@interface MapViewController () <MKMapViewDelegate>

@property (nonatomic) BOOL hasZoomedAtStartUp;
@property (weak, nonatomic) IBOutlet UIScrollView *snapbiesScrollView;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger scrollViewWidth;
@property (nonatomic) NSUInteger scrollViewHeight;
@property (weak, nonatomic) IBOutlet HackClipView *scrollViewContainer;
@property (weak, nonatomic) id <MapViewControllerDelegate> mapVCdelegate;
@property (nonatomic, strong) NSArray *snapbies;
@property (strong, nonatomic) NSMutableDictionary *displayedSnapbies;
@property (weak, nonatomic) Snapby *previouslySelectedSnapby;
@property (nonatomic) BOOL automaticScrolling;

@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //TODO: loading dialog if waiting for location
    
    self.mapView.delegate = self;
    
    //Status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    self.mapView.showsUserLocation = YES;
    self.automaticScrolling = NO;
    
    // a page is the width of the scroll view
    self.snapbiesScrollView.pagingEnabled = YES;
    self.snapbiesScrollView.showsHorizontalScrollIndicator = NO;
    self.snapbiesScrollView.showsVerticalScrollIndicator = NO;
    self.snapbiesScrollView.scrollsToTop = NO;
    self.snapbiesScrollView.delegate = self;
}

- (void)refreshSnapbies
{
    //TODO Start loading
    
    [AFSnapbyAPIClient pullSnapbiesInZone:[LocationUtilities getMapBounds:self.mapView] AndExecuteSuccess:^(NSArray *snapbies) {
        
        //TODO Loading dialog
        
        self.snapbies = snapbies;
    } failure:^{
        //TODO Stop loading dialog
    }];
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
        self.scrollViewWidth = CGRectGetWidth(self.snapbiesScrollView.frame);
        self.scrollViewHeight = CGRectGetHeight(self.snapbiesScrollView.frame);
    }
    
    
    self.snapbiesScrollView.contentSize = CGSizeMake(self.scrollViewWidth * numberPages, self.scrollViewHeight);
    
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
    [self loadScrollViewWithPage:2];
    [self loadScrollViewWithPage:3];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.hasZoomedAtStartUp == NO && [LocationUtilities userLocationValid:userLocation.location]) {
        CLLocationCoordinate2D location;
        location.latitude = userLocation.coordinate.latitude;
        location.longitude = userLocation.coordinate.longitude;
   
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, self.scrollViewContainer.frame.size.height, 0);
        
        MKCoordinateRegion snapbyRegion = MKCoordinateRegionMakeWithDistance(location, kDistanceAtStartup, kDistanceAtStartup);
        
        [mapView setRegion:snapbyRegion animated:YES];
        [mapView setVisibleMapRect:[LocationUtilities mKMapRectForCoordinateRegion:snapbyRegion] edgePadding:edgeInsets animated:NO];
        
        [self refreshSnapbies];

        self.hasZoomedAtStartUp = YES;
    }

    
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
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

- (void)animateMapToLat:(float)lat lng:(float)lng
{
    CLLocationCoordinate2D snapbyCoordinate;
    snapbyCoordinate.latitude = lat;
    snapbyCoordinate.longitude = lng;
    
    [self.mapView setCenterCoordinate:snapbyCoordinate animated:YES];

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
        [self.snapbiesScrollView addSubview:controller.view];
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
    
    NSString *snapbyKey = [NSString stringWithFormat:@"%lu",((Snapby *)[self.snapbies objectAtIndex:page]).identifier];
    
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
    return floor((self.snapbiesScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
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
    CGRect bounds = self.snapbiesScrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    
    self.automaticScrolling = YES;
    [self.snapbiesScrollView scrollRectToVisible:bounds animated:animated];
}

- (IBAction)onScrollViewClicked:(id)sender {
    Snapby *snapby = [self.snapbies objectAtIndex:[self getScrollViewPage]];
    [self performSegueWithIdentifier:@"Snapby Push Segue" sender:snapby];
}

@end
