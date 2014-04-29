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
#import "ExploreSnapbyViewController.h"
#import "CommentsViewController.h"

@protocol MyProfileViewControllerDelegate;

@interface ProfileViewController : UIViewController <CommentsVCDelegate, UIScrollViewDelegate, SettingsVCDelegate, UIActionSheetDelegate, ExploreSnapbyVCDelegate>

@property (weak, nonatomic) User *currentUser;
@property (nonatomic) NSInteger profileUserId;
- (void)snapby:(Snapby *)likedSnapby likedOrUnlike:(BOOL)liked;
- (void)snapbyCommented:(Snapby *)commentedSnapby count:(NSUInteger)commentCount;
- (void)refreshSnapbies;

// Only for myProfile in the multiple controller
@property (weak, nonatomic) id <MyProfileViewControllerDelegate> profileViewControllerDelegate;

@end

@protocol MyProfileViewControllerDelegate

- (void)reloadSnapbies;
- (CLLocation *)getMyLocation;
- (void)snapby:(Snapby *)likedSnapby likedOrUnlike:(BOOL)liked onController:(NSString *)controller;
- (void)snapbyCommented:(Snapby *)commentedSnapby count:(NSUInteger)commentCount onController:(NSString *)controller;

@property (strong, nonatomic) NSMutableSet *myLikes;
@property (strong, nonatomic) NSMutableSet *myComments;

@end
