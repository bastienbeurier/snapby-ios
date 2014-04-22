//
//  RefineSnapbyLocationViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 8/13/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol RefineSnapbyLocationViewControllerDelegate;

@interface RefineSnapbyLocationViewController : UIViewController
    @property (weak, nonatomic) id <RefineSnapbyLocationViewControllerDelegate> refineSnapbyLocationVCDelegate;
    @property (strong, nonatomic) CLLocation *myLocation;
    @property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end


@protocol RefineSnapbyLocationViewControllerDelegate

- (void)updateCreateSnapbyLocation:(CLLocation *)snapbyLocation;

@end
