//
//  GeneralUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "GeneralUtilities.h"
#import "Constants.h"

@implementation GeneralUtilities

+ (NSString *)getDeviceID
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSUInteger)currentDateInMilliseconds
{
    NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970];
    return (int) seconds;
}

+ (NSString *)getUADeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:UA_DEVICE_TOKEN_PREF];
}

@end
