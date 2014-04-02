//
//  SettingsViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"


@interface SettingsViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) User *currentUser;

@end