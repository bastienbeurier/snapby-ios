//
//  MapViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shout.h"

@protocol MapViewControllerDelegate;

@interface MapViewController : UIViewController

@property (weak, nonatomic) id <MapViewControllerDelegate> mapVCdelegate;
@property (nonatomic, strong) NSArray *shouts;
@property (strong, nonatomic) NSMutableDictionary *displayedShouts;
@property (nonatomic) BOOL preventShoutDeselection;

- (void)displayShouts:(NSArray *)shouts;

- (void)animateMapToLatitude:(double)lat Longitude:(double)lng WithDistance:(NSUInteger) distance;

@end

@protocol MapViewControllerDelegate

- (void)pullShoutsInZone:(NSArray *)mapBounds;

- (void)shoutSelectedOnMap:(Shout *)shout;

- (void)shoutDeselectedOnMap;

@end
