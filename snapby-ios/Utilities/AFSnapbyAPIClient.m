//
//  AFSnapbyAPIClient.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "AFSnapbyAPIClient.h"
#import "GeneralUtilities.h"
#import "Constants.h"
#import "NavigationAppDelegate.h"
#import "SessionUtilities.h"

@implementation AFSnapbyAPIClient

// ---------------
// Utilities
// ---------------

+ (AFSnapbyAPIClient *)sharedClient
{
    static AFSnapbyAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (PRODUCTION) {
            _sharedClient = [[AFSnapbyAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kProdAFSnapbyAPIBaseURLString]];
        } else {
            _sharedClient = [[AFSnapbyAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kDevAFSnapbyAPIBaseURLString]];
        }

        NSOperationQueue *operationQueue = _sharedClient.operationQueue;
        [_sharedClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if(status == AFNetworkReachabilityStatusNotReachable) {
                [operationQueue cancelAllOperations];
            }
        }];
    });
    
    return _sharedClient;
}

+ (NSString *)getBasePath
{
    return [NSString stringWithFormat:@"api/v%@/", kApiVersion];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (!self) {
        return nil;
    }
    
    return self;
}

// Enrich parameters with token
+ (BOOL) enrichParametersWithToken:(NSMutableDictionary *) parameters
{
    if ([SessionUtilities isSignedIn]){
        [parameters setObject:[SessionUtilities getCurrentUserToken] forKey:@"auth_token"];
        return true;
    } else {
        [SessionUtilities redirectToSignIn];
        return false;
    }
}



// ------------------------------------------------
// Snapby
// ------------------------------------------------

// Retrieve and display snapbies on the map
+ (void)pullSnapbiesInZone:(NSArray *)cornersCoordinates
       AndExecuteSuccess:(void(^)(NSArray *snapbies))successBlock failure:(void (^)())failureBlock
{
    NSDictionary *parameters = @{@"neLat": cornersCoordinates[0],
                                 @"neLng": cornersCoordinates[1],
                                 @"swLat": cornersCoordinates[2],
                                 @"swLng": cornersCoordinates[3]};
    
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"bound_box_snapbies.json"];
    
    [[AFSnapbyAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSArray *rawSnapbies = [result valueForKeyPath:@"snapbies"];
        successBlock([Snapby rawSnapbiesToInstances:rawSnapbies]);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}

// Snapby creation
+ (void)createSnapbyWithLat:(double)lat Lng:(double)lng Username:(NSString *)username Description:(NSString *)description encodedImage:(NSString *)encodedImage UserId:(NSUInteger)userId Anonymous:(BOOL)isAnonymous AndExecuteSuccess:(void(^)(Snapby *snapby))successBlock Failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    AFSnapbyAPIClient *manager = [AFSnapbyAPIClient sharedClient];
    
    // Enrich with token
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [parameters setObject:username forKey:@"username"];
    [parameters setObject:description forKey:@"description"];
    [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
    [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"user_id"];
    [parameters setObject:[NSNumber numberWithBool:isAnonymous] forKey:@"anonymous"];
    [parameters setObject:encodedImage forKey:@"avatar"];
    
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"snapbies.json"];
    
    [manager POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSString *rawSnapby = [result valueForKeyPath:@"snapby"];
        
        successBlock([Snapby rawSnapbyToInstance:rawSnapby]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock(task);
    }];
}

// Remove snapby
+ (void)removeSnapby: (Snapby *) snapby success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"snapbies/remove.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:[NSNumber numberWithInteger:snapby.identifier] forKey:@"snapby_id"];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if(successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if(failureBlock) {
            failureBlock();
        }
    }];
}

// Flag
+ (void)reportSnapby:(NSUInteger)snapbyId withFlaggerId:(NSUInteger)flaggerId withMotive:(NSString *)motive AndExecute:(void(^)())successBlock Failure:(void(^)())failureBlock
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [parameters setObject:[NSNumber numberWithLong:snapbyId] forKey:@"snapby_id"];
    [parameters setObject:motive forKey:@"motive"];
    [parameters setObject:[NSNumber numberWithLong:flaggerId] forKey:@"flagger_id"];
    
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"flags.json"];
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// ------------------------------------------------
// User
// ------------------------------------------------


+ (void)updateUserInfoWithLat:(double)lat Lng:(double)lng;
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingFormat:@"users/%lu.json", (unsigned long)[SessionUtilities getCurrentUser].identifier];
    
    [[AFSnapbyAPIClient sharedClient] PUT:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        // Update user info in phone
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
        [SessionUtilities updateCurrentUserInfoInPhone:user];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
    }];
}

// Check and redirect to App store API is obsolete
+ (void)checkAPIVersion:(NSString*)apiVersion IsObsolete:(void(^)())obsoleteBlock
{
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"obsolete_api.json"];
    
    NSDictionary *parameters = @{@"api_version": apiVersion};
    [[AFSnapbyAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        if ([[result valueForKeyPath:@"obsolete"] isEqualToString: @"true"]) {
            obsoleteBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"checkAPIVersion: We should not pass in this block!!!!");
    }];
}

// Sign in
+ (void)signinWithEmail:(NSString *)email password:(NSString *)password success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"users/sign_in.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:email forKey:@"email"];
    [parameters setObject:password forKey:@"password"];
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
    
        NSString *authToken = [result objectForKey:@"auth_token"];
        
        if (successBlock) {
            successBlock(user, authToken);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock(task);
        }
    }];
}

// Sign up
+ (void)signupWithEmail:(NSString *)email password:(NSString *)password username:(NSString *)username success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(NSDictionary *))failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"users.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:email forKey:@"email"];
    [parameters setObject:password forKey:@"password"];
    [parameters setObject:username forKey:@"username"];
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *errors = [JSON valueForKeyPath:@"errors"];
        
        if (errors) {
            failureBlock(errors);
        } else {
            NSDictionary *result = [JSON valueForKeyPath:@"result"];
            
            NSDictionary *rawUser = [result valueForKeyPath:@"user"];
            User *user = [User rawUserToInstance:rawUser];
            
            NSString *authToken = [result objectForKey:@"auth_token"];
            
            if (successBlock) {
                successBlock(user, authToken);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSLog(@"WRONG STATUS");
        failureBlock(nil);
    }];
}

// Sign in or up with Facebook
+ (void)connectFacebookWithParameters: (id) params success:(void(^)(User *user, NSString *authToken, BOOL isSignup))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"users/facebook_create_or_update.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[params objectForKey:@"email"] forKey:@"email"];
    [parameters setObject:[params objectForKey:@"id"] forKey:@"facebook_id"];
    [parameters setObject:[params objectForKey:@"name"] forKey:@"facebook_name"];
    [parameters setObject:[params objectForKey:@"username"] forKey:@"username"];
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        BOOL isSignup = (BOOL) [result valueForKey:@"is_signup"];
        
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
        NSString *authToken = [result objectForKey:@"auth_token"];
            
        if (successBlock) {
                successBlock(user, authToken, isSignup);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failure in connectFacebook");
        failureBlock();
    }];
}

+ (void)sendResetPasswordInstructionsToEmail: (NSString *) email success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"users/password.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    [parameters setObject:email forKey:@"email"];
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        successBlock();
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}

// Change username
+ (void)updateUsername:(NSString *)username success:(void(^)(User *))successBlock failure:(void(^)(NSDictionary *errors))failureBlock
{
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingFormat:@"users/%lu.json", (unsigned long)[SessionUtilities getCurrentUser].identifier];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:username forKey:@"username"];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *errors = [JSON valueForKeyPath:@"errors"];
        
        if (errors) {
            failureBlock(errors);
        } else {
            NSDictionary *result = [JSON valueForKeyPath:@"result"];
            
            NSDictionary *rawUser = [result valueForKeyPath:@"user"];
            User *user = [User rawUserToInstance:rawUser];
            
            if (successBlock) {
                successBlock(user);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock(nil);
    }];
}

// Change profile pic
+ (void)updateProfilePicture:(NSString *)encodedImage success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path = [[AFSnapbyAPIClient getBasePath] stringByAppendingFormat:@"users/%lu.json", (unsigned long)[SessionUtilities getCurrentUser].identifier];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:encodedImage forKey:@"avatar"];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] PATCH:path parameters:parameters success:successBlock failure:failureBlock];
}

// ------------------------------------------------
// Likes & comments
// ------------------------------------------------

+ (void)getCommentsForSnapby:(Snapby *)snapby success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"comments.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:[NSNumber numberWithLong:snapby.identifier] forKey:@"snapby_id"];
    
    // Enrich with token
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawComments = [result valueForKeyPath:@"comments"];
        
        successBlock([Comment rawCommentsToInstances:rawComments]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}

+ (void)createComment:(NSString *)comment forSnapby:(Snapby *)snapby lat:(double)lat lng:(double)lng success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"comments.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[NSNumber numberWithLong:snapby.identifier] forKey:@"snapby_id"];
    [parameters setObject:[NSNumber numberWithLong:snapby.userId] forKey:@"snapbyer_id"];
    [parameters setObject:comment forKey:@"description"];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    // Enrich with token
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawComments = [result valueForKeyPath:@"comments"];
        
        successBlock([Comment rawCommentsToInstances:rawComments]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        failureBlock();
    }];
}

+ (void)createLikeforSnapby:(Snapby *)snapby lat:(double)lat lng:(double)lng success:(void(^)(NSUInteger))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"likes.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[NSNumber numberWithLong:snapby.identifier] forKey:@"snapby_id"];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    // Enrich with token
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        failureBlock();
    }];
}

+ (void)removeLike: (Snapby *) snapby success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:@"likes/delete.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:[NSNumber numberWithInteger:snapby.identifier] forKey:@"snapby_id"];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] DELETE:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if(successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if(failureBlock) {
            failureBlock();
        }
    }];
}


// Get user info (for profile)
+ (void)getOtherUserInfo:(NSInteger) userId success:(void(^)(User *, NSInteger, NSInteger, BOOL))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:[NSString stringWithFormat:@"users/get_user_info"]];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"user_id"];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *otherUser = [User rawUserToInstance:rawUser];
        NSInteger nbFollowers = [[result valueForKeyPath:@"followers_count"] integerValue];
        NSInteger nbFollowedUsers = [[result valueForKeyPath:@"followed_count"] integerValue];
        BOOL isFollowedByCurrentUser = [[result valueForKeyPath:@"is_followed"] boolValue];
        successBlock(otherUser, nbFollowers, nbFollowedUsers, isFollowedByCurrentUser);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if(failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)getSnapbies:(NSUInteger)userId page:(NSUInteger)page pageSize:(NSUInteger)pageSize andExecuteSuccess:(void(^)(NSArray *snapbies))successBlock failure:(void (^)())failureBlock
{
    NSString *path =  [[AFSnapbyAPIClient getBasePath] stringByAppendingString:[NSString stringWithFormat:@"snapbies.json"]];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"user_id"];
    [parameters setObject:[NSNumber numberWithInteger:page] forKey:@"page"];
    [parameters setObject:[NSNumber numberWithInteger:pageSize] forKey:@"page_size"];
    
    if (![AFSnapbyAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFSnapbyAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSArray *rawSnapbies = [result valueForKeyPath:@"snapbies"];
        successBlock([Snapby rawSnapbiesToInstances:rawSnapbies]);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}



@end
