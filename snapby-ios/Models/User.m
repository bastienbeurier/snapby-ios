//
//  User.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "User.h"
#import "Constants.h"

#define USER_ID @"id"
#define USER_EMAIL @"email"
#define USERNAME @"username"
#define BLACKLISTED @"black_listed"
#define SNAPBY_COUNT @"snapby_count"
#define LIKED_SNAPBIES @"liked_snapbies"
#define LAT @"lat"
#define LNG @"lng"

@implementation User

+ (User *)rawUserToInstance:(NSDictionary *)rawUser
{
    User *user= [[User alloc] init];
    user.identifier = [[rawUser objectForKey:USER_ID] integerValue];
    user.email = [rawUser objectForKey:USER_EMAIL];
    user.username = [rawUser objectForKey:USERNAME];
    user.snapbyCount = [[rawUser objectForKey:SNAPBY_COUNT] intValue];
    user.likedSnapbies = [[rawUser objectForKey:LIKED_SNAPBIES] intValue];
    
    if ([rawUser objectForKey:LAT] != (id)[NSNull null]) {
        user.lat = [[rawUser objectForKey:LAT] doubleValue];
    }
    if ([rawUser objectForKey:LNG] != (id)[NSNull null]) {
        user.lng = [[rawUser objectForKey:LNG] doubleValue];
    }
    
    return user;
}

+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId
{
    NSString *baseURL = PRODUCTION ? kProdProfilePicsBaseURL : kDevProfilePicsBaseURL;
    return [NSURL URLWithString:[baseURL stringByAppendingFormat:@"%lu",(unsigned long)userId]];
}

@end
