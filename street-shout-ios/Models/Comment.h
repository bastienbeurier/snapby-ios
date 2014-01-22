//
//  Comment.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject

+ (Comment *)rawCommentToInstance:(NSDictionary *)rawComment;

+ (NSArray *)rawCommentsToInstances:(NSArray *)rawComments;

@property (nonatomic) NSUInteger shoutId;
@property (nonatomic) NSUInteger shouterId;
@property (nonatomic) NSUInteger commenterId;
@property (nonatomic, strong) NSString *commenterUsername;
@property (nonatomic, strong) NSString *description;
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (strong, nonatomic) NSString *created;

@end
