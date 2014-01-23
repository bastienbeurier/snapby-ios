//
//  LikesViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/22/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shout.h"
#import <MapKit/MapKit.h>

@interface LikesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *likes;
@property (nonatomic, strong) Shout *shout;
@property (nonatomic, strong) MKUserLocation *userLocation;

@end