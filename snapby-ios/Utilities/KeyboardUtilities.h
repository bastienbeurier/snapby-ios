//
//  KeyboardUtilities.h
//  snapby-ios
//
//  Created by Baptiste Truchot on 2/27/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyboardUtilities : NSObject

+ (void)pushUpTopView:(UIView *)topView whenKeyboardWillShowNotification:(NSNotification *)notification;

+ (void)pushDownTopView:(UIView *)topView whenKeyboardWillhideNotification:(NSNotification *) notification;

@end
