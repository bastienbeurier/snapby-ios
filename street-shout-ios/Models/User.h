//
//  User.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/8/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

+ (User *)rawUserToInstance:(NSDictionary *)rawUser;


@property (nonatomic) NSUInteger identifier;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *username;
@property (nonatomic) BOOL isBlackListed;
@property (nonatomic, strong) NSString *profilePicture;

@end
