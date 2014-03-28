//
//  ProfileViewController.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/26/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol MyProfileViewControllerDelegate;

@interface ProfileViewController : UIViewController

@property (weak, nonatomic) User *currentUser;
@property (nonatomic) NSInteger profileUserId;

// Only for myProfile in the multiple controller
@property (weak, nonatomic) id <MyProfileViewControllerDelegate> myProfileViewControllerDelegate;

@end

@protocol MyProfileViewControllerDelegate

- (void)moveToImagePickerController;
- (void)startLocationUpdate;
- (void)stopLocationUpdate;

@end
