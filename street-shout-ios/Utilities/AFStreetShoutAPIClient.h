//
//  AFStreetShoutAPIClient.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "Shout.h"
#import "User.h"
#import "Comment.h"
#import "Like.h"

@interface AFStreetShoutAPIClient : AFHTTPSessionManager

+ (AFStreetShoutAPIClient *)sharedClient;

// ------------------------------------------------
// Shout
// ------------------------------------------------

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates
              AndExecuteSuccess:(void(^)(NSArray *shouts))sucessBlock failure:(void (^)())failureBlock;

+ (void)createShoutWithLat:(double)lat
                       Lng:(double)lng
                  Username:(NSString *)username
               Description:(NSString *)description
              encodedImage:(NSString *)imageUrl
                    UserId:(NSUInteger)userId
                 Anonymous:(BOOL)isAnonymous
         AndExecuteSuccess:(void(^)(Shout *))successBlock
                   Failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)getShoutInfo:(NSUInteger)shoutId AndExecuteSuccess:(void(^)(Shout *shout))successBlock failure:(void(^)())failureBlock;

+ (void)reportShout:(NSUInteger)shoutId withFlaggerId:(NSUInteger)flaggerId withMotive:(NSString *)motive AndExecute:(void(^)())successBlock Failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)removeShout: (Shout *) shout success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)makeShoutTrending: (Shout *) shout success:(void(^)())successBlock failure:(void(^)())failureBlock;


// ------------------------------------------------
// User
// ------------------------------------------------

+ (void)checkAPIVersion:(NSString*)apiVersion IsObsolete:(void(^)())obsoleteBlock;

+ (void)signinWithEmail:(NSString *)email password:(NSString *)password success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)signupWithEmail:(NSString *)email password:(NSString *)password username:(NSString *)username success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(NSDictionary *errors))failureBlock;

+ (void)updateUserInfoWithLat:(double)lat Lng:(double)lng;

+ (void)connectFacebookWithParameters: (id)params success:(void(^)(User *user, NSString *authToken, BOOL isSignup))successBlock failure:(void(^)())failureBlock;

+ (void)sendResetPasswordInstructionsToEmail: (NSString *) email success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)updateUsername:(NSString *)username success:(void(^)(User *))successBlock failure:(void(^)(NSDictionary *errors))failureBlock;

+ (void)updateProfilePicture:(NSString *)encodedImage success:(void(^)())successBlock failure:(void(^)())failureBlock;


// ------------------------------------------------
// Likes & comments
// ------------------------------------------------

+ (void)createComment:(NSString *)comment forShout:(Shout *)shout lat:(double)lat lng:(double)lng success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)getCommentsForShout:(Shout *)shout success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)createLikeforShout:(Shout *)shout lat:(double)lat lng:(double)lng success:(void(^)(NSUInteger))successBlock failure:(void(^)())failureBlock;

+ (void)getLikesForShout:(Shout *)shout success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)getShoutMetaData:(Shout *)shout success:(void(^)(NSInteger commentCount, NSMutableArray *likerIds))successBlock failure:(void(^)())failureBlock;

+ (void)removeLike: (Shout *) shout success:(void(^)())successBlock failure:(void(^)())failureBlock;


// ------------------------------------------------
// Friendship
// ------------------------------------------------

+ (void)followUser: (NSUInteger) followedId success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)unfollowUser: (NSUInteger) relationshipId success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getFollowersOfUser:(NSInteger) followedId success:(void(^)(NSArray *users, NSArray *currentUserFollowedIds))successBlock failure:(void(^)())failureBlock;

+ (void)getFollowingOfUser:(NSInteger) followerId success:(void(^)(NSArray *, NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)getOtherUserInfo:(NSInteger) userId success:(void(^)(User *, NSInteger, NSInteger, BOOL))successBlock failure:(void(^)())failureBlock;

+ (void)createRelationshipsFromFacebookFriends:(NSArray *) friends success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getSuggestedFriendsOfUser:(NSInteger) userId success:(void(^)(NSArray *, NSArray *))successBlock failure:(void(^)())failureBlock;

@end

