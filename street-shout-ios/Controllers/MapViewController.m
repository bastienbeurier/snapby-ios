//
//  MapViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "Shout.h"
#import "NavigationViewController.h"

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)viewWillAppear:(BOOL)animated {
    CLLocationCoordinate2D initialLocation;
    //    MKUserLocation *userLocation = self.mapView.userLocation;
    initialLocation.latitude = 37.753615;
    initialLocation.longitude = -122.417578;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(initialLocation, 1000, 1000);
    
    [_mapView setRegion:viewRegion animated:YES];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.mapVCdelegate pullShoutsInZone:[LocationUtilities getMapBounds:mapView]];
}

- (void)displayShouts:(NSArray *)shouts
{
    NSMutableDictionary *newDisplayedShouts = [[NSMutableDictionary alloc] init];
    
    for (Shout *shout in shouts) {
        
        NSString *shoutKey = [NSString stringWithFormat:@"%d", shout.identifier];
        
        NSArray *shoutMarkerAndInstance;
        
        if ([self.displayedShouts objectForKey:shoutKey]) {
            //Use existing marker
            shoutMarkerAndInstance = @[shout, [self.displayedShouts objectForKey:shoutKey][1]];
            [self.displayedShouts removeObjectForKey:shoutKey];
        } else {
            //Create new marker
            CLLocationCoordinate2D annotationCoordinate;
            
            annotationCoordinate.latitude = shout.lat;
            annotationCoordinate.longitude = shout.lng;
            
            MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
            annotationPoint.coordinate = annotationCoordinate;
            annotationPoint.title = shout.displayName;
            annotationPoint.subtitle = shout.description;
            
            [self.mapView addAnnotation:annotationPoint];
            
            shoutMarkerAndInstance = @[shout, annotationPoint];
        }
        
        [newDisplayedShouts setObject:shoutMarkerAndInstance forKey:shoutKey];
    }
    
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key][1]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (NSMutableDictionary *) displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

@end
