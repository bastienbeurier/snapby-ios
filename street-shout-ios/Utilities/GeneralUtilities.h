//
//  GeneralUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "Shout.h"

@interface GeneralUtilities : NSObject

+ (NSString *)getDeviceID;

+ (NSUInteger)currentDateInMilliseconds;

+ (NSString *)getUADeviceToken;

+ (BOOL)connected;

+ (NSString *)getAnnotationPinImageForShout:(Shout *)shout selected:(BOOL)selected;

+ (UIColor *)getShoutAgeColor:(Shout *)shout;

+ (void)resizeView:(UIView *)view Width:(double)width;

+ (void)redirectToAppStore;

+ (BOOL)validEmail:(NSString *)email;

+ (BOOL)validUsername:(NSString *)username;

@end
