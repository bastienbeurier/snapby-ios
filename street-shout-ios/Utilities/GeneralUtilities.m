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

@implementation GeneralUtilities

+ (NSArray *)getShoutAgeColors
{
    return [[NSArray alloc] initWithObjects:[UIColor colorWithRed:162/256.0 green:18/256.0 blue:47/256.0 alpha:1.0],
            [UIColor colorWithRed:253/256.0 green:110/256.0 blue:138/256.0 alpha:1.0],
            [UIColor colorWithRed:255/256.0 green:194/256.0 blue:206/256.0 alpha:1.0],
            nil];
}

+ (NSUInteger)colorNumber
{
    return [self getShoutAgeColors].count;
}

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
    
    if (shoutAge < kShoutDuration / 24) {
        if (selected) {
            return [NSString stringWithFormat:@"shout-marker-%d-selected", 3];
        } else {
            return [NSString stringWithFormat:@"shout-marker-%d-deselected", 3];
        }
    } else if (shoutAge < 23 * (kShoutDuration / 24)) {
        if (selected) {
            return [NSString stringWithFormat:@"shout-marker-%d-selected", 2];
        } else {
            return [NSString stringWithFormat:@"shout-marker-%d-deselected", 2];
        }
    } else {
        if (selected) {
            return [NSString stringWithFormat:@"shout-marker-%d-selected", 1];
        } else {
            return [NSString stringWithFormat:@"shout-marker-%d-deselected", 1];
        }
    }
    
    for (int i = 1; i <= [self colorNumber]; i++) {
        if (shoutAge < (kShoutDuration / [self colorNumber]) * i) {
            if (selected) {
                return [NSString stringWithFormat:@"shout-marker-%d-selected", [self colorNumber] - i + 1];
            } else {
                return [NSString stringWithFormat:@"shout-marker-%d-deselected", [self colorNumber] - i + 1];
            }
        }
    }
    
    if (selected) {
        return @"shout-marker-1-selected";
    } else {
        return @"shout-marker-1-deselected";
    }
}

+ (UIColor *)getShoutAgeColor:(Shout *)shout
{
    NSTimeInterval shoutAge = [TimeUtilities getShoutAge:shout.created];
    
    if (shoutAge < kShoutDuration / 24) {
        return [[self getShoutAgeColors] objectAtIndex:0];
    } else if (shoutAge < 23 * (kShoutDuration / 24)) {
        return [[self getShoutAgeColors] objectAtIndex:1];
    } else {
        return [[self getShoutAgeColors] objectAtIndex:2];
    }
}

@end
