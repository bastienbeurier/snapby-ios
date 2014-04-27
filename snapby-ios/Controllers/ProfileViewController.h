//
//  ProfileViewController.h
//  snapby-ios
//
//  Created by Baptiste Truchot on 3/26/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import <GoogleMaps/GoogleMaps.h>
#import "DisplayViewController.h"
#import "SettingsViewController.h"

@protocol MyProfileViewControllerDelegate;

@interface ProfileViewController : UIViewController <UIScrollViewDelegate, SettingsVCDelegate>

@property (weak, nonatomic) User *currentUser;
@property (nonatomic) NSInteger profileUserId;

- (void)refreshSnapbies;

// Only for myProfile in the multiple controller
@property (weak, nonatomic) id <MyProfileViewControllerDelegate> profileViewControllerDelegate;

@end

@protocol MyProfileViewControllerDelegate

- (void)startLocationUpdate;
- (void)stopLocationUpdate;
- (void)refreshExploreSnapbies;
- (void)showSettings;
- (void)changeProfilePicture;

@end
