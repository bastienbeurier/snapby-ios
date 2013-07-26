//
//  NavigationViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapViewController.h"
#import "FeedTVC.h"
#import "CreateShoutViewController.h"

@interface NavigationViewController : UIViewController <MapViewControllerDelegate, FeedTVCDelegate, CreateShoutViewControllerDelegate>

@end
