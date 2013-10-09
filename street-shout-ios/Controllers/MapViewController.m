//
//  MapViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "MapViewController.h"
#import "MKPointAnnotation+ShoutPointAnnotation.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "NavigationViewController.h"
#import "Constants.h"
#import "GeneralUtilities.h"

#define ZOOM_0 180
#define ZOOM_1 10
#define ZOOM_2 3
#define ZOOM_3 1
#define ZOOM_4 0.3
#define ZOOM_5 0.1
#define ZOOM_6 0.03
#define ZOOM_7 0.01
#define ZOOM_8 0.003
#define ZOOM_9 0.001
#define ZOOM_10 0.0005

@interface MapViewController () <MKMapViewDelegate>

@property (nonatomic) BOOL hasSentDeviceInfo;
@property (weak, nonatomic) IBOutlet UIButton *myLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *dezoomMaxButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;


@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.preventShoutDeselection = NO;
    
    self.hasSentDeviceInfo = NO;
    
    [LocationUtilities animateMap:self.mapView ToLatitude:kMapInitialLatitude Longitude:kMapInitialLongitude WithSpan:ZOOM_0 Animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Drop shadows for map buttons
    [self.myLocationButton.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.myLocationButton.layer setShadowOpacity:0.3];
    [self.myLocationButton.layer setShadowRadius:1.5];
    self.myLocationButton.clipsToBounds = NO;
    [self.myLocationButton.layer setShadowOffset:CGSizeMake(kDropShadowX, kDropShadowY)];
    
    [self.dezoomMaxButton.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.dezoomMaxButton.layer setShadowOpacity:0.3];
    [self.dezoomMaxButton.layer setShadowRadius:1.5];
    self.dezoomMaxButton.clipsToBounds = NO;
    [self.dezoomMaxButton.layer setShadowOffset:CGSizeMake(kDropShadowX, kDropShadowY)];
    
    [self.settingsButton.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.settingsButton.layer setShadowOpacity:0.3];
    [self.settingsButton.layer setShadowRadius:1.5];
    self.settingsButton.clipsToBounds = NO;
    [self.settingsButton.layer setShadowOffset:CGSizeMake(kDropShadowX, kDropShadowY)];
    
    
    [super viewWillAppear:animated];
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (!self.preventShoutDeselection) {
        [self endShoutSelectionModeInMapViewController];
    }
    
    self.preventShoutDeselection = NO;
    
    [self.mapVCdelegate pullShoutsInZone:[LocationUtilities getMapBounds:mapView]];
}

- (void)refreshShoutsFromMapViewController
{
    [self mapView:self.mapView regionDidChangeAnimated:NO];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        [self.mapVCdelegate dismissShoutViewControllerIfNeeded];
        
        return;
    }
    
    MKPointAnnotation *annotation = (MKPointAnnotation *)view.annotation;
    
    if ([annotation respondsToSelector:@selector(shout)]) {
        Shout *shout = annotation.shout;
        [self setAnnotationView:view pinImageForShout:shout selected:YES];
        view.centerOffset = CGPointMake(13,-13);
        
        [self updateUIWhenShoutSelected:shout];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    
    [self setAnnotationView:view pinImageForShout:((MKPointAnnotation *)view.annotation).shout selected:NO];
    view.centerOffset = CGPointMake(10,-10);
}

- (void)updateUIWhenShoutSelected:(Shout *)shout
{
    [self.mapVCdelegate showShoutViewControllerIfNeeded:shout];
    
    [self animateMapWhenShoutSelected:shout];
}

- (void)startShoutSelectionModeInMapViewController:(Shout *)shout
{
    NSString *shoutKey = [NSString stringWithFormat:@"%d", shout.identifier];
    
    MKPointAnnotation *shoutAnnotation = [self.displayedShouts objectForKey:shoutKey];
    
    if (shoutAnnotation) {
        [self.mapView selectAnnotation:shoutAnnotation animated:NO];
    }
}

- (void)endShoutSelectionModeInMapViewController
{
    [self.mapVCdelegate dismissShoutViewControllerIfNeeded];
    
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    for (id annotationView in selectedAnnotations) {
        [self.mapView deselectAnnotation:annotationView animated:NO];
    }
}

- (void)animateMapWhenShoutSelected:(Shout *)shout
{
    [self animateMapInShoutSelectionModeWithShout:shout andDistance:kDistanceWhenShoutClickedFromMapOrFeed];
}

- (void)animateMapWhenZoomOnShout:(Shout *)shout
{
    [self animateMapInShoutSelectionModeWithShout:shout andDistance:kDistanceWhenShoutZoomed];
}

- (void)animateMapInShoutSelectionModeWithShout:(Shout *)shout andDistance:(NSUInteger)distance
{
    self.preventShoutDeselection = YES;
    NSUInteger newZoomDistance = distance;
    NSUInteger currentZoomDistance = [LocationUtilities getMaxDistanceOnMap:self.mapView];
    
    //TODO: check the times 2 for the zoomDistance
    if (newZoomDistance != 0 && 2 * newZoomDistance < currentZoomDistance) {
        [LocationUtilities animateMap:self.mapView ToLatitude:shout.lat Longitude:shout.lng WithDistance:newZoomDistance Animated:YES];
    } else {
        [LocationUtilities animateMap:self.mapView ToLatitude:shout.lat Longitude:shout.lng Animated:YES];
    }
}

- (void)displayShouts:(NSArray *)shouts
{
    NSMutableDictionary *newDisplayedShouts = [[NSMutableDictionary alloc] init];
    
    for (Shout *shout in shouts) {
        
        NSString *shoutKey = [NSString stringWithFormat:@"%d", shout.identifier];
        
        MKPointAnnotation *shoutAnnotation;
        
        if ([self.displayedShouts objectForKey:shoutKey]) {
            //Use existing annotation
            shoutAnnotation = [self.displayedShouts objectForKey:shoutKey];
            [self.displayedShouts removeObjectForKey:shoutKey];
        } else {
            //Create new annotation
            CLLocationCoordinate2D annotationCoordinate;
            annotationCoordinate.latitude = shout.lat;
            annotationCoordinate.longitude = shout.lng;
            
            shoutAnnotation = [[MKPointAnnotation alloc] init];
            shoutAnnotation.coordinate = annotationCoordinate;
            
            [self.mapView addAnnotation:shoutAnnotation];
        }
        
        NSUInteger selectedShoutId = ((MKPointAnnotation *)[self.mapView.selectedAnnotations firstObject]).shout.identifier;
        
        //Otherwise, the selected shout icon image gets replaced by the deselected icon when new shouts load
        if (shout.identifier != selectedShoutId) {
            MKAnnotationView *annotationView = [self.mapView viewForAnnotation:shoutAnnotation];
            [self setAnnotationView:annotationView pinImageForShout:shout selected:NO];
        }
        
        shoutAnnotation.shout = shout;
        [newDisplayedShouts setObject:shoutAnnotation forKey:shoutKey];
    }
    
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (void)setAnnotationView:(MKAnnotationView *)annotationView pinImageForShout:(Shout *)shout selected:(BOOL)selected
{
    NSString *annotationPinImage = [GeneralUtilities getAnnotationPinImageForShout:(Shout *)shout selected:(BOOL)selected];
    
    annotationView.image = [UIImage imageNamed:annotationPinImage];
    annotationView.centerOffset = CGPointMake(10,-10);
}

- (NSMutableDictionary *)displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

- (IBAction)myLocationButtonClicked:(id)sender {
    MKUserLocation *userLocation = self.mapView.userLocation;
    
    if (userLocation && userLocation.coordinate.longitude != 0 && userLocation.coordinate.latitude != 0) {
        
        NSUInteger currentZoomDistance = [LocationUtilities getMaxDistanceOnMap:self.mapView];
        
        //Do not zoom if map is already zoomed
        if (2 * kDistanceWhenMyLocationButtonClicked < currentZoomDistance) {
            [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:kDistanceWhenMyLocationButtonClicked Animated:YES];
        } else {
            [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude Animated:YES];
        }
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment")
                                                          message:NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment")
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }

}

- (IBAction)dezoomButtonClicked:(id)sender {
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    [self.mapView setRegion:region animated:YES];
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        CGRect endFrame = annView.frame;
        annView.frame = CGRectOffset(endFrame, 0, -500);
        [UIView animateWithDuration:0.5
                         animations:^{ annView.frame = endFrame; }];
    }
}

- (IBAction)settingsButtonClicked:(id)sender {
    [self.mapVCdelegate settingsButtonClicked];
}

@end
