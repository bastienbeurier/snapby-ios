//
//  GeneralUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "GeneralUtilities.h"
#import "Constants.h"
#import "TimeUtilities.h"

#define COLORS_NBR 12

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
    if (PRODUCTION) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:UA_DEVICE_TOKEN_PROD_PREF];
    } else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:UA_DEVICE_TOKEN_DEV_PREF];
    }
}

+ (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return !(networkStatus == NotReachable);
}

+ (NSString *)getAnnotationPinImageForShout:(Shout *)shout selected:(BOOL)selected
{
    NSTimeInterval shoutAge = [TimeUtilities getShoutAge:shout.created];
    
    for (int i = 1; i <= COLORS_NBR; i++) {
        if (shoutAge < (kShoutDuration / COLORS_NBR) * i) {
            if (selected) {
                return [NSString stringWithFormat:@"shout-marker-%d-selected", COLORS_NBR - i + 1];
            } else {
                return [NSString stringWithFormat:@"shout-marker-%d-deselected", COLORS_NBR - i + 1];
            }
        }
    }
    
    if (selected) {
        return @"shout-marker-1-selected";
    } else {
        return @"shout-marker-1-deselected";
    }
}

@end
