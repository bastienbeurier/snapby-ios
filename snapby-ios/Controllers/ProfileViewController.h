//
//  ProfileViewController.h
//  snapby-ios
//
//  Created by Baptiste Truchot on 3/26/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol MyProfileViewControllerDelegate;

@interface ProfileViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) User *currentUser;
@property (nonatomic) NSInteger profileUserId;

// Only for myProfile in the multiple controller
@property (weak, nonatomic) id <MyProfileViewControllerDelegate> myProfileViewControllerDelegate;

@end

@protocol MyProfileViewControllerDelegate

- (void)startLocationUpdate;
- (void)stopLocationUpdate;

@end
