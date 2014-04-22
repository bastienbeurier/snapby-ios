//
//  ExploreViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapViewController.h"
#import "CreateSnapbyViewController.h"
#import "SnapbyViewController.h"
#import "SettingsViewController.h"
#import "CommentsViewController.h"

@protocol ExploreControllerDelegate;


@interface ExploreViewController : UIViewController <MapViewControllerDelegate, SnapbyVCDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id <ExploreControllerDelegate> exploreControllerdelegate;
@property (strong, nonatomic) Snapby *redirectToSnapby;
@property (weak, nonatomic) User *currentUser;

@end

@protocol ExploreControllerDelegate

- (void)moveToImagePickerController;
- (void)startLocationUpdate;
- (void)stopLocationUpdate;

@end
