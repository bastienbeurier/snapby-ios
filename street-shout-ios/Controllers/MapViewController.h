//
//  MapViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shout.h"
#import <MapKit/MapKit.h>

@protocol MapViewControllerDelegate;

@interface MapViewController : UIViewController

@property (weak, nonatomic) id <MapViewControllerDelegate> mapVCdelegate;
@property (nonatomic, strong) NSArray *shouts;
@property (strong, nonatomic) NSMutableDictionary *displayedShouts;
@property (nonatomic) BOOL updateShoutsOnMapMove;
@property (nonatomic) BOOL preventShoutsReload;
@property (nonatomic) CLLocationCoordinate2D savedMapLocation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (void)displayShouts:(NSArray *)shouts;

- (void)animateMapWhenShoutSelected:(Shout *)shout;

- (void) animateMapToLat:(float)lat lng:(float)lng;

- (void)startShoutSelectionModeInMapViewController:(Shout *)shout;

- (void)endShoutSelectionModeInMapViewController;

- (void)animateMapWhenZoomOnShout:(Shout *)shout;

@end

@protocol MapViewControllerDelegate

- (void)pullShoutsInZone:(NSArray *)mapBounds;

- (void)showShoutViewControllerIfNeeded:(Shout *)shout;

- (void)dismissShoutViewControllerIfNeeded;

- (void)refreshShouts;

@end
