//
//  User.h
//  snapby-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

+ (User *)rawUserToInstance:(NSDictionary *)rawUser;

+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId;


@property (nonatomic) NSUInteger identifier;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *username;
@property (nonatomic) BOOL isBlackListed;
@property (nonatomic) NSInteger snapbyCount;
@property (nonatomic) NSInteger likedSnapbies;
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (nonatomic) NSUInteger userId;

@end
