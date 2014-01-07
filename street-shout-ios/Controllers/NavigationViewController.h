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
#import "ShoutViewController.h"
#import "SettingsViewController.h"

@interface NavigationViewController : UIViewController <MapViewControllerDelegate, FeedTVCDelegate, CreateShoutViewControllerDelegate, ShoutVCDelegate, SettingsViewControllerDelegate, UIAlertViewDelegate>

- (void)onShoutNotificationPressed:(Shout *)shout;

@end
