//
//  AFSnapbyAPIClient.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "Snapby.h"
#import "User.h"
#import "Comment.h"

@interface ApiUtilities : AFHTTPSessionManager

+ (ApiUtilities *)sharedClient;

// ------------------------------------------------
// Snapby
// ------------------------------------------------

+ (void)pullSnapbiesInZone:(NSArray *)cornersCoordinates page:(NSUInteger)page pageSize:(NSUInteger)pageSize
              AndExecuteSuccess:(void(^)(NSArray *snapbies, NSInteger page))sucessBlock failure:(void (^)())failureBlock;

+ (void)createSnapbyWithLat:(double)lat
                       Lng:(double)lng
                  Username:(NSString *)username
               Description:(NSString *)description
              encodedImage:(NSString *)imageUrl
                    UserId:(NSUInteger)userId
                 Anonymous:(BOOL)isAnonymous
         AndExecuteSuccess:(void(^)(Snapby *))successBlock
                   Failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)reportSnapby:(NSUInteger)snapbyId withFlaggerId:(NSUInteger)flaggerId withMotive:(NSString *)motive AndExecute:(void(^)())successBlock Failure:(void(^)())failureBlock;

+ (void)removeSnapby: (Snapby *) snapby success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)pullLocalSnapbiesWithLat:(double)lat Lng:(double)lng page:(NSUInteger)page pageSize:(NSUInteger)pageSize
               AndExecuteSuccess:(void(^)(NSArray *snapbies, NSInteger page))successBlock failure:(void (^)())failureBlock;

// ------------------------------------------------
// User
// ------------------------------------------------

+ (void)getOtherUserInfo:(NSInteger) userId success:(void(^)(User *, NSInteger, NSInteger, BOOL))successBlock failure:(void(^)())failureBlock;

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

+ (void)createComment:(NSString *)comment forSnapby:(Snapby *)snapby lat:(double)lat lng:(double)lng success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)getCommentsForSnapby:(Snapby *)snapby success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock;

+ (void)createLikeforSnapby:(Snapby *)snapby success:(void(^)(NSUInteger))successBlock failure:(void(^)())failureBlock;

+ (void)removeLike:(Snapby *)snapby success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getMyLikesAndCommentsSuccess:(void(^)(NSMutableSet *likes, NSMutableSet *comments))successBlock failure:(void(^)())failureBlock;

+ (void)getSnapbies:(NSUInteger)userId page:(NSUInteger)page pageSize:(NSUInteger)pageSize andExecuteSuccess:(void(^)(NSArray *snapbies))successBlock failure:(void (^)())failureBlock;

//getLocalSnapbiesCount


@end

