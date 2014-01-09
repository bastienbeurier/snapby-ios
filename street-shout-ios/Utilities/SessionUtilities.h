//
//  SessionUtilities.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 1/9/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface SessionUtilities : NSObject

+ (void)updateCurrentUserInfoInPhone:(User *)user;

+ (void)securelySaveCurrentUserToken:(NSString *)authToken;

+ (NSString *)getCurrentUserToken;

+ (User *)getCurrentUser;

+ (BOOL)loggedIn;

+ (void) redirectToSignIn;

@end
