//
//  SessionUtilities.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 1/9/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "AFJSONRequestOperation.h"

@interface SessionUtilities : NSObject

+ (void)updateCurrentUserInfoInPhone:(User *)user;

+ (User *)getCurrentUser;

+ (void)setFBConnectedPref:(BOOL)isFBConnected;

+ (BOOL)isFBConnected;

+ (void)securelySaveCurrentUserToken:(NSString *)authToken;

+ (NSString *)getCurrentUserToken;

+ (BOOL)isSignedIn;

+ (void)redirectToSignIn;

+ (BOOL)invalidTokenResponse:(AFHTTPRequestOperation *)operation;

+ (void)wipeOffCredentials;

@end
