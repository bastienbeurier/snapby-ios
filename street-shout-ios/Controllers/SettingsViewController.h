//
//  SettingsViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) id <SettingsViewControllerDelegate> settingsViewControllerdelegate;

@end

@protocol SettingsViewControllerDelegate

- (void)moveToImagePickerController;
- (void)startLocationUpdate;
- (void)stopLocationUpdate;

@end