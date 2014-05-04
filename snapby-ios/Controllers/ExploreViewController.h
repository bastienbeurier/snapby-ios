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
#import "CameraViewController.h"

@interface ExploreViewController : UIViewController <CommentsVCDelegate, UIScrollViewDelegate, UIActionSheetDelegate, ExploreSnapbyVCDelegate, CLLocationManagerDelegate, CameraViewControllerDelegate>

@property (nonatomic) BOOL fullscreenModeInExplore;

- (void)reloadFeed;

@end