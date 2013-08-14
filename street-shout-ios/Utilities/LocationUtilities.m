//
//  LocationUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "LocationUtilities.h"
#import <MapKit/MapKit.h>

@implementation LocationUtilities

+ (NSArray *)getMapBounds:(MKMapView *)mapView
{
    //First we need to calculate the corners of the map so we get the points
    CGPoint nePoint = CGPointMake(mapView.bounds.origin.x + mapView.bounds.size.width, mapView.bounds.origin.y);
    CGPoint swPoint = CGPointMake((mapView.bounds.origin.x), (mapView.bounds.origin.y + mapView.bounds.size.height));
    
    //Then transform those point into lat,lng values
    CLLocationCoordinate2D neCoord;
    neCoord = [mapView convertPoint:nePoint toCoordinateFromView:mapView];
    
    CLLocationCoordinate2D swCoord;
    swCoord = [mapView convertPoint:swPoint toCoordinateFromView:mapView];
    
    return @[[NSNumber numberWithDouble:neCoord.latitude],
             [NSNumber numberWithDouble:neCoord.longitude],
             [NSNumber numberWithDouble:swCoord.latitude],
             [NSNumber numberWithDouble:swCoord.longitude]];
}

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng WithDistance:(NSUInteger)distance Animated:(BOOL)animated
{
    CLLocationCoordinate2D location;
    location.latitude = lat;
    location.longitude = lng;
    
    MKCoordinateRegion shoutRegion = MKCoordinateRegionMakeWithDistance(location, distance, distance);
    
    [mapView setRegion:shoutRegion animated:animated];
}

@end
