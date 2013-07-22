//
//  NavigationViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface NavigationViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) NSMutableDictionary *displayedShouts;

@end
