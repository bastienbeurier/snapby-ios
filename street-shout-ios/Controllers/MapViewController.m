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

@interface MapViewController () <MKMapViewDelegate>

@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.preventShoutDeselection = NO;
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)viewWillAppear:(BOOL)animated {
    //    MKUserLocation *userLocation = self.mapView.userLocation;
    [self animateMapToLatitude:37.753615 Longitude:-122.417578 WithDistance:1000];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

    [self.mapVCdelegate pullShoutsInZone:[LocationUtilities getMapBounds:mapView]];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if (!self.preventShoutDeselection) {
        [self.mapVCdelegate shoutDeselectedOnMap];
    }
    
    self.preventShoutDeselection = NO;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    Shout *shout = ((MKPointAnnotation *)view.annotation).shout;
    
    [self.mapVCdelegate shoutSelectedOnMap:shout];
    
    self.preventShoutDeselection = YES;
    [self animateMapToLatitude:shout.lat Longitude:shout.lng WithDistance:1000];
}

- (void)animateMapToLatitude:(double)lat Longitude:(double)lng WithDistance:(NSUInteger) distance
{
    CLLocationCoordinate2D location;
    location.latitude = lat;
    location.longitude = lng;
    
    MKCoordinateRegion shoutRegion = MKCoordinateRegionMakeWithDistance(location, distance, distance);
    
    [self.mapView setRegion:shoutRegion animated:YES];
    
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
        
        shoutAnnotation.shout = shout;
        [newDisplayedShouts setObject:shoutAnnotation forKey:shoutKey];
    }
    
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (NSMutableDictionary *) displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

@end
