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

#define COLOR1 [UIColor colorWithRed:219/256.0 green:98/256.0 blue:40/256.0 alpha:1.0]
#define COLOR2 [UIColor colorWithRed:220/256.0 green:108/256.0 blue:39/256.0 alpha:1.0]
#define COLOR3 [UIColor colorWithRed:223/256.0 green:117/256.0 blue:39/256.0 alpha:1.0]
#define COLOR4 [UIColor colorWithRed:224/256.0 green:126/256.0 blue:38/256.0 alpha:1.0]
#define COLOR5 [UIColor colorWithRed:227/256.0 green:135/256.0 blue:37/256.0 alpha:1.0]
#define COLOR6 [UIColor colorWithRed:228/256.0 green:143/256.0 blue:37/256.0 alpha:1.0]
#define COLOR7 [UIColor colorWithRed:231/256.0 green:152/256.0 blue:35/256.0 alpha:1.0]
#define COLOR8 [UIColor colorWithRed:232/256.0 green:161/256.0 blue:34/256.0 alpha:1.0]
#define COLOR9 [UIColor colorWithRed:235/256.0 green:170/256.0 blue:32/256.0 alpha:1.0]
#define COLOR10 [UIColor colorWithRed:236/256.0 green:179/256.0 blue:30/256.0 alpha:1.0]
#define COLOR11 [UIColor colorWithRed:239/256.0 green:189/256.0 blue:27/256.0 alpha:1.0]
#define COLOR12 [UIColor colorWithRed:241/256.0 green:198/256.0 blue:23/256.0 alpha:1.0]

@implementation GeneralUtilities

+ (NSArray *)getShoutAgeColors
{
    return [[NSArray alloc] initWithObjects:[UIColor colorWithRed:219/256.0 green:98/256.0 blue:40/256.0 alpha:1.0],
            [UIColor colorWithRed:220/256.0 green:108/256.0 blue:39/256.0 alpha:1.0],
            [UIColor colorWithRed:223/256.0 green:117/256.0 blue:39/256.0 alpha:1.0],
            [UIColor colorWithRed:224/256.0 green:126/256.0 blue:38/256.0 alpha:1.0],
            [UIColor colorWithRed:227/256.0 green:135/256.0 blue:37/256.0 alpha:1.0],
            [UIColor colorWithRed:228/256.0 green:143/256.0 blue:37/256.0 alpha:1.0],
            [UIColor colorWithRed:231/256.0 green:152/256.0 blue:35/256.0 alpha:1.0],
            [UIColor colorWithRed:232/256.0 green:161/256.0 blue:34/256.0 alpha:1.0],
            [UIColor colorWithRed:235/256.0 green:170/256.0 blue:32/256.0 alpha:1.0],
            [UIColor colorWithRed:236/256.0 green:179/256.0 blue:30/256.0 alpha:1.0],
            [UIColor colorWithRed:239/256.0 green:189/256.0 blue:27/256.0 alpha:1.0],
            [UIColor colorWithRed:241/256.0 green:198/256.0 blue:23/256.0 alpha:1.0],
            nil];
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

+ (UIColor *)getShoutAgeColor:(Shout *)shout
{
    NSTimeInterval shoutAge = [TimeUtilities getShoutAge:shout.created];
    
    for (int i = 0; i < COLORS_NBR; i++) {
        if (shoutAge < (kShoutDuration / COLORS_NBR) * (i + 1)) {
            return [[self getShoutAgeColors] objectAtIndex:i];
        }
    }
    
    return [[self getShoutAgeColors] objectAtIndex:COLORS_NBR - 1];
}

@end
