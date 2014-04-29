//
//  SettingsViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@protocol SettingsVCDelegate;

@interface SettingsViewController : UITableViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) User *currentUser;
@property (weak, nonatomic) id <SettingsVCDelegate> settingsVCDelegate;
@property (nonatomic) BOOL changeProfilePicRequest;

@end

@protocol SettingsVCDelegate

- (void)reloadSnapbiesFromSettings;

@end