//
//  MapViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "MapViewController.h"
#import "MKPointAnnotation+ShoutPointAnnotation.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "NavigationViewController.h"
#import "Constants.h"

#define ZOOM_0 180
#define ZOOM_1 10
#define ZOOM_2 3
#define ZOOM_3 1
#define ZOOM_4 0.3
#define ZOOM_5 0.1
#define ZOOM_6 0.03
#define ZOOM_7 0.01
#define ZOOM_8 0.003
#define ZOOM_9 0.001
#define ZOOM_10 0.0005

@interface MapViewController () <MKMapViewDelegate>

@property (nonatomic) BOOL hasSentDeviceInfo;
@property (weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomOutButton;

@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.preventShoutDeselection = NO;
    
    self.hasSentDeviceInfo = NO;
    
    [LocationUtilities animateMap:self.mapView ToLatitude:kMapInitialLatitude Longitude:kMapInitialLongitude WithSpan:ZOOM_0 Animated:NO];
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (!self.preventShoutDeselection) {
        [self.mapVCdelegate shoutDeselectedOnMap];
    }
    
    self.preventShoutDeselection = NO;
    self.zoomInButton.enabled = YES;
    self.zoomOutButton.enabled = YES;
    
    [self.mapVCdelegate pullShoutsInZone:[LocationUtilities getMapBounds:mapView]];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    MKPointAnnotation *annotation = (MKPointAnnotation *)view.annotation;
    
    if ([annotation respondsToSelector:@selector(shout)]) {
        Shout *shout = annotation.shout;
        
        [self shoutSelectedOnMap:shout];
    }
}

- (void)shoutSelectedOnMap:(Shout *)shout
{
    [self.mapVCdelegate showShoutViewControllerIfNeeded:shout];
    
    [self animateMapWhenShout:shout selectedFrom:@"Map"];
}

- (void)animateMapWhenShout:(Shout *)shout selectedFrom:(NSString *)source
{
    self.preventShoutDeselection = YES;
    NSUInteger zoomDistance = 0;
    NSUInteger currentZoomDistance = [LocationUtilities getMaxDistanceOnMap:self.mapView];
    
    if ([source isEqualToString:@"Map"] || [source isEqualToString:@"Feed"]) {
        zoomDistance = kDistanceWhenShoutClickedFromMapOrFeed;
    } else if ([source isEqualToString:@"Create"]) {
        zoomDistance = kDistanceWhenRedirectedFromCreateShout;
    } else if ([source isEqualToString:@"Notification"]) {
        zoomDistance = kDistanceWhenShoutClickedFromNotif;
    }

    //TODO: check the times 2 for the zoomDistance
    if (zoomDistance != 0 && 2 * zoomDistance < currentZoomDistance) {
        [LocationUtilities animateMap:self.mapView ToLatitude:shout.lat Longitude:shout.lng WithDistance:zoomDistance Animated:YES];
    } else {
        [LocationUtilities animateMap:self.mapView ToLatitude:shout.lat Longitude:shout.lng Animated:YES];
    }
}

- (void)displayShouts:(NSArray *)shouts
{
    NSMutableDictionary *newDisplayedShouts = [[NSMutableDictionary alloc] init];
    
    for (Shout *shout in shouts) {
        
        NSString *shoutKey = [NSString stringWithFormat:@"%d", shout.identifier];
        
        MKPointAnnotation *shoutAnnotation;
        
        if ([self.displayedShouts objectForKey:shoutKey]) {
            //Use existing annotation
            shoutAnnotation = [self.displayedShouts objectForKey:shoutKey];
            [self.displayedShouts removeObjectForKey:shoutKey];
        } else {
            //Create new annotation
            CLLocationCoordinate2D annotationCoordinate;
            annotationCoordinate.latitude = shout.lat;
            annotationCoordinate.longitude = shout.lng;
            
            shoutAnnotation = [[MKPointAnnotation alloc] init];
            shoutAnnotation.coordinate = annotationCoordinate;
            
            [self.mapView addAnnotation:shoutAnnotation];
        }
        
        shoutAnnotation.shout = shout;
        [newDisplayedShouts setObject:shoutAnnotation forKey:shoutKey];
    }
    
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (NSMutableDictionary *) displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

- (void)myLocationButtonClicked
{
    MKUserLocation *userLocation = self.mapView.userLocation;
    
    if (userLocation && userLocation.coordinate.longitude != 0 && userLocation.coordinate.latitude != 0) {
        
        NSUInteger currentZoomDistance = [LocationUtilities getMaxDistanceOnMap:self.mapView];
        
        //Do not zoom if map is already zoomed
        if (2 * kDistanceWhenMyLocationButtonClicked < currentZoomDistance) {
            [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:kDistanceWhenMyLocationButtonClicked Animated:YES];
        } else {
            [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude Animated:YES];
        }
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment")
                                                          message:NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment")
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
}

- (void)dezoomButtonClicked
{
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    [self.mapView setRegion:region animated:YES];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    } else {
        MKAnnotationView *annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ShoutPin"];
    
        annView.image = [UIImage imageNamed:@"shout-marker-v2.png"];
        annView.centerOffset = CGPointMake(10,-10);
        
        return annView;
    }
}

- (void)mapView:(MKMapView *)mapView
didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        CGRect endFrame = annView.frame;
        annView.frame = CGRectOffset(endFrame, 0, -500);
        [UIView animateWithDuration:0.5
                         animations:^{ annView.frame = endFrame; }];
    }
}

- (void)viewDidUnload {
    [self setZoomInButton:nil];
    [self setZoomOutButton:nil];
    [super viewDidUnload];
}
@end
