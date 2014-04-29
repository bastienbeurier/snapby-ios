//
//  GeneralUtilities.m
//  snapby-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "GeneralUtilities.h"
#import "Constants.h"
#import "TimeUtilities.h"
#import "DeviceUtilities.h"

@implementation GeneralUtilities

+ (NSArray *)getSnapbyAgeColors
{
    return [[NSArray alloc] initWithObjects:[UIColor colorWithRed:162/256.0 green:18/256.0 blue:47/256.0 alpha:1.0],
            [UIColor colorWithRed:253/256.0 green:110/256.0 blue:138/256.0 alpha:1.0],
            [UIColor colorWithRed:255/256.0 green:194/256.0 blue:206/256.0 alpha:1.0],
            nil];
}

+ (NSUInteger)colorNumber
{
    return [self getSnapbyAgeColors].count;
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

+ (NSString *)getAnnotationPinImageForSnapby:(Snapby *)snapby selected:(BOOL)selected
{
    if (snapby.anonymous) {
        if (selected) {
            return @"snapby-marker-anonymous-selected";
        } else {
            return @"snapby-marker-anonymous";
        }
    } else {
        if (selected) {
            return @"snapby-marker-selected";
        } else {
            return @"snapby-marker";
        }
    }
}

+ (UIColor *)getSnapbyAgeColor:(Snapby *)snapby
{
    NSTimeInterval snapbyAge = [TimeUtilities getSnapbyAge:snapby.created];
    
    if (snapbyAge < kSnapbyDuration / kSnapbyDurationHours) {
        return [[self getSnapbyAgeColors] objectAtIndex:0];
    } else if (snapbyAge < 3 * (kSnapbyDuration / kSnapbyDurationHours)) {
        return [[self getSnapbyAgeColors] objectAtIndex:1];
    } else {
        return [[self getSnapbyAgeColors] objectAtIndex:2];
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
    NSString *reviewURL = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%ld?mt=8",APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
};

+ (BOOL)validEmail:(NSString *)email
{
    NSString *emailExp = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    
    NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:emailExp options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSRange matchRange = [emailRegex rangeOfFirstMatchInString:email options:0 range:NSMakeRange(0, [email length])];
    
    return [email length] != 0 && matchRange.length == [email length];
}

+ (BOOL)validUsername:(NSString *)username
{
    NSString *usernameExp = @"[A-Z0-9a-z._+-]";
    
    NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:usernameExp options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSUInteger usernameMatches = [usernameRegex numberOfMatchesInString:username options:0 range:NSMakeRange(0, [username length])];
    
    return usernameMatches == [username length];
}

+ (NSArray *)checkForRemovedSnapbies:(NSArray *)snapbies
{
    NSMutableArray *filteredSnapbies = [[NSMutableArray alloc] initWithCapacity:[snapbies count]];
    
    for (Snapby *snapby in snapbies) {
        if (!snapby.removed) {
            [filteredSnapbies addObject:snapby];

        }
    }
    
    return filteredSnapbies;
}

+ (void)enrichParamsWithGeneralUserAndDeviceInfo:(NSMutableDictionary *)parameters;
{
    NSString *uaDeviceToken = [GeneralUtilities getUADeviceToken];
    if (uaDeviceToken) {
        [parameters setObject:uaDeviceToken forKey:@"push_token"];
    }
    
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

// Show an alert message
+ (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:@"OK!"
                      otherButtonTitles:nil] show];
}

+ (UIActivityViewController *)getShareViewController:(UIImage *)image
{
    NSString *shareString = @"Hey, check out this snapby! Discover other local pictures by downloading the Snapby app.";
    
    //            NSURL *shareUrl = [NSURL URLWithString:[[(PRODUCTION? kProdSnapbyBaseURLString : kDevAFSnapbyAPIBaseURLString) stringByAppendingString:@"snapbies/"]stringByAppendingString:[NSString stringWithFormat:@"%lu",(unsigned long)snapby.identifier]]];
    
    NSURL *shareUrl = [NSURL URLWithString:PRODUCTION? kProdSnapbyBaseURLString : kDevAFSnapbyAPIBaseURLString];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, image, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:@"Sharing a snapby with you." forKey:@"subject"];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    
    return activityViewController;
}

@end
