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
#import "FeedTVC.h"

@interface NavigationViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *feedContainer;
@property (nonatomic, retain) FeedTVC *currentViewController;

@end

@implementation NavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;

//    self.currentViewController = [[FeedTVC alloc] init];
//    [self addChildViewController:self.currentViewController];
//    self.currentViewController.view.frame = self.feedContainer.bounds;
//    [self.feedContainer addSubview:self.currentViewController.view];
//    [self.currentViewController didMoveToParentViewController:self];
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
    NSMutableDictionary *newDisplayedShouts = [[NSMutableDictionary alloc] init];
    
    for (Shout *shout in shouts) {
                
        NSString *shoutKey = [NSString stringWithFormat:@"%d", shout.identifier];
        
        NSArray *shoutMarkerAndInstance;
        
        if ([self.displayedShouts objectForKey:shoutKey]) {
            //Use existing marker
            shoutMarkerAndInstance = @[shout, [self.displayedShouts objectForKey:shoutKey][1]];
            [self.displayedShouts removeObjectForKey:shoutKey];
        } else {
            //Create new marker
            CLLocationCoordinate2D annotationCoordinate;
            
            annotationCoordinate.latitude = shout.lat;
            annotationCoordinate.longitude = shout.lng;
            
            MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
            annotationPoint.coordinate = annotationCoordinate;
            annotationPoint.title = shout.displayName;
            annotationPoint.subtitle = shout.description;
            
            [self.mapView addAnnotation:annotationPoint];

            shoutMarkerAndInstance = @[shout, annotationPoint];
        }

        [newDisplayedShouts setObject:shoutMarkerAndInstance forKey:shoutKey];
    }
    
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key][1]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (NSMutableDictionary *) displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

@end
