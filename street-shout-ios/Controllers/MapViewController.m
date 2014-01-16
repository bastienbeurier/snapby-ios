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
#import "ImageUtilities.h"
#import "MKMapView+ZoomLevel.h"
#import "TrackingUtilities.h"

#define ZOOM_0 180

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *myLocationButton;
@property (nonatomic) BOOL hasZoomedAtStartUp;


@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.preventShoutDeselection = NO;
    
    [LocationUtilities animateMap:self.mapView ToLatitude:kMapInitialLatitude Longitude:kMapInitialLongitude WithSpan:ZOOM_0 Animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Buttons round corner
    NSUInteger buttonHeight = self.myLocationButton.bounds.size.height;
    self.myLocationButton.layer.cornerRadius = buttonHeight/2;
    
    [super viewWillAppear:animated];
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.hasZoomedAtStartUp == NO && userLocation.coordinate.latitude != 0 && userLocation.coordinate.latitude != -180 && userLocation.coordinate.longitude != 0 && userLocation.coordinate.longitude != -180) {
        [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:kDistanceAtStartup Animated:YES];
        self.hasZoomedAtStartUp = YES;
    }

    
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
        
        //Mixpanel tracking
        [TrackingUtilities trackDisplayShout:shout withSource:@"Map"];
        
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
            [self updateAnnotation:shoutAnnotation shoutInfo:shout];
            [self updateAnnotation:shoutAnnotation pinAccordingToShoutInfo:shout];
        } else {
            //Create new annotation
            CLLocationCoordinate2D annotationCoordinate;
            annotationCoordinate.latitude = shout.lat;
            annotationCoordinate.longitude = shout.lng;
            
            shoutAnnotation = [[MKPointAnnotation alloc] init];
            shoutAnnotation.coordinate = annotationCoordinate;
            
            [self updateAnnotation:shoutAnnotation shoutInfo:shout];
            [self.mapView addAnnotation:shoutAnnotation];
        }
        
        [newDisplayedShouts setObject:shoutAnnotation forKey:shoutKey];
    }
    
    //Remove annotations that are not on screen anymore
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (void)updateAnnotation:(MKPointAnnotation *)shoutAnnotation pinAccordingToShoutInfo:(Shout *)shout
{
    NSUInteger selectedShoutId = ((MKPointAnnotation *)[self.mapView.selectedAnnotations firstObject]).shout.identifier;
    
    //Otherwise, the selected shout icon image gets replaced by the deselected icon when new shouts load
    if (shout.identifier != selectedShoutId) {
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation:shoutAnnotation];
        [self setAnnotationView:annotationView pinImageForShout:shout selected:NO];
    }
}

- (void)updateAnnotation:(MKPointAnnotation *)shoutAnnotation shoutInfo:(Shout *)shout
{
    shoutAnnotation.shout = shout;
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
        
        self.hasZoomedAtStartUp = YES;
    } else {
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment") withTitle:NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment")];
    }

}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        MKPointAnnotation *annotation = (MKPointAnnotation *)annView.annotation;
        
        if ([annotation respondsToSelector:@selector(shout)]) {
            [self updateAnnotation:annotation pinAccordingToShoutInfo:annotation.shout];
        }
        
        CGRect endFrame = annView.frame;
        annView.frame = CGRectOffset(endFrame, 0, -500);
        [UIView animateWithDuration:0.5
                         animations:^{ annView.frame = endFrame; }];
    }
}

@end
