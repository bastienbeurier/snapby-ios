//
//  Shout.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "Shout.h"
#import "AFStreetShoutAPIClient.h"
#import "Constants.h"

#define SHOUT_ID @"id"
#define USER_ID @"user_id"
#define SHOUT_LAT @"lat"
#define SHOUT_LNG @"lng"
#define SHOUT_DESCRIPTION @"description"
#define SHOUT_CREATED_AT @"created_at"
#define SHOUT_SOURCE @"source"
#define SHOUT_USERNAME @"username"
#define SHOUT_IMAGE @"image"
#define SHOUT_REMOVED @"removed"
#define SHOUT_ANONYMOUS @"anonymous"

@implementation Shout

+ (Shout *)rawShoutToInstance:(NSDictionary *)rawShout
{
    Shout *shout = [[Shout alloc] init];
    shout.identifier = [[rawShout objectForKey:SHOUT_ID] integerValue];
    shout.userId = [[rawShout objectForKey:USER_ID] integerValue];
    shout.lat = [[rawShout objectForKey:SHOUT_LAT] doubleValue];
    shout.lng = [[rawShout objectForKey:SHOUT_LNG] doubleValue];
    shout.description = [rawShout objectForKey:SHOUT_DESCRIPTION];
    shout.created = [rawShout objectForKey:SHOUT_CREATED_AT];
    shout.username = [rawShout objectForKey:SHOUT_USERNAME];
    shout.removed = [[rawShout objectForKey:SHOUT_REMOVED] integerValue] == 1 ? YES : NO;
    shout.anonymous = [[rawShout objectForKey:SHOUT_ANONYMOUS] integerValue] == 1 ? YES : NO;
    
    return shout;
}

+ (NSArray *)rawShoutsToInstances:(NSArray *)rawShouts
{
    NSMutableArray *shouts = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawShout in rawShouts) {
        [shouts addObject:[Shout rawShoutToInstance:rawShout]];
    }
    
    return shouts;
}

- (NSURL *)getShoutImageURL
{
    NSString *baseURL = PRODUCTION ? kProdShoutImageBaseURL : kDevShoutImageBaseURL;
    
    return [NSURL URLWithString:[[baseURL stringByAppendingFormat:@"%lu",(unsigned long)self.identifier] stringByAppendingString:@"--400"]];
}

@end
