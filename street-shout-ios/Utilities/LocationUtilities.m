//
//  LocationUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "LocationUtilities.h"
#import <MapKit/MapKit.h>
#import "Constants.h"

#define METERS_TO_YRD 1.09361
#define YRD_TO_MILES 0.000621371

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

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng WithSpan:(NSUInteger)spanValue Animated:(BOOL)animated
{
    CLLocationCoordinate2D location;
    location.latitude = lat;
    location.longitude = lng;
    
    MKCoordinateRegion region;
    region.center= location;
    
    MKCoordinateSpan span;
    span.latitudeDelta = spanValue;
    span.longitudeDelta = spanValue;
    
    region.span=span;

    [mapView setRegion:region animated:animated];
}

+ (NSString *)formattedDistanceInMiles:(NSUInteger)distance
{
    NSUInteger distanceYd = round(distance * METERS_TO_YRD);
    NSUInteger distanceMiles = round(distance * YRD_TO_MILES);
    
    if (distanceYd < 100) {
        return NSLocalizedStringFromTable (@"nearby", @"Strings", @"comment");
    } else if (distanceMiles < 1) {
        NSString *str = [NSString stringWithFormat:@"%d", (NSUInteger) round(distanceYd / 100.0) * 100];
        return [str stringByAppendingFormat:@"yd %@", NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
    } else if (distanceMiles < 10) {
        NSString *str = [NSString stringWithFormat:@"%d", distanceMiles];
        return [str stringByAppendingFormat:@"mi %@", NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
    } else if (distanceMiles < 100 ) {
        NSString *str = [NSString stringWithFormat:@"%d", (NSUInteger) round(distanceMiles / 10.0) * 10];
        return [str stringByAppendingFormat:@"mi %@", NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
    } else {
        return NSLocalizedStringFromTable (@"far_away", @"Strings", @"comment");
    }
}

+ (NSString *)formattedDistanceInMeters:(NSUInteger)distance
{
    if (distance < 100) {
        return NSLocalizedStringFromTable (@"nearby", @"Strings", @"comment");
    } else if (distance < 1) {
        NSString *str = [NSString stringWithFormat:@"%d", (NSUInteger) round(distance / 100.0) * 100];
        return [str stringByAppendingFormat:@"%@ %@", NSLocalizedStringFromTable (@"meters", @"Strings", @"comment"), NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
    } else if (distance < 10) {
        NSString *str = [NSString stringWithFormat:@"%d", distance];
        return [str stringByAppendingFormat:@"km %@", NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
    } else if (distance < 100 ) {
        NSString *str = [NSString stringWithFormat:@"%d", (NSUInteger) round(distance / 10.0) * 10];
        return [str stringByAppendingFormat:@"km %@", NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
    } else {
        return NSLocalizedStringFromTable (@"far_away", @"Strings", @"comment");
    }
}

+ (NSString *)formattedDistanceLat1:(double)lat1 lng1:(double)lng1 lat2:(double)lat2 lng2:(double)lng2
{
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:lat1 longitude:lng1];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:lat2 longitude:lng2];
    
    NSUInteger distance = (NSUInteger) [loc1 distanceFromLocation:loc2];
    
    NSNumber *distanceUnitPreferenceIndex = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
    
    if (!distanceUnitPreferenceIndex || [distanceUnitPreferenceIndex integerValue] == 0) {
        return [self formattedDistanceInMeters:distance];
    } else {
        return [self formattedDistanceInMiles:distance];
    }
}

@end
