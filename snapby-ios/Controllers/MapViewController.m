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
#import "ExploreViewController.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "MKMapView+ZoomLevel.h"
#import "TrackingUtilities.h"
#import "ExploreSnapbyViewController.h"
#import "HackClipView.h"

@interface MapViewController () <MKMapViewDelegate>

@property (nonatomic) BOOL hasZoomedAtStartUp;
@property (weak, nonatomic) IBOutlet UIScrollView *snapbiesScrollView;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger scrollViewWidth;
@property (nonatomic) NSUInteger scrollViewHeight;
@property (weak, nonatomic) IBOutlet HackClipView *scrollViewContainer;

@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    
    [LocationUtilities animateMap:self.mapView ToLatitude:kMapInitialLatitude Longitude:kMapInitialLongitude Animated:NO];
    
    // a page is the width of the scroll view
    self.snapbiesScrollView.pagingEnabled = YES;
    self.snapbiesScrollView.showsHorizontalScrollIndicator = NO;
    self.snapbiesScrollView.showsVerticalScrollIndicator = NO;
    self.snapbiesScrollView.scrollsToTop = NO;
    self.snapbiesScrollView.delegate = self;
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
    [self loadScrollViewWithPage:4];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.hasZoomedAtStartUp == NO && [LocationUtilities userLocationValid:userLocation.location]) {
        CLLocationCoordinate2D location;
        location.latitude = userLocation.coordinate.latitude;
        location.longitude = userLocation.coordinate.longitude;
   
        UIEdgeInsets edgeInsets =
        UIEdgeInsetsMake(0, 0, self.scrollViewContainer.frame.size.height, 0);
        
        MKCoordinateRegion snapbyRegion = MKCoordinateRegionMakeWithDistance(location, kDistanceAtStartup, kDistanceAtStartup);
        
        [mapView setRegion:snapbyRegion animated:YES];
        [mapView setVisibleMapRect:[LocationUtilities mKMapRectForCoordinateRegion:snapbyRegion] edgePadding:edgeInsets animated:NO];

        self.hasZoomedAtStartUp = YES;
    }

    
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

    [self.mapVCdelegate refreshSnapbies];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{

    MKPointAnnotation *annotation = (MKPointAnnotation *)view.annotation;
    
    if ([annotation respondsToSelector:@selector(snapby)]) {
        Snapby *snapby = annotation.snapby;
        
        //Mixpanel tracking
        [TrackingUtilities trackDisplaySnapby:snapby withSource:@"Map"];
        
        [self.mapVCdelegate snapbySelectionComingFromMap:snapby];
    }
}

- (void)deselectAnnotationsOnMap
{
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    for (id annotationView in selectedAnnotations) {
        [self.mapView deselectAnnotation:annotationView animated:NO];
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
    NSMutableDictionary *newDisplayedSnapbies = [[NSMutableDictionary alloc] init];
    
    for (Snapby *snapby in snapbies) {
        
        NSString *snapbyKey = [NSString stringWithFormat:@"%lu", (unsigned long)snapby.identifier];
        
        MKPointAnnotation *snapbyAnnotation;
        
        if ([self.displayedSnapbies objectForKey:snapbyKey]) {
            //Use existing annotation
            snapbyAnnotation = [self.displayedSnapbies objectForKey:snapbyKey];
            [self.displayedSnapbies removeObjectForKey:snapbyKey];
            [self updateAnnotation:snapbyAnnotation snapbyInfo:snapby];
            [self updateAnnotation:snapbyAnnotation pinAccordingToSnapbyInfo:snapby];
        } else {
            //Create new annotation
            CLLocationCoordinate2D annotationCoordinate;
            annotationCoordinate.latitude = snapby.lat;
            annotationCoordinate.longitude = snapby.lng;
            
            snapbyAnnotation = [[MKPointAnnotation alloc] init];
            snapbyAnnotation.coordinate = annotationCoordinate;
            
            [self updateAnnotation:snapbyAnnotation snapbyInfo:snapby];
            [self.mapView addAnnotation:snapbyAnnotation];
        }
        
        [newDisplayedSnapbies setObject:snapbyAnnotation forKey:snapbyKey];
    }
    
    //Remove annotations that are not on screen anymore
    for (NSString *key in self.displayedSnapbies) {
        [self.mapView removeAnnotation:[self.displayedSnapbies objectForKey:key]];
    }
    
    self.displayedSnapbies = newDisplayedSnapbies;
}

- (void)updateAnnotation:(MKPointAnnotation *)snapbyAnnotation pinAccordingToSnapbyInfo:(Snapby *)snapby
{
    MKAnnotationView *annotationView = [self.mapView viewForAnnotation:snapbyAnnotation];
    
    NSString *annotationPinImage = [GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby];
    
    annotationView.image = [UIImage imageNamed:annotationPinImage];
    annotationView.centerOffset = CGPointMake(kSnapbyAnnotationOffsetX, kSnapbyAnnotationOffsetY);
}

- (void)updateAnnotation:(MKPointAnnotation *)snapbyAnnotation snapbyInfo:(Snapby *)snapby
{
    snapbyAnnotation.snapby = snapby;
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
            [self updateAnnotation:annotation pinAccordingToSnapbyInfo:annotation.snapby];
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
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewDidEndDecelerating");
    
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollViewWidth;
    NSUInteger page = floor((self.snapbiesScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    
    
    [self loadScrollViewWithPage:page - 4];
    [self loadScrollViewWithPage:page - 3];
    [self loadScrollViewWithPage:page - 2];
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:page + 2];
    [self loadScrollViewWithPage:page + 3];
    [self loadScrollViewWithPage:page + 4];
    
    // a possible optimization would be to unload the views+controllers which are no longer visible
}

@end
