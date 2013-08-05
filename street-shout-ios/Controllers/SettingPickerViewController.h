//
//  SettingPickerViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/1/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingPickerViewControllerDelegate;

@interface SettingPickerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) NSArray *pickerData;
@property (strong, nonatomic) NSString *preferenceType;
@property (weak, nonatomic) id <SettingPickerViewControllerDelegate> settingPickerVCDelegate;

@end

@protocol SettingPickerViewControllerDelegate

- (void)dismissSettingPickerModal:(SettingPickerViewController *)settingPickerViewController;

@end