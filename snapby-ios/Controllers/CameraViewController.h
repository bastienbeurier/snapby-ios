//
//  CameraViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 5/1/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CreateSnapbyViewController.h"

@protocol CameraViewControllerDelegate;

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate,CreateSnapbyViewControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) id <CameraViewControllerDelegate> cameraVCDelegate;

@end

@protocol CameraViewControllerDelegate

- (void)onSnapbyCreated;
- (CLLocation *)getMyLocation;

@end