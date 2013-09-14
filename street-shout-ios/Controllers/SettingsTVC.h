//
//  SettingsTVC.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/1/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingPickerViewController.h"

@protocol SettingsTVCDelegate;

@interface SettingsTVC : UITableViewController <SettingPickerViewControllerDelegate>

@property (weak, nonatomic) id <SettingsTVCDelegate> settingsTVCDelegate;

- (void)sendDeviceInfo;

@end

@protocol SettingsTVCDelegate

- (void)sendDeviceInfo;

@end
