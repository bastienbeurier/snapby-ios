//
//  MapViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MapViewControllerDelegate;

@interface MapViewController : UIViewController

@property (weak, nonatomic) id <MapViewControllerDelegate> mapVCdelegate;

@property (nonatomic, strong) NSArray *shouts;

@property (strong, nonatomic) NSMutableDictionary *displayedShouts;

- (void)displayShouts:(NSArray *)shouts;

@end

@protocol MapViewControllerDelegate

- (void)pullShoutsInZone:(NSArray *)mapBounds;

@end
