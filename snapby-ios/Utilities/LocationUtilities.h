//
//  LocationUtilities.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LocationUtilities : NSObject

+ (NSArray *)getMapBounds:(MKMapView *)mapView;

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng WithDistance:(NSUInteger)distance Animated:(BOOL)animated;

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng WithSpan:(double)spanValue Animated:(BOOL)animated;

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng Animated:(BOOL)animated;

+ (NSArray *)formattedDistanceLat1:(double)lat1 lng1:(double)lng1 lat2:(double)lat2 lng2:(double)lng2;

+ (NSUInteger)getMaxDistanceOnMap:(MKMapView *)mapView;

+ (BOOL)userLocationValid:(CLLocation *)userLocation;

+ (MKMapRect) mKMapRectForCoordinateRegion:(MKCoordinateRegion)region;

@end
