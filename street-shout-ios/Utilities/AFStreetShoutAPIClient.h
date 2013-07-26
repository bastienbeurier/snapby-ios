//
//  AFStreetShoutAPIClient.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFHTTPClient.h"
#import "Shout.h"

@interface AFStreetShoutAPIClient : AFHTTPClient

+ (AFStreetShoutAPIClient *)sharedClient;

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates
              AndExecute:(void(^)(NSArray *shouts))block;

+ (void)createShoutWithLat:(double)lat
                       Lng:(double)lng
                  Username:(NSString *)userName
               Description:(NSString *)description
                     Image:(NSString *) imageUrl
         AndExecuteSuccess:(void(^)(Shout *))successBlock
                   Failure:(void(^)())failureBlock;

@end
