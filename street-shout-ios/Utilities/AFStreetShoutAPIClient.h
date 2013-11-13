//
//  AFStreetShoutAPIClient.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFHTTPClient.h"
#import "Shout.h"

#define API_VERSION @"1.0"

@interface AFStreetShoutAPIClient : AFHTTPClient

+ (AFStreetShoutAPIClient *)sharedClient;

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates
              AndExecuteSuccess:(void(^)(NSArray *shouts))sucessBlock failure:(void (^)())failureBlock;

+ (void)createShoutWithLat:(double)lat
                       Lng:(double)lng
                  Username:(NSString *)userName
               Description:(NSString *)description
                     Image:(NSString *) imageUrl
                  DeviceId:(NSString *)deviceId
         AndExecuteSuccess:(void(^)(Shout *))successBlock
                   Failure:(void(^)())failureBlock;

+ (void)sendDeviceInfoWithLat:(double)lat Lng:(double)lng;

+ (void)getShoutInfo:(NSUInteger)shoutId AndExecute:(void(^)(Shout *shout))successBlock;

+ (void)reportShout:(NSUInteger)shoutId withMotive:(NSUInteger)motiveIndex AndExecute:(void(^)())successBlock Failure:(void(^)())failureBlock;

@end

static NSString *const MyFirstConstant = API_VERSION;

