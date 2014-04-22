//
//  Comment.h
//  snapby-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject

+ (Comment *)rawCommentToInstance:(NSDictionary *)rawComment;

+ (NSArray *)rawCommentsToInstances:(NSArray *)rawComments;

@property (nonatomic) NSUInteger snapbyId;
@property (nonatomic) NSUInteger snapbyerId;
@property (nonatomic) NSUInteger commenterId;
@property (nonatomic) NSUInteger commenterScore;
@property (nonatomic, strong) NSString *commenterUsername;
@property (nonatomic, strong) NSString *description;
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (strong, nonatomic) NSString *created;

@end
