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
#import "CommentsViewController.h"

@protocol ExploreViewControllerDelegate;

@interface ExploreViewController : UIViewController <CommentsVCDelegate, UIScrollViewDelegate, UIActionSheetDelegate, ExploreSnapbyVCDelegate>

@property (weak, nonatomic) id <ExploreViewControllerDelegate> exploreVCDelegate;

- (void) moveMapToMyLocationAndLoadSnapbies;
- (void) onLocationObtained;

@end

@protocol ExploreViewControllerDelegate

- (CLLocation *)getMyLocation;

@property (strong, nonatomic) NSMutableSet *myLikes;
@property (strong, nonatomic) NSMutableSet *myComments;

@end
