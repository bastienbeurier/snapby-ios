//
//  MultipleViewController.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/18/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ProfileViewController.h"
#import "ExploreViewController.h"
#import <CoreLocation/CLLocationManager.h>

@interface MultipleViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ExploreControllerDelegate, MyProfileViewControllerDelegate, CreateShoutViewControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

- (ExploreViewController *) getOrInitExploreViewController;

@end
