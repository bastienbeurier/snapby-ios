//
//  SettingsViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingPickerViewController.h"

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UIViewController <SettingPickerViewControllerDelegate>

@property (weak, nonatomic) id <SettingsViewControllerDelegate> settingsViewControllerDelegate;

- (void)sendDeviceInfo;

@end

@protocol SettingsViewControllerDelegate

- (void)sendDeviceInfo;

- (void)refreshShouts;

@end