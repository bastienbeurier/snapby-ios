//
//  MapRequestHandler.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "MapRequestHandler.h"
#import "AFStreetShoutAPIClient.h"

@implementation MapRequestHandler

+ (void)pullShoutsInZone:(NSArray *)cornersCoordinates AndExecuteSuccess:(void(^)(NSArray *shouts))successBlock failure:(void(^)())failureBlock
{
    [AFStreetShoutAPIClient pullShoutsInZone:cornersCoordinates AndExecuteSuccess:successBlock failure:failureBlock];
}

@end
