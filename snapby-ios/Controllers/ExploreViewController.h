//
//  MapViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snapby.h"
#import "DisplayViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "ExploreSnapbyViewController.h"

@protocol ExploreViewControllerDelegate;

@interface ExploreViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, ExploreSnapbyVCDelegate>

@property (weak, nonatomic) id <ExploreViewControllerDelegate> exploreVCDelegate;

- (void) moveMapToMyLocationAndLoadSnapbies;

@end

@protocol ExploreViewControllerDelegate

- (CLLocation *)getMyLocation;
- (void)refreshProfileSnapbies;

@end
