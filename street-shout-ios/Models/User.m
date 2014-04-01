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
#define BLACKLISTED @"black_listed"
#define PROFILE_PICTURE @"profile_picture"
#define SHOUT_COUNT @"shout_count"
#define LAT @"lat"
#define LNG @"lng"

@implementation User

+ (NSArray *)rawUsersToInstances:(NSArray *)rawUsers
{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawUser in rawUsers) {
        [users addObject:[User rawUserToInstance:rawUser]];
    }
    
    return users;
}

+ (User *)rawUserToInstance:(NSDictionary *)rawUser
{
    User *user= [[User alloc] init];
    user.identifier = [[rawUser objectForKey:USER_ID] integerValue];
    user.email = [rawUser objectForKey:USER_EMAIL];
    user.username = [rawUser objectForKey:USERNAME];
    user.shoutCount = [[rawUser objectForKey:SHOUT_COUNT] intValue];
    user.lat = [[rawUser objectForKey:LAT] doubleValue];
    user.lng = [[rawUser objectForKey:LNG] doubleValue];
    
    return user;
}

- (NSURL *)getUserProfilePicture
{
    NSString *baseURL = PRODUCTION ? kProdProfilePicsBaseURL : kDevProfilePicsBaseURL;
    return [NSURL URLWithString:[baseURL stringByAppendingFormat:@"%lu",(unsigned long)self.identifier]];
}

@end
