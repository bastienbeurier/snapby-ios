//
//  LocationUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LocationUtilities : NSObject

+ (NSArray *)getMapBounds:(MKMapView *)mapView;

+ (void)animateMap:(MKMapView *)mapView ToLatitude:(double)lat Longitude:(double)lng WithDistance:(NSUInteger)distance Animated:(BOOL)animated;

@end
