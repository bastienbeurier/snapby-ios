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
#import "UIDevice-Hardware.h"
#import "NavigationAppDelegate.h"

@implementation AFStreetShoutAPIClient

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

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates
       AndExecuteSuccess:(void(^)(NSArray *shouts))successBlock failure:(void (^)())failureBlock
{
    NSDictionary *parameters = @{@"neLat": cornersCoordinates[0],
                                 @"neLng": cornersCoordinates[1],
                                 @"swLat": cornersCoordinates[2],
                                 @"swLng": cornersCoordinates[3]};
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] getPath:@"bound_box_shouts.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        NSArray *rawShouts = [JSON valueForKeyPath:@"result"];
        
        successBlock([Shout rawShoutsToInstances:rawShouts]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        failureBlock();
    }];
}

+ (void)getShoutInfo:(NSUInteger)shoutId AndExecute:(void(^)(Shout *shout))successBlock
{
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] getPath:[NSString stringWithFormat:@"shouts/%d", shoutId] parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        Shout *rawShout = [JSON valueForKeyPath:@"result"];
        
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        NSLog(@"ERROR!!!");
    }];
}

+ (void)createShoutWithLat:(double)lat Lng:(double)lng Username:(NSString *)userName Description:(NSString *)description Image:(NSString *)imageUrl DeviceId:(NSString *)deviceId AndExecuteSuccess:(void(^)(Shout *shout))successBlock Failure:(void(^)())failureBlock
{    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    [parameters setObject:userName forKey:@"user_name"];
    [parameters setObject:description forKey:@"description"];
    [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
    [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    [parameters setObject:deviceId forKey:@"device_id"];
    
    if (imageUrl) {
        [parameters setObject:imageUrl forKey:@"image"];
    }
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:@"shouts.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        NSString *rawShout = [JSON valueForKeyPath:@"result"];
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        failureBlock();
    }];
}

+ (void)sendDeviceInfoWithLat:(double)lat Lng:(double)lng
{    
    NSString *deviceId = [GeneralUtilities getDeviceID];
    NSString *uaDeviceToken = [GeneralUtilities getUADeviceToken];
    NSNumber *notificationRadius = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIFICATION_RADIUS_PREF];
    
    if (!notificationRadius) {
        notificationRadius = [NSNumber numberWithInt:kDefaultNotificationRadiusIndex];
    }
    
    NSString *deviceModel = [[UIDevice currentDevice] platformString];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *osType = @"ios";
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *apiVersion = kApiVersion;
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    [parameters setObject:deviceId forKey:@"device_id"];
    [parameters setObject:notificationRadius forKey:@"notification_radius"];
    [parameters setObject:deviceModel forKey:@"device_model"];
    [parameters setObject:osVersion forKey:@"os_version"];
    [parameters setObject:osType forKey:@"os_type"];
    [parameters setObject:appVersion forKey:@"app_version"];
    [parameters setObject:apiVersion forKey:@"api_version"];
    [parameters setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
    [parameters setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
    
    if (uaDeviceToken) {
        [parameters setObject:uaDeviceToken forKey:@"push_token"];
    }
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:@"update_device_info" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    }];
}

+ (void)reportShout:(NSUInteger)shoutId withMotive:(NSUInteger)motiveIndex AndExecute:(void(^)())successBlock Failure:(void(^)())failureBlock
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    [parameters setObject:[NSNumber numberWithInt:shoutId] forKey:@"id"];
    [parameters setObject:[NSNumber numberWithInt:motiveIndex] forKey:@"motive"];
    [parameters setObject:[GeneralUtilities getDeviceID] forKey:@"device_id"];
    
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] postPath:@"flag_shout" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        if (successBlock) {
            successBlock();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        if (failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)getBlackListedDevicesAndExecute:(void(^)(NSArray *blackListedDeviceIds))block
{
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [[AFStreetShoutAPIClient sharedClient] getPath:@"black_listed_devices.json" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        NSArray *rawBlackListedDevices = [JSON valueForKeyPath:@"result"];
        NSMutableArray *blackListedDeviceIds = [[NSMutableArray alloc] init];
        
        for (NSDictionary *rawBlackListedDevice in rawBlackListedDevices) {
            [blackListedDeviceIds addObject:[rawBlackListedDevice objectForKey:@"device_id"]];
        }
        
        if (block) {
            block(blackListedDeviceIds);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    }];
}

+ (void)checkAPIVersion:(NSString*)apiVersion IsObsolete:(void(^)())block
{
    [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    NSDictionary *parameters = @{@"api_version": apiVersion};
    [[AFStreetShoutAPIClient sharedClient] getPath:@"obsolete_api.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        if ([[JSON valueForKeyPath:@"result"]  isEqualToString: @"IsObsolete"]) {
            block();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"checkAPIVersion: We should not pass in this block!!!!");
        [(NavigationAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    }];
}

@end
