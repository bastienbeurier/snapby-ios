//
//  SessionUtilities.m
//  street-shout-ios
//
//  Created by Baptiste Truchot on 1/9/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "SessionUtilities.h"
#import "Constants.h"

@implementation SessionUtilities

+ (void)updateCurrentUserInfoInPhone:(User *)currentUser
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSNumber *userId = [NSNumber numberWithInt:currentUser.identifier];
    
    [prefs setObject:userId forKey:USER_ID_PREF];
    [prefs setObject:currentUser.email forKey:USER_EMAIL_PREF];
    [prefs setObject:currentUser.username forKey:USERNAME_PREF];
    
    [prefs synchronize];
}

+ (User *)getCurrentUser
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    User *user= [[User alloc] init];
    user.identifier = [[prefs objectForKey:USER_ID_PREF] integerValue];
    user.email = [prefs objectForKey:USER_EMAIL_PREF];
    user.username = [prefs objectForKey:USERNAME_PREF];
    
    if (user.identifier && user.email && user.username) {
        return user;
    } else {
        return nil;
    }
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
+ (BOOL)loggedIn
{
    return [SessionUtilities getCurrentUser] && [SessionUtilities getCurrentUserToken];
}

// redirect to entry view (sign in)
+ (void) redirectToSignIn
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    window.rootViewController = [storyboard instantiateInitialViewController];
}

+ (BOOL)invalidTokenResponse:(AFHTTPRequestOperation *)operation
{
    return operation && [operation.response statusCode] == 401;
}

@end
