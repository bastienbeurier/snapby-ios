//
//  NavigationViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "NavigationViewController.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "Shout.h"

@interface NavigationViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSMutableDictionary *displayedShouts;

@end

@implementation NavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
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
    [MapRequestHandler pullShoutsInZone:[LocationUtilities getMapBounds:mapView]
                             AndExecute:^(NSArray *shouts) {
        [self displayShouts:shouts];
    }];
}

- (void)displayShouts:(NSArray *)shouts
{
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key][1]];
    }
    
    [self.displayedShouts removeAllObjects];
    
    for (Shout *shout in shouts) {
        CLLocationCoordinate2D annotationCoordinate;
        
        annotationCoordinate.latitude = shout.lat;
        annotationCoordinate.longitude = shout.lng;
        
        MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
        annotationPoint.coordinate = annotationCoordinate;
        annotationPoint.title = shout.displayName;
        annotationPoint.subtitle = shout.description;
        
        NSArray *shoutMarkerAndInstance = @[shout, annotationPoint];
        [self.displayedShouts setObject:shoutMarkerAndInstance
                                 forKey:[NSString stringWithFormat:@"%d", shout.identifier]];
        
        [self.mapView addAnnotation:annotationPoint];
    }
}

- (NSMutableDictionary *) displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

@end
