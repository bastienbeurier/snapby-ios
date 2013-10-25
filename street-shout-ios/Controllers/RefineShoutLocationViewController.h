//
//  RefineShoutLocationViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/13/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol RefineShoutLocationViewControllerDelegate;

@interface RefineShoutLocationViewController : UIViewController
    @property (weak, nonatomic) id <RefineShoutLocationViewControllerDelegate> refineShoutLocationVCDelegate;
    @property (strong, nonatomic) CLLocation *refinedShoutLocation;
    @property (strong, nonatomic) CLLocation *myLocation;
    @property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@protocol RefineShoutLocationViewControllerDelegate

- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation;

- (void)showMapInCreateShoutViewController;

@property (nonatomic, strong) CLLocation *myLocation;

@end
