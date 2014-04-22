//
//  GeneralUtilities.h
//  snapby-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "Snapby.h"

@interface GeneralUtilities : NSObject

+ (NSString *)getDeviceID;

+ (NSUInteger)currentDateInMilliseconds;

+ (NSString *)getUADeviceToken;

+ (BOOL)connected;

+ (NSString *)getAnnotationPinImageForSnapby:(Snapby *)snapby;

+ (UIColor *)getSnapbyAgeColor:(Snapby *)snapby;

+ (void)resizeView:(UIView *)view Width:(double)width;

+ (void)redirectToAppStore;

+ (BOOL)validEmail:(NSString *)email;

+ (BOOL)validUsername:(NSString *)username;

+ (NSArray *)checkForRemovedSnapbies:(NSArray *)snapbies;

+ (void)enrichParamsWithGeneralUserAndDeviceInfo:(NSMutableDictionary *)parameters;

+ (void)showMessage:(NSString *)text withTitle:(NSString *)title;

+ (void)adaptHeightTextView:(UITextView *)textView;

@end
