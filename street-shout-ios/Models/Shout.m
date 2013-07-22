//
//  Shout.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "Shout.h"
#import "AFStreetShoutAPIClient.h"

#define SHOUT_ID @"id"
#define SHOUT_LAT @"lat"
#define SHOUT_LNG @"lng"
#define SHOUT_DESCRIPTION @"description"
#define SHOUT_CREATED_AT @"created_at"
#define SHOUT_SOURCE @"source"
#define SHOUT_DISPLAY_NAME @"display_name"
#define SHOUT_IMAGE @"image"

@implementation Shout

+ (Shout *)rawShoutToInstance:(NSDictionary *)rawShout
{
    Shout *shout = [[Shout alloc] init];
    shout.identifier = [[rawShout objectForKey:SHOUT_ID] integerValue];
    shout.lat = [[rawShout objectForKey:SHOUT_LAT] doubleValue];
    shout.lng = [[rawShout objectForKey:SHOUT_LNG] doubleValue];
    shout.description = [rawShout objectForKey:SHOUT_DESCRIPTION];
    shout.created = [rawShout objectForKey:SHOUT_CREATED_AT];
    shout.source = [rawShout objectForKey:SHOUT_SOURCE];
    shout.displayName = [rawShout objectForKey:SHOUT_DISPLAY_NAME];
    shout.image = [rawShout objectForKey:SHOUT_IMAGE];
    
    if (shout.image && shout.image != (id)[NSNull null] && shout.image.length != 0 && ![shout.image isEqualToString:@"null"]) {
        shout.image = [@"http://" stringByAppendingString:shout.image];
    } else {
        shout.image = nil;
    }
    
    return shout;
}

+ (NSArray *)rawShoutsToInstances:(NSArray *)rawShouts
{
    NSMutableArray *shouts = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawShout in rawShouts) {
        [shouts addObject:[Shout rawShoutToInstance:rawShout]];
    }
    
    return shouts;
}

+ (void)createShoutWithLat:(double)lat Lng:(double)lng Username:(NSString *)userName Description:(NSString *)description Image:(NSString *) imageUrl
{
    [AFStreetShoutAPIClient createShoutWithLat:(double)lat Lng:(double)lng Username:(NSString *)userName Description:(NSString *)description Image:(NSString *) imageUrl];
}

@end
