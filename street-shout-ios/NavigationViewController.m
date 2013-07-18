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

@interface NavigationViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

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
    NSLog(@"MAP MOVED!!!");
    
    [MapRequestHandler pullShoutsInZone:[LocationUtilities getMapBounds:mapView]];
}

@end
