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

@end
