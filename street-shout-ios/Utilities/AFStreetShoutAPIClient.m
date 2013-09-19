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

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates AndExecute:(void(^)(NSArray *shouts))block
{
    NSDictionary *parameters = @{@"neLat": cornersCoordinates[0],
                                 @"neLng": cornersCoordinates[1],
                                 @"swLat": cornersCoordinates[2],
                                 @"swLng": cornersCoordinates[3]};
    
    [[AFStreetShoutAPIClient sharedClient] getPath:@"bound_box_shouts.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        NSArray *rawShouts = [JSON valueForKeyPath:@"result"];
        
        block([Shout rawShoutsToInstances:rawShouts]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR!!!");
        //TODO: implement
    }];
}

+ (void)getShoutInfo:(NSUInteger)shoutId AndExecute:(void(^)(Shout *shout))successBlock
{
    [[AFStreetShoutAPIClient sharedClient] getPath:[NSString stringWithFormat:@"shouts/%d", shoutId] parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        Shout *rawShout = [JSON valueForKeyPath:@"result"];
        
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
    
    [[AFStreetShoutAPIClient sharedClient] postPath:@"shouts.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSString *rawShout = [JSON valueForKeyPath:@"result"];
        successBlock([Shout rawShoutToInstance:rawShout]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
    
    [[AFStreetShoutAPIClient sharedClient] postPath:@"update_device_info" parameters:parameters success:nil failure:nil];
}

@end
