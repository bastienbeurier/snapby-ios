//
//  User.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "User.h"
#import "Constants.h"

#define USER_ID @"id"
#define USER_EMAIL @"email"
#define USERNAME @"username"

@implementation User

+ (User *)rawUserToInstance:(NSDictionary *)rawUser
{
    User *user= [[User alloc] init];
    user.identifier = [[rawUser objectForKey:USER_ID] integerValue];
    user.email = [rawUser objectForKey:USER_EMAIL];
    user.username = [rawUser objectForKey:USERNAME];
    
    return user;
}

+ (void)updateCurrentUserInfoInPhone:(User *)currentUser
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSNumber *userId = [NSNumber numberWithInt:currentUser.identifier];
    
    [prefs setObject:userId forKey:USER_ID_PREF];
    [prefs setObject:currentUser.email forKey:USER_EMAIL_PREF];
    [prefs setObject:currentUser.username forKey:USERNAME_PREF];
    
    [prefs synchronize];
}

+ (User *)currentUser
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    User *user= [[User alloc] init];
    user.identifier = [[prefs objectForKey:USER_ID_PREF] integerValue];
    user.email = [prefs objectForKey:USER_EMAIL_PREF];
    user.username = [prefs objectForKey:USERNAME_PREF];
    
    return user;
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

@end
