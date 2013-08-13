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

@property (nonatomic) BOOL hasZoomedAtStartUp;

@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.preventShoutDeselection = NO;
    
    self.hasZoomedAtStartUp = NO;
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if ( self.hasZoomedAtStartUp == NO ) {
        [self animateMapToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:1000];
        self.hasZoomedAtStartUp = YES;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (!self.preventShoutDeselection) {
        [self.mapVCdelegate shoutDeselectedOnMap];
    }
    
    self.preventShoutDeselection = NO;
    
    [self.mapVCdelegate pullShoutsInZone:[LocationUtilities getMapBounds:mapView]];
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

- (void)myLocationButtonClicked
{
    MKUserLocation *userLocation = self.mapView.userLocation;
    
    if (userLocation && userLocation.coordinate.longitude != 0 && userLocation.coordinate.latitude != 0) {
        [self animateMapToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:1000];
        self.hasZoomedAtStartUp = YES;
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment")
                                                          message:NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment")
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }

}

- (void)dezoomButtonClicked
{
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    [self.mapView setRegion:region animated:YES];
}

@end
