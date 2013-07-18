//
//  Shout.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "Shout.h"
#import "AFStreetShoutAPIClient.h"

@implementation Shout

+ (Shout *)rawShoutToInstance:(NSDictionary *)rawShout
{
    Shout *shout = [[Shout alloc] init];
    shout.identifier = [[rawShout objectForKey:@"id"] integerValue];
    shout.lat = [[rawShout objectForKey:@"lat"] doubleValue];
    shout.lng = [[rawShout objectForKey:@"lng"] doubleValue];
    shout.description = [rawShout objectForKey:@"description"];
    shout.created = [rawShout objectForKey:@"created_at"];
    shout.source = [rawShout objectForKey:@"source"];
    shout.displayName = [rawShout objectForKey:@"display_name"];
    shout.image = [rawShout objectForKey:@"image"];
    
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
