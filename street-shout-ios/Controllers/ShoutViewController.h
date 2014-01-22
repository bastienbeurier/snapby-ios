//
//  ShoutViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shout.h"
#import <MapKit/MapKit.h>

@protocol ShoutVCDelegate;

@interface ShoutViewController : UIViewController <UIActionSheetDelegate, MKMapViewDelegate>

@property (strong, nonatomic) Shout *shout;

@property (weak, nonatomic) id <ShoutVCDelegate> shoutVCDelegate;

@end

@protocol ShoutVCDelegate

- (MKUserLocation *)getMyLocation;

- (void)redisplayFeed;

@property (strong, nonatomic) UIView *view;

@end
