//
//  LocationUtilities.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "LocationUtilities.h"
#import <MapKit/MapKit.h>
#import "Constants.h"

#define METERS_TO_YRD 1.09361
#define YRD_TO_MILES 0.000621371

@implementation LocationUtilities

+ (NSArray *)getMapBounds:(GMSMapView *)mapView
{
    GMSVisibleRegion region = mapView.projection.visibleRegion;
    //First we need to calculate the corners of the map so we get the points
    CLLocationCoordinate2D neCoord = region.farRight;
    CLLocationCoordinate2D swCoord = region.nearLeft;
    
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
    
    MKCoordinateRegion snapbyRegion = MKCoordinateRegionMakeWithDistance(location, distance, distance);
    
    [mapView setRegion:snapbyRegion animated:animated];
}

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng Animated:(BOOL)animated
{
    CLLocationCoordinate2D location;
    location.latitude = lat;
    location.longitude = lng;
    
    [mapView setCenterCoordinate:location animated:animated];
}

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng WithSpan:(double)spanValue Animated:(BOOL)animated
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

+ (NSArray *)formattedDistanceInMiles:(NSUInteger)distance
{
    NSUInteger distanceYd = round(distance * METERS_TO_YRD);
    NSUInteger distanceMiles = round(distance * YRD_TO_MILES);
    
    if (distanceYd < 100) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) distanceYd];
        return [[NSArray alloc] initWithObjects:str, NSLocalizedStringFromTable (@"yd", @"Strings", @"comment"), nil];
    } else if (distanceMiles < 1) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) round(distanceYd / 100.0) * 100];
        return [[NSArray alloc] initWithObjects:str, NSLocalizedStringFromTable (@"yd", @"Strings", @"comment"), nil];
    } else if (distanceMiles < 10) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long)distanceMiles];
        return [[NSArray alloc] initWithObjects:str, @"mi", nil];
    } else if (distanceMiles < 100 ) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) round(distanceMiles / 10.0) * 10];
        return [[NSArray alloc] initWithObjects:str, @"mi", nil];
    } else {
        return [[NSArray alloc] initWithObjects:@"+100", @"mi", nil];
    }
}

+ (NSArray *)formattedDistanceInMeters:(NSUInteger)distance
{
    if (distance < 100) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) distance];
        return [[NSArray alloc] initWithObjects:str, NSLocalizedStringFromTable (@"m", @"Strings", @"comment"), nil];
    } else if (distance < 1000) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) round(distance / 100.0) * 100];
        return [[NSArray alloc] initWithObjects:str, NSLocalizedStringFromTable (@"m", @"Strings", @"comment"), nil];
    } else if (distance < 10000) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) round(distance / 1000.0)];
        return [[NSArray alloc] initWithObjects:str, @"km", nil];
    } else if (distance < 100000 ) {
        NSString *str = [NSString stringWithFormat:@"%lu", (unsigned long) round(distance / 10000.0) * 10];
        return [[NSArray alloc] initWithObjects:str, @"km", nil];
    } else {
        return [[NSArray alloc] initWithObjects:@"+100", @"km", nil];
    }
}

+ (NSArray *)formattedDistanceLat1:(double)lat1 lng1:(double)lng1 lat2:(double)lat2 lng2:(double)lng2
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

//Returns the max distance on the map in meters
+ (NSUInteger)getMaxDistanceOnMap:(MKMapView *)mapView
{
    MKMapPoint mpTopLeft = mapView.visibleMapRect.origin;
    
    MKMapPoint mpTopRight = MKMapPointMake(
                                           mapView.visibleMapRect.origin.x + mapView.visibleMapRect.size.width,
                                           mapView.visibleMapRect.origin.y);
    
    MKMapPoint mpBottomRight = MKMapPointMake(
                                              mapView.visibleMapRect.origin.x + mapView.visibleMapRect.size.width,
                                              mapView.visibleMapRect.origin.y + mapView.visibleMapRect.size.height);
    
    CLLocationDistance hDist = (CLLocationDistance) MKMetersBetweenMapPoints(mpTopLeft, mpTopRight);
    CLLocationDistance vDist = (CLLocationDistance) MKMetersBetweenMapPoints(mpTopRight, mpBottomRight);

    return (NSUInteger) MIN(hDist, vDist);
}

+ (BOOL)userLocationValid:(CLLocation *)userLocation
{
    if(!userLocation){
        return false;
    }
    return userLocation.coordinate.latitude != 0 &&
    userLocation.coordinate.latitude != -180 &&
    userLocation.coordinate.longitude != 0 &&
    userLocation.coordinate.longitude != -180;
}

+ (MKMapRect) mKMapRectForCoordinateRegion:(MKCoordinateRegion)region
{
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

@end
