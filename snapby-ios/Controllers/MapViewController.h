//
//  MapViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snapby.h"
#import <MapKit/MapKit.h>

@protocol MapViewControllerDelegate;

@interface MapViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) id <MapViewControllerDelegate> mapVCdelegate;
@property (nonatomic, strong) NSArray *snapbies;
@property (strong, nonatomic) NSMutableDictionary *displayedSnapbies;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (void)displaySnapbies:(NSArray *)snapbies;

- (void) animateMapToLat:(float)lat lng:(float)lng;

- (void)deselectAnnotationsOnMap;

@end

@protocol MapViewControllerDelegate

- (void)pullSnapbiesInZone:(NSArray *)mapBounds;

- (void)snapbySelectionComingFromMap:(Snapby *)snapby;

- (void)refreshSnapbies;

@end
