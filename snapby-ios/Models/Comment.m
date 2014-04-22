//
//  Comment.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "Comment.h"

#define SNAPBY_ID @"snapby_id"
#define SNAPBYER_ID @"snapbyer_id"
#define COMMENTER_ID @"commenter_id"
#define COMMENTER_USERNAME @"commenter_username"
#define DESCRIPTION @"description"
#define LAT @"lat"
#define LNG @"lng"
#define CREATED_AT @"created_at"
#define COMMENTER_SCORE @"commenter_score"

@implementation Comment

+ (Comment *)rawCommentToInstance:(NSDictionary *)rawComment
{
    Comment *comment = [[Comment alloc] init];
    
    comment.snapbyId = [[rawComment objectForKey:SNAPBY_ID] integerValue];
    comment.snapbyerId = [[rawComment objectForKey:SNAPBYER_ID] integerValue];
    comment.commenterId = [[rawComment objectForKey:COMMENTER_ID] integerValue];
    comment.commenterUsername = [rawComment objectForKey:COMMENTER_USERNAME];
    comment.description = [rawComment objectForKey:DESCRIPTION];
    comment.created = [rawComment objectForKey:CREATED_AT];
    
    NSString *rawLat = [rawComment objectForKey:LAT];
    NSString *rawLng = [rawComment objectForKey:LNG];
    
    if (rawLat && rawLng &&
        rawLat != (id)[NSNull null] && rawLng != (id)[NSNull null]) {
        comment.lat = [rawLat doubleValue];
        comment.lng = [rawLng doubleValue];
    } else {
        comment.lat = 0;
        comment.lng = 0;
    }
    
    if ([rawComment objectForKey:COMMENTER_SCORE] != (id)[NSNull null]) {
        comment.commenterScore = [[rawComment objectForKey:COMMENTER_SCORE] integerValue];
    }
    
    return comment;
}

+ (NSArray *)rawCommentsToInstances:(NSArray *)rawComments
{
    NSMutableArray *comments = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawComment in rawComments) {
        [comments addObject:[Comment rawCommentToInstance:rawComment]];
    }
    
    return comments;
}

@end
