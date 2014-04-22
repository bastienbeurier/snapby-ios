//
//  Snapby.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Snapby : NSObject

+ (NSArray *)rawSnapbiesToInstances:(NSArray *)rawSnapbies;
+ (Snapby *)rawSnapbyToInstance:(id)rawSnapby;
- (NSURL *)getSnapbyImageURL;
- (NSURL *)getSnapbyThumbURL;

@property (nonatomic) NSUInteger identifier;
@property (nonatomic) NSUInteger userId;
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (strong, nonatomic) NSString *created;
@property (strong, nonatomic) NSString *lastActive;
@property (strong, nonatomic) NSString *username;
@property (nonatomic) BOOL removed;
@property (nonatomic) BOOL anonymous;
@property (nonatomic) NSUInteger likeCount;
@property (nonatomic) NSUInteger commentCount;
@property (nonatomic) NSUInteger userScore;

@end
