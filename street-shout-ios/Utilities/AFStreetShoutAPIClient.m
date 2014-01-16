//
//  AFStreetShoutAPIClient.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFStreetShoutAPIClient.h"
#import "AFJSONRequestOperation.h"
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
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

// Enrich parameters with token
+ (void) enrichParametersWithToken:(NSMutableDictionary *) parameters
{
    if ([SessionUtilities isSignedIn]){
        [parameters setObject:[SessionUtilities getCurrentUserToken] forKey:@"auth_token"];
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
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    
    [[AFStreetShoutAPIClient sharedClient] getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawShouts = [result valueForKeyPath:@"shouts"];
        
        successBlock([Shout rawShoutsToInstances:rawShouts]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        failureBlock();
    }];
}

// Display shout from notification
+ (void)getShoutInfo:(NSUInteger)shoutId AndExecute:(void(^)(Shout *shout))successBlock
{
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:[NSString stringWithFormat:@"shouts/%d", shoutId]];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSDictionary *rawShout = [result valueForKeyPath:@"shout"];
        
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        NSLog(@"ERROR!!!");
    }];
}

// Shout creation
+ (void)createShoutWithLat:(double)lat Lng:(double)lng Username:(NSString *)username Description:(NSString *)description Image:(NSString *)imageUrl UserId:(NSUInteger)userId AndExecuteSuccess:(void(^)(Shout *shout))successBlock Failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock
{    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    // Enrich with token
    [AFStreetShoutAPIClient enrichParametersWithToken: parameters];
    
    [parameters setObject:username forKey:@"username"];
    [parameters setObject:description forKey:@"description"];
    [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
    [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"user_id"];
    
    if (imageUrl) {
        [parameters setObject:imageUrl forKey:@"image"];
    }
    
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"shouts.json"];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSString *rawShout = [result valueForKeyPath:@"shout"];
        
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        failureBlock(operation);
    }];
}

+ (void)updateUserInfo
{
    [AFStreetShoutAPIClient updateUserInfoWithLat:0 Lng:0];
}

+ (void)updateUserInfoWithLat:(double)lat Lng:(double)lng;
{
    NSString *uaDeviceToken = [GeneralUtilities getUADeviceToken];
    NSNumber *notificationRadius = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIFICATION_RADIUS_PREF];
    
    if (!notificationRadius) {
        notificationRadius = [NSNumber numberWithInt:kDefaultNotificationRadiusIndex];
    }
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    [parameters setObject:notificationRadius forKey:@"notification_radius"];
    
    if (lat != 0 && lng != 0) {
        [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    }
    
    if (uaDeviceToken) {
        [parameters setObject:uaDeviceToken forKey:@"push_token"];
    }
    
    [GeneralUtilities enrichParamsWithGeneralUserAndDeviceInfo:parameters];
    [AFStreetShoutAPIClient enrichParametersWithToken: parameters];
    
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingFormat:@"users/%d.json", [SessionUtilities getCurrentUser].identifier];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] putPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    }];
}

+ (void)reportShout:(NSUInteger)shoutId withFlaggerId:(NSUInteger)flaggerId withMotive:(NSString *)motive AndExecute:(void(^)())successBlock Failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [AFStreetShoutAPIClient enrichParametersWithToken: parameters];
    
    [parameters setObject:[NSNumber numberWithInt:shoutId] forKey:@"shout_id"];
    [parameters setObject:motive forKey:@"motive"];
    [parameters setObject:[NSNumber numberWithInt:flaggerId] forKey:@"flagger_id"];

    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"flags.json"];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        if (successBlock) {
            successBlock();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        if (failureBlock) {
            failureBlock(operation);
        }
    }];
}

// Check and redirect to App store API is obsolete
+ (void)checkAPIVersion:(NSString*)apiVersion IsObsolete:(void(^)())obsoleteBlock
{
    NSString *path = [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"obsolete_api.json"];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    NSDictionary *parameters = @{@"api_version": apiVersion};
    [[AFStreetShoutAPIClient sharedClient] getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        if ([[result valueForKeyPath:@"obsolete"] isEqualToString: @"true"]) {
            obsoleteBlock();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"checkAPIVersion: We should not pass in this block!!!!");
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    }];
}

// Sign in
+ (void)signinWithEmail:(NSString *)email password:(NSString *)password success:(void(^)(User *user, NSString *authToken))successBlock failure:(void(^)(AFHTTPRequestOperation *operation))failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"users/sign_in.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [parameters setObject:email forKey:@"email"];
    [parameters setObject:password forKey:@"password"];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
    
        NSString *authToken = [result objectForKey:@"auth_token"];
        
        if (successBlock) {
            successBlock(user, authToken);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        if (failureBlock) {
            failureBlock(operation);
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
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *errors = [JSON valueForKeyPath:@"errors"];
        
        NSLog(@"SERVER ERRORS: %@", errors);
        
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
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSLog(@"WRONG STATUS");
        failureBlock(nil);
    }];
}

// Sign in or up with Facebook
+ (void)signInOrUpWithFacebookWithParameters: (id) params success:(void(^)(User *user, NSString *authToken, BOOL isSignup))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[AFStreetShoutAPIClient getBasePath] stringByAppendingString:@"users/facebook_create_or_update.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [parameters setObject:[params objectForKey:@"email"] forKey:@"email"];
    [parameters setObject:[params objectForKey:@"id"] forKey:@"facebook_id"];
    [parameters setObject:[params objectForKey:@"name"] forKey:@"facebook_name"];
    [parameters setObject:[params objectForKey:@"username"] forKey:@"username"];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        BOOL isSignup = (BOOL) [result valueForKey:@"is_signup"] ;
        
        NSDictionary *rawUser = [result valueForKeyPath:@"user"];
        User *user = [User rawUserToInstance:rawUser];
        NSString *authToken = [result objectForKey:@"auth_token"];
            
        if (successBlock) {
                successBlock(user, authToken, isSignup);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        NSLog(@"Failure in signInOrUpWithFacebook");
        failureBlock();
    }];
}


@end
