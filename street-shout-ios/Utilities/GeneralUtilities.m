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
#import "DeviceUtilities.h"

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
    
    if (shoutAge < kShoutDuration / kShoutDurationHours) {
        if (selected) {
            return [NSString stringWithFormat:@"shout-marker-%d-selected", 3];
        } else {
            return [NSString stringWithFormat:@"shout-marker-%d-deselected", 3];
        }
    } else if (shoutAge < 3 * (kShoutDuration / kShoutDurationHours)) {
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
}

+ (UIColor *)getShoutAgeColor:(Shout *)shout
{
    NSTimeInterval shoutAge = [TimeUtilities getShoutAge:shout.created];
    
    if (shoutAge < kShoutDuration / kShoutDurationHours) {
        return [[self getShoutAgeColors] objectAtIndex:0];
    } else if (shoutAge < 3 * (kShoutDuration / kShoutDurationHours)) {
        return [[self getShoutAgeColors] objectAtIndex:1];
    } else {
        return [[self getShoutAgeColors] objectAtIndex:2];
    }
}

+ (void)resizeView:(UIView *)view Width:(double)width
{
    UIView *superView = view.superview;
    [view removeFromSuperview];
    [view setTranslatesAutoresizingMaskIntoConstraints:YES];
    view.frame = CGRectMake(view.frame.origin.x,
                            view.frame.origin.y,
                            width,
                            view.frame.size.height);
    [superView addSubview:view];
}

+ (void)redirectToAppStore
{
    NSString *reviewURL = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8",APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
};

+ (BOOL)validEmail:(NSString *)email
{
    NSString *emailExp = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    
    NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:emailExp options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSRange matchRange = [emailRegex rangeOfFirstMatchInString:email options:0 range:NSMakeRange(0, [email length])];
    
    return matchRange.length == [email length];
}

+ (BOOL)validUsername:(NSString *)username
{
    NSString *usernameExp = @"[A-Z0-9a-z._+-]";
    
    NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:usernameExp options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSUInteger usernameMatches = [usernameRegex numberOfMatchesInString:username options:0 range:NSMakeRange(0, [username length])];
    
    return usernameMatches == [username length];
}

+ (NSArray *)checkForRemovedShouts:(NSArray *)shouts
{
    NSMutableArray *filteredShouts = [[NSMutableArray alloc] initWithCapacity:[shouts count]];
    
    for (Shout *shout in shouts) {
        if (!shout.removed) {
            [filteredShouts addObject:shout];

        }
    }
    
    return filteredShouts;
}

+ (void)enrichParamsWithGeneralUserAndDeviceInfo:(NSMutableDictionary *)parameters;
{
    NSString *deviceModel = [DeviceUtilities platformString];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *osType = @"ios";
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *apiVersion = kApiVersion;
    
    [parameters setObject:deviceModel forKey:@"device_model"];
    [parameters setObject:osVersion forKey:@"os_version"];
    [parameters setObject:osType forKey:@"os_type"];
    [parameters setObject:appVersion forKey:@"app_version"];
    [parameters setObject:apiVersion forKey:@"api_version"];
}

@end
