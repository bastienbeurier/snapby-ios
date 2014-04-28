//
//  Snapby.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "Snapby.h"
#import "ApiUtilities.h"
#import "Constants.h"

#define SNAPBY_ID @"id"
#define USER_ID @"user_id"
#define SNAPBY_LAT @"lat"
#define SNAPBY_LNG @"lng"
#define SNAPBY_CREATED_AT @"created_at"
#define LAST_ACTIVE @"last_active"
#define SNAPBY_USERNAME @"username"
#define SNAPBY_IMAGE @"image"
#define SNAPBY_REMOVED @"removed"
#define SNAPBY_ANONYMOUS @"anonymous"
#define LIKE_COUNT @"like_count"
#define COMMENT_COUNT @"comment_count"
#define USER_SCORE @"user_score"

@implementation Snapby

+ (Snapby *)rawSnapbyToInstance:(NSDictionary *)rawSnapby
{
    Snapby *snapby = [[Snapby alloc] init];
    snapby.identifier = [[rawSnapby objectForKey:SNAPBY_ID] integerValue];
    snapby.userId = [[rawSnapby objectForKey:USER_ID] integerValue];
    snapby.lat = [[rawSnapby objectForKey:SNAPBY_LAT] doubleValue];
    snapby.lng = [[rawSnapby objectForKey:SNAPBY_LNG] doubleValue];
    snapby.created = [rawSnapby objectForKey:SNAPBY_CREATED_AT];
    snapby.lastActive = [rawSnapby objectForKey:LAST_ACTIVE];
    snapby.username = [rawSnapby objectForKey:SNAPBY_USERNAME];
    snapby.removed = [[rawSnapby objectForKey:SNAPBY_REMOVED] integerValue] == 1 ? YES : NO;
    snapby.anonymous = [[rawSnapby objectForKey:SNAPBY_ANONYMOUS] integerValue] == 1 ? YES : NO;
    
    snapby.likeCount = [[rawSnapby objectForKey:LIKE_COUNT] integerValue];
    snapby.commentCount = [[rawSnapby objectForKey:COMMENT_COUNT] integerValue];
    
    if ([rawSnapby objectForKey:USER_SCORE] != (id)[NSNull null]) {
        snapby.userScore = [[rawSnapby objectForKey:USER_SCORE] integerValue];
    }
    
    return snapby;
}

+ (NSArray *)rawSnapbiesToInstances:(NSArray *)rawSnapbies
{
    NSMutableArray *snapbies = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawSnapby in rawSnapbies) {
        [snapbies addObject:[Snapby rawSnapbyToInstance:rawSnapby]];
    }
    
    return snapbies;
}

- (NSURL *)getSnapbyImageURL
{
    NSString *baseURL = PRODUCTION ? kProdSnapbyImageBaseURL : kDevSnapbyImageBaseURL;
    
    return [NSURL URLWithString:[baseURL stringByAppendingFormat:@"%lu",(unsigned long)self.identifier]];
}

- (NSURL *)getSnapbyThumbURL
{
    NSString *baseURL = PRODUCTION ? kProdSnapbyThumbBaseURL : kDevSnapbyThumbBaseURL;
    
    return [NSURL URLWithString:[baseURL stringByAppendingFormat:@"%lu",(unsigned long)self.identifier]];
}

@end
