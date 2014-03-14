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
#import "ExploreViewController.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "MKMapView+ZoomLevel.h"
#import "TrackingUtilities.h"

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *myLocationButton;
@property (nonatomic) BOOL hasZoomedAtStartUp;


@end

@implementation MapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    
    [LocationUtilities animateMap:self.mapView ToLatitude:kMapInitialLatitude Longitude:kMapInitialLongitude Animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Buttons round corner
    NSUInteger buttonHeight = self.myLocationButton.bounds.size.height;
    self.myLocationButton.layer.cornerRadius = buttonHeight/2;
    
    [super viewWillAppear:animated];
}

- (void)setShouts:(NSArray *)shouts
{
    _shouts = shouts;
    [self displayShouts:shouts];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.hasZoomedAtStartUp == NO && [LocationUtilities userLocationValid:userLocation]) {
        [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:kDistanceAtStartup Animated:NO];
        self.hasZoomedAtStartUp = YES;
    }

    
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

    [self.mapVCdelegate refreshShouts];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{

    MKPointAnnotation *annotation = (MKPointAnnotation *)view.annotation;
    
    if ([annotation respondsToSelector:@selector(shout)]) {
        Shout *shout = annotation.shout;
        
        //Mixpanel tracking
        [TrackingUtilities trackDisplayShout:shout withSource:@"Map"];
        
        [self.mapVCdelegate shoutSelectionComingFromMap:shout];
    }
}

- (void)deselectAnnotationsOnMap
{
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    for (id annotationView in selectedAnnotations) {
        [self.mapView deselectAnnotation:annotationView animated:NO];
    }
}

- (void)animateMapToLat:(float)lat lng:(float)lng
{
    CLLocationCoordinate2D shoutCoordinate;
    shoutCoordinate.latitude = lat;
    shoutCoordinate.longitude = lng;
    
    [self.mapView setCenterCoordinate:shoutCoordinate animated:YES];

}

- (void)displayShouts:(NSArray *)shouts
{
    NSMutableDictionary *newDisplayedShouts = [[NSMutableDictionary alloc] init];
    
    for (Shout *shout in shouts) {
        
        NSString *shoutKey = [NSString stringWithFormat:@"%lu", (unsigned long)shout.identifier];
        
        MKPointAnnotation *shoutAnnotation;
        
        if ([self.displayedShouts objectForKey:shoutKey]) {
            //Use existing annotation
            shoutAnnotation = [self.displayedShouts objectForKey:shoutKey];
            [self.displayedShouts removeObjectForKey:shoutKey];
            [self updateAnnotation:shoutAnnotation shoutInfo:shout];
            [self updateAnnotation:shoutAnnotation pinAccordingToShoutInfo:shout];
        } else {
            //Create new annotation
            CLLocationCoordinate2D annotationCoordinate;
            annotationCoordinate.latitude = shout.lat;
            annotationCoordinate.longitude = shout.lng;
            
            shoutAnnotation = [[MKPointAnnotation alloc] init];
            shoutAnnotation.coordinate = annotationCoordinate;
            
            [self updateAnnotation:shoutAnnotation shoutInfo:shout];
            [self.mapView addAnnotation:shoutAnnotation];
        }
        
        [newDisplayedShouts setObject:shoutAnnotation forKey:shoutKey];
    }
    
    //Remove annotations that are not on screen anymore
    for (NSString *key in self.displayedShouts) {
        [self.mapView removeAnnotation:[self.displayedShouts objectForKey:key]];
    }
    
    self.displayedShouts = newDisplayedShouts;
}

- (void)updateAnnotation:(MKPointAnnotation *)shoutAnnotation pinAccordingToShoutInfo:(Shout *)shout
{
    MKAnnotationView *annotationView = [self.mapView viewForAnnotation:shoutAnnotation];
    
    NSString *annotationPinImage = [GeneralUtilities getAnnotationPinImageForShout:(Shout *)shout];
    
    annotationView.image = [UIImage imageNamed:annotationPinImage];
    annotationView.centerOffset = CGPointMake(kShoutAnnotationOffsetX, kShoutAnnotationOffsetY);
}

- (void)updateAnnotation:(MKPointAnnotation *)shoutAnnotation shoutInfo:(Shout *)shout
{
    shoutAnnotation.shout = shout;
}

- (NSMutableDictionary *)displayedShouts
{
    if (!_displayedShouts) _displayedShouts = [[NSMutableDictionary alloc] init];
    return _displayedShouts;
}

- (IBAction)myLocationButtonClicked:(id)sender {
    MKUserLocation *userLocation = self.mapView.userLocation;
    
    if (userLocation && userLocation.coordinate.longitude != 0 && userLocation.coordinate.latitude != 0) {
        
        NSUInteger currentZoomDistance = [LocationUtilities getMaxDistanceOnMap:self.mapView];
        
        //Do not zoom if map is already zoomed
        if (2 * kDistanceWhenMyLocationButtonClicked < currentZoomDistance) {
            [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude WithDistance:kDistanceWhenMyLocationButtonClicked Animated:YES];
        } else {
            [LocationUtilities animateMap:self.mapView ToLatitude:userLocation.coordinate.latitude Longitude:userLocation.coordinate.longitude Animated:YES];
        }
        
        self.hasZoomedAtStartUp = YES;
    } else {
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"no_location_for_shout_message", @"Strings", @"comment") withTitle:NSLocalizedStringFromTable (@"no_location_for_shout_title", @"Strings", @"comment")];
    }

}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        MKPointAnnotation *annotation = (MKPointAnnotation *)annView.annotation;
        
        if ([annotation respondsToSelector:@selector(shout)]) {
            [self updateAnnotation:annotation pinAccordingToShoutInfo:annotation.shout];
        }
        
        CGRect endFrame = annView.frame;
        annView.frame = CGRectMake(endFrame.origin.x + endFrame.size.width/2, endFrame.origin.y + endFrame.size.height, 0, 0);
        [UIView animateWithDuration:0.3
                         animations:^{ annView.frame = endFrame; }];
    }
}

@end
