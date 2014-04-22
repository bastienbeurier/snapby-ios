//
//  SettingsViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"


@interface SettingsViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) User *currentUser;

@end