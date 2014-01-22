//
//  Like.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/22/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Like : NSObject

+ (Like *)rawLikeToInstance:(NSDictionary *)rawLike;

+ (NSArray *)rawLikesToInstances:(NSArray *)rawLikes;

+ (NSMutableArray *)rawLikerIdsToNumbers:(NSArray *)rawLikerIds;

@property (nonatomic) NSUInteger shoutId;
@property (nonatomic) NSUInteger likerId;
@property (nonatomic, strong) NSString *likerUsername;
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (strong, nonatomic) NSString *created;

@end
