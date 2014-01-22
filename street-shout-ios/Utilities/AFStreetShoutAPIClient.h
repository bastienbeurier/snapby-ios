//
//  AFStreetShoutAPIClient.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFHTTPClient.h"
#import "Shout.h"
#import "User.h"
#import "Comment.h"

@interface AFStreetShoutAPIClient : AFHTTPClient

+ (AFStreetShoutAPIClient *)sharedClient;

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates
              AndExecuteSuccess:(void(^)(NSArray *shouts))sucessBlock failure:(void (^)())failureBlock;

+ (void)createShoutWithLat:(double)lat
                       Lng:(double)lng
                  Username:(NSString *)username
               Description:(NSString *)description
                     Image:(NSString *)imageUrl
                    UserId:(NSUInteger)userId
         AndExecuteSuccess:(void(^)(Shout *))successBlock
                   Failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)getShoutInfo:(NSUInteger)shoutId AndExecute:(void(^)(Shout *shout))successBlock;

+ (void)reportShout:(NSUInteger)shoutId withFlaggerId:(NSUInteger)flaggerId withMotive:(NSString *)motive AndExecute:(void(^)())successBlock Failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)checkAPIVersion:(NSString*)apiVersion IsObsolete:(void(^)())obsoleteBlock;

+ (void)signinWithEmail:(NSString *)email password:(NSString *)password success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock;

+ (void)signupWithEmail:(NSString *)email password:(NSString *)password username:(NSString *)username success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(NSDictionary *errors))failureBlock;

+ (void)updateUserInfoWithLat:(double)lat Lng:(double)lng;

+ (void)updateUserInfo;

+ (void)signInOrUpWithFacebookWithParameters: (id)params success:(void(^)(User *user, NSString *authToken, BOOL isSignup))successBlock failure:(void(^)())failureBlock;

+ (void)sendResetPasswordInstructionsToEmail: (NSString *) email success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getCommentsForShout:(Shout *)shout success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)getShoutMetaData:(Shout *)shout success:(void(^)(NSInteger commentCount))successBlock failure:(void(^)())failureBlock;

@end

