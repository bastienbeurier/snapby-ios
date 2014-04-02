//
//  ExploreViewController.h
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
#import "CommentsViewController.h"

@protocol ExploreControllerDelegate;


@interface ExploreViewController : UIViewController <MapViewControllerDelegate, FeedTVCDelegate, ShoutVCDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id <ExploreControllerDelegate> exploreControllerdelegate;
@property (strong, nonatomic) Shout *redirectToShout;
@property (weak, nonatomic) User *currentUser;

- (void)onShoutNotificationPressedWhileAppInNavigationVC:(Shout *)shout;

@end

@protocol ExploreControllerDelegate

- (void)moveToImagePickerController;
- (void)startLocationUpdate;
- (void)stopLocationUpdate;

@end
