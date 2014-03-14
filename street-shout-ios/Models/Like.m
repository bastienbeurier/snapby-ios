//
//  Like.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/22/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "Like.h"

#define SHOUT_ID @"shout_id"
#define LIKER_ID @"liker_id"
#define LIKER_USERNAME @"liker_username"
#define LAT @"lat"
#define LNG @"lng"
#define CREATED_AT @"created_at"

@implementation Like

+ (Like *)rawLikeToInstance:(NSDictionary *)rawLike
{
    Like *like = [[Like alloc] init];
    
    like.shoutId = [[rawLike objectForKey:SHOUT_ID] integerValue];
    like.likerId = [[rawLike objectForKey:LIKER_ID] integerValue];
    like.likerUsername = [rawLike objectForKey:LIKER_USERNAME];
    like.created = [rawLike objectForKey:CREATED_AT];
    
    NSString *rawLat = [rawLike objectForKey:LAT];
    NSString *rawLng = [rawLike objectForKey:LNG];
    
    if (rawLat && rawLng &&
        rawLat != (id)[NSNull null] && rawLng != (id)[NSNull null]) {
        like.lat = [rawLat doubleValue];
        like.lng = [rawLng doubleValue];
    } else {
        like.lat = 0;
        like.lng = 0;
    }
    
    return like;
}

+ (NSArray *)rawLikesToInstances:(NSArray *)rawLikes
{
    NSMutableArray *likes = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawLike in rawLikes) {
        [likes addObject:[Like rawLikeToInstance:rawLike]];
    }
    
    return likes;
}

+ (NSMutableArray *)rawLikerIdsToNumbers:(NSArray *)rawLikerIds
{
    NSMutableArray *likerIds = [[NSMutableArray alloc] init];
    
    for (NSString *rawLikerId in rawLikerIds) {
        [likerIds addObject:[NSNumber numberWithLong:[rawLikerId integerValue]]];
    }
    
    return likerIds;
}

@end
