//
//  MultipleViewController.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/18/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "ExploreViewController.h"

@interface MultipleViewController : UIViewController <UIPageViewControllerDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ExploreControllerDelegate, SettingsViewControllerDelegate, CreateShoutViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

@end
