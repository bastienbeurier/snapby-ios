//
//  AFStreetShoutAPIClient.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFStreetShoutAPIClient.h"
#import "GeneralUtilities.h"
#import "Constants.h"
#import "NavigationAppDelegate.h"
#import "SessionUtilities.h"

@implementation AFStreetShoutAPIClient

// ---------------
// Utilities
// ---------------

+ (AFStreetShoutAPIClient *)sharedClient
{
    static AFStreetShoutAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (PRODUCTION) {
            _sharedClient = [[AFStreetShoutAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kProdAFStreetShoutAPIBaseURLString]];
        } else {
            _sharedClient = [[AFStreetShoutAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kDevAFStreetShoutAPIBaseURLString]];
            
            //todoBT put this in prod too when tested
            NSOperationQueue *operationQueue = _sharedClient.operationQueue;
            [_sharedClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                if(status == AFNetworkReachabilityStatusNotReachable) {
                    [operationQueue cancelAllOperations];
                }
            }];
        }
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



// ---------------
// Requests
// ---------------

// Retrieve and display shouts on the map
+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates
       AndExecuteSuccess:(void(^)(NSArray *shouts))successBlock failure:(void (^)())failureBlock
{
    NSDictionary *parameters = @{@"neLat": cornersCoordinates[0],
                                 @"neLng": cornersCoordinates[1],
                                 @"swLat": cornersCoordinates[2],
                                 @"swLng": cornersCoordinates[3]};
    
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"bound_box_shouts.json"];
    
    [[AFStreetShoutAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSArray *rawShouts = [result valueForKeyPath:@"shouts"];
        successBlock([Shout rawShoutsToInstances:rawShouts]);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}

// Display shout from notification
+ (void)getShoutInfo:(NSUInteger)shoutId AndExecuteSuccess:(void(^)(Shout *shout))successBlock failure:(void(^)())failureBlock
{
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:[NSString stringWithFormat:@"shouts/%d", shoutId]];
    
    [[AFStreetShoutAPIClient sharedClient] GET:path parameters:nil success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSDictionary *rawShout = [result valueForKeyPath:@"shout"];
        
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Shout creation
+ (void)createShoutWithLat:(double)lat Lng:(double)lng Username:(NSString *)username Description:(NSString *)description Image:(NSString *)imageUrl UserId:(NSUInteger)userId Anonymous:(BOOL)isAnonymous AndExecuteSuccess:(void(^)(Shout *shout))successBlock Failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    AFStreetShoutAPIClient *manager = [AFStreetShoutAPIClient sharedClient];
    
    // Enrich with token
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [parameters setObject:username forKey:@"username"];
    [parameters setObject:description forKey:@"description"];
    [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
    [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"user_id"];
    [parameters setObject:[NSNumber numberWithBool:isAnonymous] forKey:@"anonymous"];
    [parameters setObject:imageUrl forKey:@"image"];
    
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"shouts.json"];
    
    [manager POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSString *rawShout = [result valueForKeyPath:@"shout"];
        
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock(task);
    }];
}

+ (void)updateUserInfo
{
    [AFStreetShoutAPIClient updateUserInfoWithLat:0 Lng:0];
}

+ (void)updateUserInfoWithLat:(double)lat Lng:(double)lng;
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingFormat:@"users/%d.json", [SessionUtilities getCurrentUser].identifier];
    
    [[AFStreetShoutAPIClient sharedClient] PUT:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        // Update user info in phone
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
        [SessionUtilities updateCurrentUserInfoInPhone:user];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
    }];
}

+ (void)reportShout:(NSUInteger)shoutId withFlaggerId:(NSUInteger)flaggerId withMotive:(NSString *)motive AndExecute:(void(^)())successBlock Failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [parameters setObject:[NSNumber numberWithInt:shoutId] forKey:@"shout_id"];
    [parameters setObject:motive forKey:@"motive"];
    [parameters setObject:[NSNumber numberWithInt:flaggerId] forKey:@"flagger_id"];

    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"flags.json"];
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock(task);
        }
    }];
}

// Check and redirect to App store API is obsolete
+ (void)checkAPIVersion:(NSString*)apiVersion IsObsolete:(void(^)())obsoleteBlock
{
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"obsolete_api.json"];
    
    NSDictionary *parameters = @{@"api_version": apiVersion};
    [[AFStreetShoutAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
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
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"users/sign_in.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:email forKey:@"email"];
    [parameters setObject:password forKey:@"password"];
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
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
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"users.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:email forKey:@"email"];
    [parameters setObject:password forKey:@"password"];
    [parameters setObject:username forKey:@"username"];
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
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
+ (void)signInOrUpWithFacebookWithParameters: (id) params success:(void(^)(User *user, NSString *authToken, BOOL isSignup))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"users/facebook_create_or_update.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[params objectForKey:@"email"] forKey:@"email"];
    [parameters setObject:[params objectForKey:@"id"] forKey:@"facebook_id"];
    [parameters setObject:[params objectForKey:@"name"] forKey:@"facebook_name"];
    [parameters setObject:[params objectForKey:@"username"] forKey:@"username"];
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        BOOL isSignup = (BOOL) [result valueForKey:@"is_signup"];
        
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
        NSString *authToken = [result objectForKey:@"auth_token"];
            
        if (successBlock) {
                successBlock(user, authToken, isSignup);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failure in signInOrUpWithFacebook");
        failureBlock();
    }];
}

+ (void)sendResetPasswordInstructionsToEmail: (NSString *) email success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"users/password.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    [parameters setObject:email forKey:@"email"];
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        successBlock(JSON);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}

+ (void)getCommentsForShout:(Shout *)shout success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"comments.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:[NSNumber numberWithInt:shout.identifier] forKey:@"shout_id"];
    
    // Enrich with token
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFStreetShoutAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawComments = [result valueForKeyPath:@"comments"];
        
        successBlock([Comment rawCommentsToInstances:rawComments]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock();
    }];
}

+ (void)createComment:(NSString *)comment forShout:(Shout *)shout lat:(double)lat lng:(double)lng success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"comments.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[NSNumber numberWithInt:shout.identifier] forKey:@"shout_id"];
    [parameters setObject:[NSNumber numberWithInt:shout.userId] forKey:@"shouter_id"];
    [parameters setObject:comment forKey:@"description"];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    // Enrich with token
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawComments = [result valueForKeyPath:@"comments"];
        
        successBlock([Comment rawCommentsToInstances:rawComments]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        failureBlock();
    }];
}

+ (void)createLikeforShout:(Shout *)shout lat:(double)lat lng:(double)lng success:(void(^)(NSUInteger))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"likes.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[NSNumber numberWithInt:shout.identifier] forKey:@"shout_id"];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    // Enrich with token
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFStreetShoutAPIClient sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        failureBlock();
    }];
}

+ (void)getLikesForShout:(Shout *)shout success:(void(^)(NSArray *))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"likes.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:[NSNumber numberWithInt:shout.identifier] forKey:@"shout_id"];
    
    // Enrich with token
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }
    
    [[AFStreetShoutAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawLikes = [result valueForKeyPath:@"likes"];
        
        successBlock([Like rawLikesToInstances:rawLikes]);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        failureBlock();
    }];
}

+ (void)getShoutMetaData:(Shout *)shout success:(void(^)(NSInteger commentCount, NSMutableArray *likerIds))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"/get_shout_meta_data.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    [parameters setObject:[NSNumber numberWithInt:shout.identifier] forKey:@"shout_id"];
    
    [[AFStreetShoutAPIClient sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSInteger commentCount = [[result objectForKey:@"comment_count"] integerValue];
        
        NSMutableArray *likerIds = [Like rawLikerIdsToNumbers:[result objectForKey:@"liker_ids"]];
        
        successBlock(commentCount, likerIds);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)updateUsername:(NSString *)username success:(void(^)(User *))successBlock failure:(void(^)(NSDictionary *errors))failureBlock
{
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"modify_user_credentials.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:username forKey:@"username"];
    
    if (![AFStreetShoutAPIClient enrichParametersWithToken: parameters]) {
        return;
    }

    [[AFStreetShoutAPIClient sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
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

@end
