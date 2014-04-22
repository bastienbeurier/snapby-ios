//
//  RefineSnapbyLocationViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 8/13/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "RefineSnapbyLocationViewController.h"
#import "Constants.h"
#import "LocationUtilities.h"
#import "CreateSnapbyViewController.h"
#import "ImageUtilities.h"

#define MAP_CORNER_RADIUS 20

@interface RefineSnapbyLocationViewController () <MKMapViewDelegate>

@property (strong, nonatomic) MKPointAnnotation *snapbyAnnotation;

@property (weak, nonatomic) IBOutlet UIButton *refreshMapButton;

@end

@implementation RefineSnapbyLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    
    //Round corners
    [self.mapView.layer setCornerRadius:MAP_CORNER_RADIUS];
    
    [self updateMyLocation];
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:@"Your location" sizeBig:YES inViewController:self];
}

- (void)updateMyLocation
{
    MKUserLocation *mapUserLocation = self.mapView.userLocation;
    
    if ([LocationUtilities userLocationValid:mapUserLocation.location]) {
        self.myLocation = mapUserLocation.location;
    }
    
    [LocationUtilities animateMap:self.mapView
                        ToLatitude:self.myLocation.coordinate.latitude
                         Longitude:self.myLocation.coordinate.longitude
                      WithDistance:2*kSnapbyRadius
                          Animated:NO];
        
    if (self.snapbyAnnotation) [self.mapView removeAnnotation:self.snapbyAnnotation];
    self.snapbyAnnotation = [[MKPointAnnotation alloc] init];
    self.snapbyAnnotation.coordinate = self.myLocation.coordinate;
    [self.mapView addAnnotation:self.snapbyAnnotation];
    [self.mapView selectAnnotation:self.snapbyAnnotation animated:NO];
    [self updateSnapbyLocation:self.myLocation];
}

- (IBAction)refreshMapClicked:(id)sender {
    [self updateMyLocation];
}

- (void)backButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding) {
        CLLocation *newSnapbyLocation = [[CLLocation alloc] initWithLatitude:annotationView.annotation.coordinate.latitude
                                                                  longitude:annotationView.annotation.coordinate.longitude];
        [self updateSnapbyLocation:newSnapbyLocation];
    }
}

- (void)updateSnapbyLocation:(CLLocation *)newSnapbyLocation
{
    [self.refineSnapbyLocationVCDelegate updateCreateSnapbyLocation:newSnapbyLocation];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        [self.mapView selectAnnotation:self.snapbyAnnotation animated:NO];
        return;
    }
    
    view.draggable = YES;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *aV;
    for (aV in views) {
        if ([aV.annotation isKindOfClass:[MKUserLocation class]]) {
            MKAnnotationView* annotationView = aV;
            annotationView.canShowCallout = NO;
        }
    }
}

@end
