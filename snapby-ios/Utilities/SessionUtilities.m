//
//  SessionUtilities.m
//  snapby-ios
//
//  Created by Baptiste Truchot on 1/9/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "SessionUtilities.h"
#import "Constants.h"
#import "Mixpanel.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation SessionUtilities

+ (void)updateCurrentUserInfoInPhone:(User *)currentUser
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSNumber *userId = [NSNumber numberWithLong:currentUser.identifier];
    NSNumber *isBlackListed = [NSNumber numberWithBool:currentUser.isBlackListed];

    [prefs setObject:userId forKey:USER_ID_PREF];
    [prefs setObject:currentUser.email forKey:USER_EMAIL_PREF];
    [prefs setObject:currentUser.username forKey:USERNAME_PREF];
    [prefs setObject:isBlackListed forKey:USER_BLACKLISTED];
    
    [prefs synchronize];
}

+ (User *)getCurrentUser
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    User *user= [[User alloc] init];
    user.identifier = [[prefs objectForKey:USER_ID_PREF] integerValue];
    user.email = [prefs objectForKey:USER_EMAIL_PREF];
    user.username = [prefs objectForKey:USERNAME_PREF];
    user.isBlackListed = [[prefs objectForKey:USER_BLACKLISTED] boolValue];
    
    if (user.identifier && user.email && user.username) {
        return user;
    } else {
        return nil;
    }
}

+ (void)setFBConnectedPref:(BOOL)isFBConnected
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *fbConnect = [NSNumber numberWithBool:isFBConnected];
    [prefs setObject:fbConnect forKey:USER_CONNECT_PREF];

}

+ (BOOL) isFBConnected
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [[prefs objectForKey:USER_CONNECT_PREF] integerValue];
}

//TODO: store securely in keychain
+ (void)securelySaveCurrentUserToken:(NSString *)authToken
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setObject:authToken forKey:USER_AUTH_TOKEN_PREF];
    
    [prefs synchronize];
}

//TODO: get from keychain
+ (NSString *)getCurrentUserToken
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [prefs objectForKey:USER_AUTH_TOKEN_PREF];
}

// Check User and token are stored in the phone
+ (BOOL)isSignedIn
{
    return [SessionUtilities getCurrentUser] && [SessionUtilities getCurrentUserToken];
}

// redirect to entry view (sign in)
+ (void)redirectToSignIn
{
    [SessionUtilities wipeOffCredentials];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    window.rootViewController = [storyboard instantiateInitialViewController];
}

// Remove FB session and user token
+ (void)wipeOffCredentials
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel reset];
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    // Close the FB session and remove the access token from the cache
    // The session state handler (in the app delegate) will be called automatically
    [FBSession.activeSession closeAndClearTokenInformation];
    [FBSession.activeSession close];
    [FBSession setActiveSession:nil];
}

// Check if this is an invalid token response
+ (BOOL)invalidTokenResponse:(NSURLSessionDataTask *)task
{
    return task && [(NSHTTPURLResponse *) task.response statusCode] == 401;
}

+ (BOOL)currentUserIsAdmin
{
    return [SessionUtilities getCurrentUser].identifier < 3;
}

@end
