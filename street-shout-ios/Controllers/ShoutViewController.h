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

@interface ShoutViewController : UIViewController <UIActionSheetDelegate>

@property (strong, nonatomic) Shout *shout;

@property (weak, nonatomic) id <ShoutVCDelegate> shoutVCDelegate;

@end

@protocol ShoutVCDelegate

- (void)displayShoutImage:(Shout *)shout;

- (MKUserLocation *)getMyLocation;

- (void)animateMapWhenZoomOnShout:(Shout *)shout;

//Hack to remove the selection highligh from the cell during the back animation
- (void)redisplayFeed;

@property (strong, nonatomic) UIView *view;

@end
