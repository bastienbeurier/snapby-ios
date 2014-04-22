//
//  MultipleViewController.h
//  snapby-ios
//
//  Created by Baptiste Truchot on 3/18/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ProfileViewController.h"
#import "ExploreViewController.h"
#import <CoreLocation/CLLocationManager.h>

@interface MultipleViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ExploreControllerDelegate, MyProfileViewControllerDelegate, CreateSnapbyViewControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

- (ExploreViewController *) getOrInitExploreViewController;

@end
