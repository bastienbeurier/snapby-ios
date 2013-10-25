//
//  RefineShoutLocationViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/13/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "RefineShoutLocationViewController.h"
#import "Constants.h"
#import "LocationUtilities.h"
#import "CreateShoutViewController.h"
#import "ImageUtilities.h"

#define MAP_CORNER_RADIUS 20

@interface RefineShoutLocationViewController () <MKMapViewDelegate>

@property (strong, nonatomic) MKPointAnnotation *shoutAnnotation;

@property (weak, nonatomic) IBOutlet UIButton *refreshMapButton;

@end

@implementation RefineShoutLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    
    //Round corners
    [self.mapView.layer setCornerRadius:MAP_CORNER_RADIUS];
    
    
    //Drop shadows
    [ImageUtilities addDropShadowToView:self.refreshMapButton];
    
    [self updateMyLocation];
    
    //Navigation bar
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.hidesBackButton = YES;
    
    //Add done button to nav bar
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Done"
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(doneButtonClicked)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)updateMyLocation
{
    MKUserLocation *mapUserLocation = self.mapView.userLocation;
    
    if (mapUserLocation && mapUserLocation.coordinate.longitude != 0 && mapUserLocation.coordinate.latitude != 0 &&
        mapUserLocation.coordinate.longitude != -180 && mapUserLocation.coordinate.latitude != -180) {
        self.myLocation = mapUserLocation.location;
    }
    
    [LocationUtilities animateMap:self.mapView
                        ToLatitude:self.myLocation.coordinate.latitude
                         Longitude:self.myLocation.coordinate.longitude
                      WithDistance:2*kShoutRadius
                          Animated:NO];
    
    self.refineShoutLocationVCDelegate.myLocation = self.myLocation;
        
    if (self.shoutAnnotation) [self.mapView removeAnnotation:self.shoutAnnotation];
    self.shoutAnnotation = [[MKPointAnnotation alloc] init];
    self.shoutAnnotation.coordinate = self.myLocation.coordinate;
    [self.mapView addAnnotation:self.shoutAnnotation];
    [self.mapView selectAnnotation:self.shoutAnnotation animated:NO];
    [self updateShoutLocation:self.myLocation];
}

- (IBAction)refreshMapClicked:(id)sender {
    [self updateMyLocation];
}

- (void) doneButtonClicked {
    [self.refineShoutLocationVCDelegate showMapInCreateShoutViewController];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding) {
        CLLocation *newShoutLocation = [[CLLocation alloc] initWithLatitude:annotationView.annotation.coordinate.latitude
                                                                  longitude:annotationView.annotation.coordinate.longitude];
        [self updateShoutLocation:newShoutLocation];
    }
}

- (void)updateShoutLocation:(CLLocation *)newShoutLocation
{
    self.refinedShoutLocation = newShoutLocation;
    [self.refineShoutLocationVCDelegate updateCreateShoutLocation:newShoutLocation];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        [self.mapView selectAnnotation:self.shoutAnnotation animated:NO];
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
