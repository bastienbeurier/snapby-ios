//
//  User.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

+ (NSArray *)rawUsersToInstances:(NSArray *)rawUsers;

+ (User *)rawUserToInstance:(NSDictionary *)rawUser;

- (NSURL *)getUserProfilePictureURL;
+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId;


@property (nonatomic) NSUInteger identifier;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *username;
@property (nonatomic) BOOL isBlackListed;
@property (nonatomic) NSInteger shoutCount;
@property (nonatomic) double lat;
@property (nonatomic) double lng;

@end
